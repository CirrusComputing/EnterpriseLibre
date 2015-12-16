#!/bin/bash
#
# DNS deploy script - v3.2
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
echo "$(date) - Deploy Domain Name Server"

# Get the system parameters
TMP_DOMAIN=$(awk '/search/ { print $2 }' < /etc/resolv.conf)
echo "TMP_DOMAIN is $TMP_DOMAIN"
eseriGetDNSInternal $TMP_DOMAIN zeus.$TMP_DOMAIN
eseriGetNetwork

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SYSTEM_ANCHOR_IP=$(getParameter system_anchor_ip)
SHORT_DOMAIN=$(getParameter short_domain)
TIMEZONE=$(getParameter timezone)
WAN_IP=$(getParameter wan_ip)

DEPLOY_TIME=$(date +%Y%m%d01)
echo "$DEPLOY_TIME"

# Variables
DNS_CONFIG_FOLDER=/etc/bind
DNS_DB_TEMPLATE_INTERNAL=$DNS_CONFIG_FOLDER/db.domain.internal
DNS_DB_TEMPLATE_INTERNALREVERSE=$DNS_CONFIG_FOLDER/db.domain.internalreverse
DNS_DB_TEMPLATE_EXTERNAL=$DNS_CONFIG_FOLDER/db.domain.external
DNS_DB_INTERNAL=$DNS_CONFIG_FOLDER/db.$DOMAIN.internal
DNS_DB_INTERNALREVERSE=$DNS_CONFIG_FOLDER/db.$DOMAIN.internalreverse
DNS_DB_EXTERNAL=$DNS_CONFIG_FOLDER/db.$DOMAIN.external
DNS_DB_INTERNALCAPABILITIES=$DNS_CONFIG_FOLDER/db.internalcapabilities
DNS_DB_EXTERNALCAPABILITIES=$DNS_CONFIG_FOLDER/db.externalcapabilities

DNS_NAMED_CONF=$DNS_CONFIG_FOLDER/named.conf
DNS_NAMED_CONF_LOCAL=$DNS_CONFIG_FOLDER/named.conf.local
DNS_NAMED_CONF_INTERNAL=$DNS_CONFIG_FOLDER/named.conf.internal
DNS_NAMED_CONF_EXTERNAL=$DNS_CONFIG_FOLDER/named.conf.external
DNS_NAMED_CONF_OPTIONS=$DNS_CONFIG_FOLDER/named.conf.options
DNS_DB_RFC1918=$DNS_CONFIG_FOLDER/zones.rfc1918
DNS_DB_RFC1918_101_10=$DNS_CONFIG_FOLDER/zones.rfc1918.101.10.in-addr.arpa

DNS_ZONES_FOLDER=$DNS_CONFIG_FOLDER/zones
DNS_INTERNAL_ZONES_FOLDER=$DNS_ZONES_FOLDER/internal
DNS_EXTERNAL_ZONES_FOLDER=$DNS_ZONES_FOLDER/external
DNS_CONF_TEMPLATE_SYSTEM_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/system-anchor-domain-internal.conf
DNS_CONF_SYSTEM_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/$SYSTEM_ANCHOR_DOMAIN.conf
DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/domain-internal.conf
DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ZONES_FOLDER/domain-external.conf
DNS_CONF_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/$DOMAIN.conf
DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ZONES_FOLDER/$DOMAIN.conf
DNS_CONF_MASTERS_INTERNAL=$DNS_ZONES_FOLDER/masters-internal.conf
DNS_CONF_NOTIFYSLAVES_INTERNAL=$DNS_ZONES_FOLDER/notifyslaves-internal.conf
DNS_CONF_NOTIFYSLAVES_EXTERNAL=$DNS_ZONES_FOLDER/notifyslaves-external.conf

ETC_DEFAULT_FOLDER=/etc/default
DNS_DEFAULTS=$ETC_DEFAULT_FOLDER/bind9
KRB5_CONFIG=/etc/krb5.conf
LDAP_CONFIG=/etc/ldap/ldap.conf

