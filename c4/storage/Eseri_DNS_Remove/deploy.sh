#!/bin/bash
#
# Eseri Master/Slave DNS configuration script (Delete Cloud) - v1.9
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure Eseri DNS"

# Check for proper number of parameters
if [ $# -ne "2" ]; then
    echo "Usage: $SCRIPT_NAME DOMAIN NETWORK"
    echo "Example: $SCRIPT_NAME a1.newvirtualorgs.net 10.101.1"
    exit 1
fi

# Check the format of the input parameters
eseriCheckParameter "Full domain name" $1
eseriCheckParameter "Network" $2

DOMAIN=$1
NETWORK=$2

# Cannot get this from eseriCommon, but we know this runs on the prime dns server
SYSTEM_ANCHOR_DOMAIN=($hostname -d)

# Variables
SHORT_NAME=$(hostname -s)
BIND_CONFIG_FOLDER=/etc/bind
BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS=$BIND_CONFIG_FOLDER/named.conf.acl.internalnetworks
BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES=$BIND_CONFIG_FOLDER/named.conf.internal.notifyslaves
BIND_NAMED_CONF_INTERNAL_CUSTOMER_ZONES=$BIND_CONFIG_FOLDER/named.conf.internal.customerzones
BIND_NAMED_CONF_EXTERNAL_CUSTOMER_ZONES=$BIND_CONFIG_FOLDER/named.conf.external.customerzones
BIND_ORG_INTERNAL_CONFIG_FILE=$BIND_CONFIG_FOLDER/orgs/internal/$DOMAIN.conf
BIND_ORG_EXTERNAL_CONFIG_FILE=$BIND_CONFIG_FOLDER/orgs/external/$DOMAIN.conf
BIND_GENERAL_ZONE_DEFINITION=$BIND_CONFIG_FOLDER/zones.rfc1918.101.10.in-addr.arpa
ORG_DNS_IP="${NETWORK}.2"
NETWORK_REVERSE=$(echo "$NETWORK" | sed 's/\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3.\2.\1/')

# Archive files
BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS_DEL_AWK=$ARCHIVE_FOLDER/named.conf.acl.internalnetworks.del.awk
BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES_DEL_AWK=$ARCHIVE_FOLDER/named.conf.internal.notifyslaves.del.awk

# Creating backup
tar -C /etc -czf $RESULT_FOLDER/bind9.tar.gz bind

#Uncomment general reverse zone definition
sed -i "s|^\/\/\(zone \"$NETWORK_REVERSE.in-addr.arpa\".*\)|\1|g" $BIND_GENERAL_ZONE_DEFINITION

# Allow the Org's DNS to access the internal view
awk -f $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS_DEL_AWK -v ORG_DNS_IP="${ORG_DNS_IP}/32;" $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS >$BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS.tmp
mv $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS.tmp $BIND_NAMED_CONF_ACL_INTERNAL_NETWORKS

# Allow the Org's DNS to fetch the internal serv.eseri.net zone and also notify it when there's a change
awk -f $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES_DEL_AWK -v ORG_DNS_IP="$ORG_DNS_IP;" $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES >$BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES.tmp
mv $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES.tmp $BIND_NAMED_CONF_INTERNAL_NOTIFYSLAVES

if [ -f "$BIND_ORG_INTERNAL_CONFIG_FILE" ]; then
    # Remove the internal cloud zones definition from Bind's config (named.conf.internal.customerzones)
    sed -i "/include \"\/etc\/bind\/orgs\/internal\/$DOMAIN.conf\";/d" $BIND_NAMED_CONF_INTERNAL_CUSTOMER_ZONES
    
    # Remove the internal cloud zones config
    rm $BIND_ORG_INTERNAL_CONFIG_FILE
fi

if [ -f "$BIND_ORG_EXTERNAL_CONFIG_FILE" ]; then
    # Remove the external cloud zones definition from Bind's config (named.conf.external.customerzones)
    sed -i "/include \"\/etc\/bind\/orgs\/external\/$DOMAIN.conf\";/d" $BIND_NAMED_CONF_EXTERNAL_CUSTOMER_ZONES

    # Remove the external cloud zones config
    rm $BIND_ORG_EXTERNAL_CONFIG_FILE

    # Remove the cache files
    rm /var/cache/bind/db.$NETWORK
    rm /var/cache/bind/db.$DOMAIN.internal
    rm /var/cache/bind/db.$DOMAIN.external
fi

# Reload Bind
/etc/init.d/bind9 reload

exit 0
