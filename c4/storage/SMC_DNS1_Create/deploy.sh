#!/bin/bash
#
# SMC central DNS configuration script (before org DNS) - v1.7
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure SMC DNS"

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
NETWORK=$(getParameter network)
SHORTNAME=$(getParameter shortname)
DOMAIN=$(getParameter domain)
WAN_IP=$(getParameter wan_ip)

# Variables
BIND_CONFIG_FOLDER=/etc/bind/
BIND_NAMED_CONF_LOCAL=$BIND_CONFIG_FOLDER/named.conf.local
BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES=$BIND_CONFIG_FOLDER/named.conf.internal.notifyslaves
BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS=$BIND_CONFIG_FOLDER/named.conf.acl.internalnetworks
BIND_NAMED_CONF_INTERNAL_CUSTOMER_ZONES=$BIND_CONFIG_FOLDER/named.conf.internal.customerzones
BIND_NAMED_CONF_EXTERNAL_CUSTOMER_ZONES=$BIND_CONFIG_FOLDER/named.conf.external.customerzones
BIND_GENERAL_ZONE_DEFINITION=$BIND_CONFIG_FOLDER/zones.rfc1918.101.10.in-addr.arpa
ORG_DNS_IP="${NETWORK}.2"
NETWORK_REVERSE=$(echo "$NETWORK" | sed 's/\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3.\2.\1/')

# Archive files
BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS_ADD_AWK=$ARCHIVE_FOLDER/named.conf.acl.internalnetworks.add.awk
BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES_ADD_AWK=$ARCHIVE_FOLDER/named.conf.internal.notifyslaves.add.awk

# Template files
BIND_TEMPLATE_ORG_INTERNAL_CONFIG_FILE=${TEMPLATE_FOLDER}/transient/domain-internal.conf
BIND_TEMPLATE_ORG_EXTERNAL_CONFIG_FILE=${TEMPLATE_FOLDER}/transient/domain-external.conf
BIND_ORG_INTERNAL_CONFIG_FILE=$BIND_CONFIG_FOLDER/orgs/internal/$DOMAIN.conf
BIND_ORG_EXTERNAL_CONFIG_FILE=$BIND_CONFIG_FOLDER/orgs/external/$DOMAIN.conf

# Creating backup
tar -C /etc -czf $RESULT_FOLDER/bind9.tar.gz bind

#Comment out general reverse zone definition
sed -i "s|^\(zone \"$NETWORK_REVERSE.in-addr.arpa\".*\)|\/\/\1|g" $BIND_GENERAL_ZONE_DEFINITION

# Allow the Org's DNS to access the internal view
awk -f $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS_ADD_AWK -v ORG_DNS_IP="${ORG_DNS_IP}/32;" \
       $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS > \
       $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS.tmp

# did awk fail for some reason?
if [ $? -ne 0 ]
  then
    echo "awk1 failed "
    exit 1
fi

if [ ! -s $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS.tmp ]
  then 
    echo "awk1 created a zero length file"
    exit 1
fi

mv $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS.tmp \
   $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS

# Allow the Org's DNS to fetch the internal system_anchor_domain zone and also notify it when there's a change
awk -f $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES_ADD_AWK -v ORG_DNS_IP="$ORG_DNS_IP;" \
       $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES >  \
       $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES.tmp
# did awk fail for some reason? 
if [ $? -ne 0 ]
  then
    echo "awk2 failed " 
    exit 1
fi

# Is the result a zero length file? 
if [ ! -s $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES.tmp ]
  then
    echo "awk2 created a zero length file"
    exit 1
fi

mv $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES.tmp \
   $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES

# Generate a TSIG for the internal view
INTERNAL_SECRET_FILE=$(dnssec-keygen -a HMAC-MD5 -b 128 -n HOST $DOMAIN.)
mv $INTERNAL_SECRET_FILE.* $RESULT_FOLDER/
INTERNAL_SECRET=$(cat $RESULT_FOLDER/$INTERNAL_SECRET_FILE.key | awk '{print $7}')

# Generate a TSIG for the external view
EXTERNAL_SECRET_FILE=$(dnssec-keygen -a HMAC-MD5 -b 128 -n HOST $DOMAIN.)
mv $EXTERNAL_SECRET_FILE.* $RESULT_FOLDER/
EXTERNAL_SECRET=$(cat $RESULT_FOLDER/$EXTERNAL_SECRET_FILE.key | awk '{print $7}')

# Define internal cloud zones as slaves
cp $BIND_TEMPLATE_ORG_INTERNAL_CONFIG_FILE $BIND_ORG_INTERNAL_CONFIG_FILE
sed -i -e "s|\[-INTERNAL_SECRET-\]|$INTERNAL_SECRET|g" $BIND_ORG_INTERNAL_CONFIG_FILE
eseriReplaceValues $BIND_ORG_INTERNAL_CONFIG_FILE
chown root:root $BIND_ORG_INTERNAL_CONFIG_FILE
chmod 644 $BIND_ORG_INTERNAL_CONFIG_FILE

# Define external cloud zones as slaves
cp $BIND_TEMPLATE_ORG_EXTERNAL_CONFIG_FILE $BIND_ORG_EXTERNAL_CONFIG_FILE
sed -i -e "s|\[-EXTERNAL_SECRET-\]|$EXTERNAL_SECRET|g" $BIND_ORG_EXTERNAL_CONFIG_FILE
eseriReplaceValues $BIND_ORG_EXTERNAL_CONFIG_FILE
chown root:root $BIND_ORG_EXTERNAL_CONFIG_FILE
chmod 644 $BIND_ORG_EXTERNAL_CONFIG_FILE

# Include the internal cloud zones definition in Bind's config (named.conf.internal.customerzones)
echo "include \"/etc/bind/orgs/internal/$DOMAIN.conf\";" >> $BIND_NAMED_CONF_INTERNAL_CUSTOMER_ZONES
# Include the external cloud zones definition in Bind's config (named.conf.external.customerzones)
echo "include \"/etc/bind/orgs/external/$DOMAIN.conf\";" >> $BIND_NAMED_CONF_EXTERNAL_CUSTOMER_ZONES

# Reload Bind
/etc/init.d/bind9 reload

# Save Internal and External TSIG keys for later use
echo "INTERNAL_SECRET=$INTERNAL_SECRET" >> $RESULT_FOLDER/Cloud_Secret.txt
echo "EXTERNAL_SECRET=$EXTERNAL_SECRET" >> $RESULT_FOLDER/Cloud_Secret.txt

# Save IPs, Hostnames, NS and MX for later use
host $(dig @8.8.8.8 +short SOA $SYSTEM_ANCHOR_DOMAIN | awk '{print $1}') 8.8.8.8 | awk '/^.*has address [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print "SMC_DNS_IP_PUBLIC="$4}' >> $RESULT_FOLDER/SMC_HOST_IP.txt
host $(hostname -f) | awk '/^.*has address [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print "SMC_DNS_IP_PRIVATE="$4}' >> $RESULT_FOLDER/SMC_HOST_IP.txt
host hera.$SYSTEM_ANCHOR_DOMAIN | awk '/^.*has address [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print "SMC_MAIL_IP_PRIVATE="$4}' >> $RESULT_FOLDER/SMC_HOST_IP.txt
host c3.$SYSTEM_ANCHOR_DOMAIN | awk '/^.*has address [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print "SMC_C3_IP_PRIVATE="$4}' >> $RESULT_FOLDER/SMC_HOST_IP.txt


exit 0
