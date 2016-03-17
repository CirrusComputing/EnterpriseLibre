#!/bin/bash
#
# Firewall deploy script - v2.2
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy Cloud Firewall Server"

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SHORT_DOMAIN=$(getParameter short_domain)
TIMEZONE=$(getParameter timezone)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

WAN_IP=$(ifconfig venet0:0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
KRB5_CONFIG=/etc/krb5.conf
LDAP_CONFIG=/etc/ldap/ldap.conf
FIREWALL_CONFIG_FOLDER=/etc/shorewall
APACHE_USER=www-data
APACHE_CONFIG_FOLDER=/etc/apache2
APACHE_SITES_AVAILABLE=sites-available
NAGIOS_PLUGINS_FOLDER=/usr/local/lib/nagios/plugins
NAGIOS_SHOREWALL_PLUGIN=check_shorewall
SYSTEM_SSL_FOLDER=/etc/ssl
SYSTEM_SSL_CERTS_FOLDER=$SYSTEM_SSL_FOLDER/certs
SYSTEM_SSL_PRIVATE_FOLDER=$SYSTEM_SSL_FOLDER/private
APACHE_SSL_CERT=$SYSTEM_SSL_CERTS_FOLDER/ssl.$DOMAIN.pem
APACHE_SSL_PRIVATE_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/ssl.$DOMAIN.pem
APACHE_DEFAULT_PAGE=/var/www/index.html

SHOREWALL_CONFIG_FILES='hosts interfaces masq policy routestopped rules zones'
APACHE_SITES='default-ssl desktop nuxeo orangehrm phpscheduleit redmine sqlledger timesheet trac vtiger sogo wiki mailinglists'

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

# Deploy Apache Certificate
install -o root -g root -m 644 $ARCHIVE_FOLDER/ssl.${DOMAIN}_cert.pem $APACHE_SSL_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/ssl.${DOMAIN}_key.pem $APACHE_SSL_PRIVATE_KEY

# Install Nagios shorewall plugin
install -o root -g root -m 755 $ARCHIVE_FOLDER/files/$NAGIOS_PLUGINS_FOLDER/$NAGIOS_SHOREWALL_PLUGIN $NAGIOS_PLUGINS_FOLDER/$NAGIOS_SHOREWALL_PLUGIN
# Edit local nagios config
echo "command[$NAGIOS_SHOREWALL_PLUGIN]=sudo $NAGIOS_PLUGINS_FOLDER/$NAGIOS_SHOREWALL_PLUGIN" >> /etc/nagios/nrpe_local.cfg
/etc/init.d/nagios-nrpe-server restart
# Edit sudoers.d for nagios
sed -i "/^nagios    ALL=NOPASSWD:.*/ {s||\0, $NAGIOS_PLUGINS_FOLDER/$NAGIOS_SHOREWALL_PLUGIN|g;} " /etc/sudoers.d/nagios

# Disable ICMP redirects, saves a bunch of "redirect ignored" messages on the HWH
echo "net.ipv4.conf.eth0.send_redirects = 0" >> /etc/sysctl.conf
sysctl -p

# Since hermes WAN IP cannot be resolved using the cloud's DNS, add to /etc/hosts to avoid below warning.
# (EAI 2)Name or service not known: Failed to resolve server name for x.x.x.x (check DNS) -- or specify an explicit ServerName
echo "$WAN_IP localhost.localdomain localhost" >> /etc/hosts
# Install and configure Apache2
aptGetInstall apache2
# Manually install Apache2 updates
dpkg -i $ARCHIVE_FOLDER/packages/apache2/*.deb
# Install ssl.conf which disables SSLv3 and certain Cipher Suites
install -o root -g root -m 644 $ARCHIVE_FOLDER/files/$APACHE_CONFIG_FOLDER/mods-available/ssl.conf $APACHE_CONFIG_FOLDER/mods-available/
install -o root -g root -m 644 $ARCHIVE_FOLDER/files/$APACHE_DEFAULT_PAGE $APACHE_DEFAULT_PAGE
install -o root -g root -m 644 $TEMPLATE_FOLDER/$APACHE_CONFIG_FOLDER/ports.conf $APACHE_CONFIG_FOLDER/
eseriReplaceValues $APACHE_CONFIG_FOLDER/ports.conf
install -o root -g root -m 644 $TEMPLATE_FOLDER/$APACHE_CONFIG_FOLDER/httpd.conf $APACHE_CONFIG_FOLDER/
for SITE in $APACHE_SITES ; do
    install -o root -g root -m 644 $TEMPLATE_FOLDER/$APACHE_CONFIG_FOLDER/sites-available/$SITE $APACHE_CONFIG_FOLDER/sites-available/$SITE
    eseriReplaceValues $APACHE_CONFIG_FOLDER/sites-available/$SITE
done
a2enmod proxy proxy_http proxy_connect ssl
adduser $APACHE_USER ssl-cert
/etc/init.d/apache2 restart

# Do Last
# Install and configure Shorewall
aptGetInstall shorewall
for FILE in $SHOREWALL_CONFIG_FILES ; do
    install -o root -g root -m 644 $TEMPLATE_FOLDER/$FIREWALL_CONFIG_FOLDER/$FILE $FIREWALL_CONFIG_FOLDER/$FILE
    parseCapabilities $FIREWALL_CONFIG_FOLDER/$FILE
    eseriReplaceValues $FIREWALL_CONFIG_FOLDER/$FILE
done
sed -i 's|startup=0|startup=1|g' /etc/default/shorewall
sed -i 's|IP_FORWARDING=Keep|IP_FORWARDING=On|g' /etc/shorewall/shorewall.conf
/etc/init.d/shorewall restart

exit 0
