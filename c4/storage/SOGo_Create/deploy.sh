#!/bin/bash
#
# SOGo deploy - v1.4
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy SOGo"

MAIL_DOMAIN=$(getParameter email_domain)
IT_MAN_USER=$(getParameter manager_username)
LDAP_PASSWORD_SOGO=$(getPassword LDAP_PASSWORD_SOGO)
DB_PASSWORD_SOGO=$(getPassword DB_PASSWORD_SOGO)
SOGO_PASSWORD_FREEBUSY=$(getPassword SOGO_PASSWORD_FREEBUSY)
LDAP_DOVECOT_PW=$(getPassword LDAP_PASSWORD_DOVECOT)
DOVECOT_MASTER_USER_PASSWORD=$(getPassword DOVECOT_MASTER_USER_PASSWORD)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# Install memcached
aptGetInstall memcached

# Install Dovecot
aptGetInstall dovecot-imapd

# Deploy config files and modify values
install -o root -g root -m 644 -t /etc/dovecot/ $ARCHIVE_FOLDER/files/etc/dovecot/dovecot.conf
install -o root -g root -m 640 -t /etc/dovecot/ $TEMPLATE_FOLDER/etc/dovecot/dovecot-ldap.conf
sed -i -e "s/\[-LDAP_PASSWORD_DOVECOT-\]/$LDAP_DOVECOT_PW/g" -e "s/\[-DOVECOT_MASTER_USER_PASSWORD-\]/$DOVECOT_MASTER_USER_PASSWORD/" /etc/dovecot/dovecot-ldap.conf
eseriReplaceValues /etc/dovecot/dovecot-ldap.conf

# Restart Apache2
service dovecot restart

# Preseed tmpreaper
debconf-set-selections $ARCHIVE_FOLDER/tmpreaper.seed

# Install sogo and the postgresql driver for it (force-yes is used because the inverse apt respoitory is not yet authenticated)
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/inverse.list
eseriReplaceValues /etc/apt/sources.list.d/inverse.list
apt-get update
apt-get -y -q --force-yes install sogo sope4.9-gdl1-postgresql

# Set SOGo configuration
service sogo stop

install -o sogo -g sogo -m 600 -t /home/sogo/GNUstep/Defaults $TEMPLATE_FOLDER/home/sogo/GNUstep/Defaults/.GNUstepDefaults
sed -i -e "s|\[-DB_PASSWORD_SOGO-\]|${DB_PASSWORD_SOGO}|g;s|\[-MAIL_DOMAIN-\]|${MAIL_DOMAIN}|g;s|\[-TIMEZONE-\]|${TIMEZONE}|g;s|\[-LDAP_PASSWORD_SOGO-\]|${LDAP_PASSWORD_SOGO}|g" /home/sogo/GNUstep/Defaults/.GNUstepDefaults
eseriReplaceValues /home/sogo/GNUstep/Defaults/.GNUstepDefaults

service sogo start

# Enable tmpreaper
sed -i -e 's/^SHOWWARNING/#SHOWWARNING/' /etc/tmpreaper.conf

# Install Apache2
aptGetInstall apache2 libapache2-mod-chroot libapache2-mod-auth-kerb libapache2-mod-php5 php5-curl

# Enable required Apache modules
a2enmod rewrite
a2enmod auth_kerb
a2enmod mod_chroot
a2enmod proxy_http
a2enmod headers
a2enmod authnz_ldap

# Deploy keytab for Apache2
install -o www-data -g root -m 400 $ARCHIVE_FOLDER/gaia.apache2.keytab /etc/apache2/apache2.keytab

# Deploy php.ini
install -o root -g root -m 644 -t /etc/php5/apache2 $ARCHIVE_FOLDER/files/etc/php5/apache2/php.ini

# Deploy free busy workaround
install -o root -g root -m 755 -d /var/lib/freebusy
install -o root -g root -m 644 -t /var/lib/freebusy $TEMPLATE_FOLDER/var/lib/freebusy/index.php
sed -i -e "s/\[-SOGO_PASSWORD_FREEBUSY-\]/$SOGO_PASSWORD_FREEBUSY/" /var/lib/freebusy/index.php
eseriReplaceValues /var/lib/freebusy/index.php
htpasswd -c -b /etc/apache2/sogo.passwd system-freebusy "$SOGO_PASSWORD_FREEBUSY"

# Apache configuration
install -o root -g root -m 644 -t /etc/apache2/sites-available $TEMPLATE_FOLDER/etc/apache2/sites-available/sogo
sed -i -e "s|\[-LDAP_PASSWORD_SOGO-\]|${LDAP_PASSWORD_SOGO}|g" /etc/apache2/sites-available/sogo
DOMAIN_ESCAPED=$(echo "$DOMAIN" | sed 's/\./\\./g')
sed -i -e "s/\[-DOMAIN_ESCAPED-\]/${DOMAIN_ESCAPED}/g" /etc/apache2/sites-available/sogo
eseriReplaceValues /etc/apache2/sites-available/sogo
a2dissite default
a2ensite sogo
mv /etc/apache2/conf.d/SOGo.conf /etc/apache2/conf.d/sogo.conf
sed -i -e "s%^.*x-webobjects-server-port.*$%  RequestHeader set \"x-webobjects-server-port\" \"80\"%" \
-e "s%^.*x-webobjects-server-name.*$%  RequestHeader set \"x-webobjects-server-name\" \"gaia.$DOMAIN\"%" \
-e "s%^.*x-webobjects-server-url.*$%  # Commented out for third level domains to work in domain config 2.3\n  #RequestHeader set \"x-webobjects-server-url\" \"http://webmail.$DOMAIN\"%" \
 /etc/apache2/conf.d/sogo.conf

# Restart Apache2
service apache2 restart

exit 0