# Get the Private IP address and Public IP address of the SMC DNS.
SMC_DNS_IP_PRIVATE=$(grep 'SMC_DNS_IP_PRIVATE=' $ARCHIVE_FOLDER/SMC_HOST_IP.txt | sed 's|SMC_DNS_IP_PRIVATE=||')
echo "SMC_DNS_IP_PRIVATE is $SMC_DNS_IP_PRIVATE"
SMC_DNS_IP_PUBLIC=$(grep 'SMC_DNS_IP_PUBLIC='  $ARCHIVE_FOLDER/SMC_HOST_IP.txt | sed 's|SMC_DNS_IP_PUBLIC=||')
echo "SMC_DNS_IP_PUBLIC is $SMC_DNS_IP_PUBLIC"

# Install bind9
dpkg -i $ARCHIVE_FOLDER/bind/*

# Get the TSIG keys for the internal and external view
INTERNAL_SECRET=$(grep 'INTERNAL_SECRET=' $ARCHIVE_FOLDER/Cloud_Secret.txt | sed 's|INTERNAL_SECRET=||')
echo "INTERNAL_SECRET is $INTERNAL_SECRET"
EXTERNAL_SECRET=$(grep 'EXTERNAL_SECRET=' $ARCHIVE_FOLDER/Cloud_Secret.txt | sed 's|EXTERNAL_SECRET=||')
echo "EXTERNAL_SECRET is $EXTERNAL_SECRET"

# Generate OpenSSL key
DOMAIN_KEY=$(openssl rsa -in $ARCHIVE_FOLDER/dkim.${DOMAIN}_key.pem -pubout -outform pem 2>/dev/null | grep -v "^-" | tr -d '\n')

# Deploy the config files and set the parameters
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_TEMPLATE_INTERNAL $DNS_DB_INTERNAL
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_TEMPLATE_INTERNALREVERSE $DNS_DB_INTERNALREVERSE
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_TEMPLATE_EXTERNAL $DNS_DB_EXTERNAL
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_INTERNALCAPABILITIES $DNS_DB_INTERNALCAPABILITIES
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_EXTERNALCAPABILITIES $DNS_DB_EXTERNALCAPABILITIES
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_NAMED_CONF $DNS_NAMED_CONF
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_NAMED_CONF_LOCAL $DNS_NAMED_CONF_LOCAL
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_NAMED_CONF_OPTIONS $DNS_NAMED_CONF_OPTIONS
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_RFC1918 $DNS_DB_RFC1918
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DB_RFC1918_101_10 $DNS_DB_RFC1918_101_10
install -o root -g root -m 755 -d $DNS_ZONES_FOLDER
install -o root -g root -m 755 -d $DNS_INTERNAL_ZONES_FOLDER
install -o root -g root -m 755 -d $DNS_EXTERNAL_ZONES_FOLDER
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_SYSTEM_INTERNAL_ZONE_FILE $DNS_CONF_SYSTEM_INTERNAL_ZONE_FILE
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_MASTERS_INTERNAL $DNS_CONF_MASTERS_INTERNAL
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_NOTIFYSLAVES_INTERNAL $DNS_CONF_NOTIFYSLAVES_INTERNAL
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_NOTIFYSLAVES_EXTERNAL $DNS_CONF_NOTIFYSLAVES_EXTERNAL
parseCapabilities $DNS_DB_INTERNAL
parseCapabilities $DNS_DB_INTERNALREVERSE
parseCapabilities $DNS_DB_EXTERNAL
parseCapabilities $DNS_DB_INTERNALCAPABILITIES
parseCapabilities $DNS_DB_EXTERNALCAPABILITIES
eseriReplaceValues $DNS_DB_INTERNAL
eseriReplaceValues $DNS_DB_INTERNALREVERSE
sed -i -e "s|\[-DOMAIN_KEY-\]|$DOMAIN_KEY|g;" $DNS_DB_EXTERNAL
eseriReplaceValues $DNS_DB_EXTERNAL
sed -i -e "s|\[-INTERNAL_SECRET-\]|$INTERNAL_SECRET|g;s|\[-EXTERNAL_SECRET-\]|$EXTERNAL_SECRET|g" $DNS_NAMED_CONF_LOCAL
eseriReplaceValues $DNS_NAMED_CONF_LOCAL
eseriReplaceValues $DNS_CONF_SYSTEM_INTERNAL_ZONE_FILE
eseriReplaceValues $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
eseriReplaceValues $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
eseriReplaceValues $DNS_CONF_MASTERS_INTERNAL
eseriReplaceValues $DNS_CONF_NOTIFYSLAVES_INTERNAL
eseriReplaceValues $DNS_CONF_NOTIFYSLAVES_EXTERNAL

# Include the internal cloud zones definition in Bind's config (named.conf.internal)
echo "include \"$DNS_CONF_SYSTEM_INTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_INTERNAL
echo "include \"$DNS_CONF_CLOUD_INTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_INTERNAL
# Include the external cloud zones definition in Bind's config (named.conf.external)
echo "include \"$DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_EXTERNAL

# Comment out zones 0.101.10 and 1.101.10 (System Manager Cloud) from the rfc1918 file
sed -i -e 's/zone "0.101.10.in-addr.arpa"/\/\/&/' $DNS_DB_RFC1918_101_10
sed -i -e 's/zone "1.101.10.in-addr.arpa"/\/\/&/' $DNS_DB_RFC1918_101_10

# Comment out the zone from the rfc1918 file
sed -i -e 's/zone "'${NETWORK_REVERSE}'.in-addr.arpa"/\/\/&/' $DNS_DB_RFC1918_101_10

# set bind options so only ipv4
install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_DEFAULTS $DNS_DEFAULTS

# Restart the server
/etc/init.d/bind9 restart

# Wait till the DNS servers talk to each other
# The eseri core DNS server might be at the other end of a VPN, 200 miles away,
# so there might occasionally be a long pause here.
TIME=0
TIMEOUT=400
while true; do
	host lucid-mirror.wan.virtualorgs.net
	[ $? -eq 0 ] && break
	echo "Time: $TIME sec(s)"
	sleep 1
	TIME=$(expr $TIME + 1)
	[ $TIME -ge $TIMEOUT ] && exit 1
done

# Upgrade the system
eseriSystemUpgrade

# Reconfigure SSMTP 
echo "$FQDN_HOSTNAME" >/etc/mailname
sed -i -e "s|^root=.*|root=sysadmin@$SYSTEM_ANCHOR_DOMAIN|g" -e "s|^mailhub=.*|mailhub=smtp.$DOMAIN|g" -e "s|^hostname=.*|hostname=$FQDN_HOSTNAME|g" /etc/ssmtp/ssmtp.conf
echo "root:$SHORT_DOMAIN.$SHORT_NAME@$SYSTEM_ANCHOR_DOMAIN:smtp.$DOMAIN" >>/etc/ssmtp/revaliases

# Reconfigure Timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Deploy CA root certificate
mkdir /usr/share/ca-certificates/$DOMAIN
install -o root -g root -m 644 $ARCHIVE_FOLDER/CA.crt /usr/share/ca-certificates/$DOMAIN/CA.crt
echo "`hostname -d`/CA.crt" >> /etc/ca-certificates.conf
update-ca-certificates

# Install Kerberos Client
install -o root -g root -m 644 $TEMPLATE_FOLDER/$KRB5_CONFIG $KRB5_CONFIG
eseriReplaceValues $KRB5_CONFIG
aptGetInstall krb5-user

# Install the LDAP Client
aptGetInstall ldap-utils libsasl2-modules-gssapi-mit
install -o root -g root -m 644 $TEMPLATE_FOLDER/$LDAP_CONFIG $LDAP_CONFIG
eseriReplaceValues $LDAP_CONFIG

exit 0
