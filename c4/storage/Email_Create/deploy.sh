#!/bin/bash
#
# Email server deploy script - v3.4
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
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
echo "$(date) Deploy Email Server"

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
EMAIL_DOMAIN=$(getParameter email_domain)
IT_MAN_USER=$(getParameter manager_username)
LDAP_LIBNSS_PW=$(getPassword LDAP_PASSWORD_LIBNSS)
LDAP_POSTFIX_PW=$(getPassword LDAP_PASSWORD_POSTFIX)
LDAP_DOVECOT_PW=$(getPassword LDAP_PASSWORD_DOVECOT)
PGSQL_DSPAM_PW=$(getPassword DB_PASSWORD_DSPAM)

# Variables
SYSTEM_SSL_FOLDER=/etc/ssl
SYSTEM_SSL_CERTS_FOLDER=$SYSTEM_SSL_FOLDER/certs
SYSTEM_SSL_PRIVATE_FOLDER=$SYSTEM_SSL_FOLDER/private
SYSTEM_DEFAULT_FOLDER=/etc/default
SYSTEM_MAIL_FOLDER=/etc/mail
VMAIL_USER=vmail
VMAIL_HOME=/var/spool/$VMAIL_USER
DSPAM_CONFIG_FOLDER=/etc/dspam  
DSPAM_HOME_DIR=/var/spool/dspam

POSTFIX_CONFIG_FOLDER=/etc/postfix
POSTFIX_DSPAM_FOLDER=/var/spool/postfix/dspam
DOVECOT_CONFIG_FOLDER=/etc/dovecot
DOVECOT_IMAP_PLUGIN_FOLDER=/usr/lib/dovecot/modules/imap
DSPAM_USER=dspam
POSTFIX_USER=postfix
DOVECOT_USER=dovecot

# Template files
LIBNSS_LDAP_CONFIG=/etc/ldap.conf
LIBNSS_LDAP_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}${LIBNSS_LDAP_CONFIG}
POSTFIX_LDAP_CONFIG_FOLDER=$POSTFIX_CONFIG_FOLDER/ldap
POSTFIX_MAIN_CONFIG=$POSTFIX_CONFIG_FOLDER/main.cf
POSTFIX_CLIENT_ACCESS=$POSTFIX_CONFIG_FOLDER/client_access
POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
POSTFIX_LDAP_VIRTUAL_ALIAS_MAPS=$POSTFIX_LDAP_CONFIG_FOLDER/virtual_alias_maps.cf
POSTFIX_LDAP_VIRTUAL_ALIAS_FORWARD_MAPS=$POSTFIX_LDAP_CONFIG_FOLDER/virtual_alias_forward_maps.cf
POSTFIX_LDAP_VIRTUAL_ALIAS_ONLYFORWARD_MAPS=$POSTFIX_LDAP_CONFIG_FOLDER/virtual_alias_onlyforward_maps.cf
POSTFIX_LDAP_VIRTUAL_MAILBOX_LIMIT=$POSTFIX_LDAP_CONFIG_FOLDER/virtual_mailbox_limits.cf
POSTFIX_LDAP_VIRTUAL_MAILBOX_MAPS=$POSTFIX_LDAP_CONFIG_FOLDER/virtual_mailbox_maps.cf
POSTFIX_SENDER_LOGIN_MAPS=$POSTFIX_LDAP_CONFIG_FOLDER/smtpd_sender_login_maps.cf
DOVECOT_CONFIG=$DOVECOT_CONFIG_FOLDER/dovecot.conf
DOVECOT_LDAP_CONFIG=$DOVECOT_CONFIG_FOLDER/dovecot-ldap.conf
DK_DEFAULT_CONFIG=$SYSTEM_DEFAULT_FOLDER/dk-filter
DKIM_CONFIG=/etc/dkim-filter.conf
DKIM_CONFIG_HOSTS=/etc/dkim.InternalSigningHosts.conf

# Archive files
SYSTEM_KRB5_KEYTAB=/etc/krb5.keytab
DOVECOT_KEYTAB=$DOVECOT_CONFIG_FOLDER/hera.dovecot.keytab

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# SSL certs
SMTP_SSL_CERT=$SYSTEM_SSL_CERTS_FOLDER/smtp.$DOMAIN.pem
SMTP_SSL_PRIVATE_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/smtp.$DOMAIN.pem
IMAP_SSL_CERT=$SYSTEM_SSL_CERTS_FOLDER/imap.$DOMAIN.pem
IMAP_SSL_PRIVATE_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/imap.$DOMAIN.pem
DKIM_SSL_CERT=$SYSTEM_SSL_CERTS_FOLDER/dkim.$DOMAIN.pem
DKIM_SSL_PRIVATE_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/dkim.$DOMAIN.pem
DKIM_PRIVATE_KEY=$SYSTEM_MAIL_FOLDER/dkim.key

# Get the Private IP address of the SMC C3.
SMC_MAIL_IP_PRIVATE=$(grep 'SMC_MAIL_IP_PRIVATE=' $ARCHIVE_FOLDER/SMC_HOST_IP.txt | sed 's|SMC_MAIL_IP_PRIVATE=||')
echo "SMC_MAIL_IP_PRIVATE is $SMC_MAIL_IP_PRIVATE"

# Deploy Keytab
install -o root -g root -m 440 $ARCHIVE_FOLDER/hera.host.keytab $SYSTEM_KRB5_KEYTAB

# Install libnss-ldap & nscd
debconf-set-selections $ARCHIVE_FOLDER/system/ldap-auth-config.seed
aptGetInstall nscd libnss-ldap
install -o root -g root -m 640 $LIBNSS_LDAP_TEMPLATE_CONFIG $LIBNSS_LDAP_CONFIG
eseriReplaceValues $LIBNSS_LDAP_CONFIG
sed -i "s/\[-LDAP_PASSWORD_LIBNSS-\]/$LDAP_LIBNSS_PW/" $LIBNSS_LDAP_CONFIG
/etc/init.d/nscd restart

# Install PAM Kerberos and PAM Foreground
aptGetInstall libpam-krb5 libpam-foreground

# Apply authentication configuration
install -o root -g root -m 644 -t /etc/auth-client-config/profile.d/ $ARCHIVE_FOLDER/system/eseri
auth-client-config -p eseri -a
/etc/init.d/nscd restart

# Create the vmail user
adduser --system --home $VMAIL_HOME --group --disabled-password --disabled-login $VMAIL_USER
chmod 770 $VMAIL_HOME
VMAIL_UID=$(getent passwd $VMAIL_USER|awk 'BEGIN { FS = ":" } ; { print $3 }')
VMAIL_GID=$(getent passwd $VMAIL_USER|awk 'BEGIN { FS = ":" } ; { print $4 }')

###############################################
# We have a new version of dspam, dspam-3.10.2
#   (with a newer version of Ubuntu this could be an apt-get)

# Dspam spool log dir
install -o $DSPAM_USER -g $DSPAM_USER -m 770 -d $DSPAM_HOME_DIR
install -o $DSPAM_USER -g $DSPAM_USER -m 775 -d $DSPAM_HOME_DIR/log

# Dspam run pid dir
install -o $DSPAM_USER -g $DSPAM_USER -m 755 -d /var/run/dspam

# Create the dspam user
adduser --system --home $DSPAM_HOME_DIR --group --disabled-password --disabled-login $DSPAM_USER

# Install DSPAM bin  --
install -o root -g root -m 755 -t /usr/bin/ $ARCHIVE_FOLDER/dspam/bin/dspam*
chmod 510 /usr/bin/dspam
chown $DSPAM_USER:$DSPAM_USER  /usr/bin/dspam

# Install DSPAM lib
install -o root -g root -m 644 -t /usr/lib/ $ARCHIVE_FOLDER/dspam/lib/libdspam.so.7.0.0
ln -s /usr/lib/libdspam.so.7.0.0 /usr/lib/libdspam.so.7
ln -s /usr/lib/libdspam.so.7.0.0 /usr/lib/libdspam.so

# Install DSPAM init
install -o root -g root -m 755 -t /etc/init.d/ $ARCHIVE_FOLDER/dspam/etc/init.d/dspam
ln -s /etc/init.d/dspam /etc/rc2.d/S21dspam

# dspam etc/default
install -o root -g root -m 644 -t /etc/default/ $ARCHIVE_FOLDER/dspam/etc/default/dspam

# DSPAM conf dir and file
mkdir $DSPAM_CONFIG_FOLDER
install -o $DSPAM_USER -g $DSPAM_USER -m 640 -t $DSPAM_CONFIG_FOLDER/ $ARCHIVE_FOLDER/dspam/etc/dspam.conf

eseriReplaceValues $DSPAM_CONFIG_FOLDER/dspam.conf
sed -i -e "s/\[-DB_PASSWORD_DSPAM-\]/$PGSQL_DSPAM_PW/g" $DSPAM_CONFIG_FOLDER/dspam.conf

# DSPAM cron tab
install -o root -g root -m 644 -t /etc/cron.d/                  $ARCHIVE_FOLDER/dspam/etc/dspam-cleanup
# DSPAM cron script
install -o root -g root -m 755 -t /usr/local/sbin/              $ARCHIVE_FOLDER/dspam/sbin/dspam-cleanup
eseriReplaceValues /usr/local/sbin/dspam-cleanup

# needed for vacuumdb
aptGetInstall postgresql-client

# DSPAM pg pasw
echo "pgsql.$DOMAIN:*:dspam:dspam:$PGSQL_DSPAM_PW" >/root/.pgpass
chmod 600 /root/.pgpass

###############################################
# Install DK and DKIM
aptGetInstall dk-filter dkim-filter

# Deploy Certificates
install -o root -g root -m 644 $ARCHIVE_FOLDER/dkim.${DOMAIN}_cert.pem $DKIM_SSL_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/dkim.${DOMAIN}_key.pem $DKIM_SSL_PRIVATE_KEY

# Deploy config files and modify values
[ -d $SYSTEM_MAIL_FOLDER ] || mkdir $SYSTEM_MAIL_FOLDER
install -o dk-filter -g dkim-filter -m 440 $DKIM_SSL_PRIVATE_KEY $DKIM_PRIVATE_KEY
install -o root -g root -m 644 $ARCHIVE_FOLDER/dkim-filter/dkim-filter /etc/default/dkim-filter
install -o root -g root -m 644 ${TEMPLATE_FOLDER}$DK_DEFAULT_CONFIG $DK_DEFAULT_CONFIG
eseriReplaceValues $DK_DEFAULT_CONFIG
install -o root -g root -m 644 ${TEMPLATE_FOLDER}$DKIM_CONFIG $DKIM_CONFIG
eseriReplaceValues $DKIM_CONFIG
install -o root -g root -m 644 ${TEMPLATE_FOLDER}$DKIM_CONFIG_HOSTS $DKIM_CONFIG_HOSTS
eseriReplaceValues $DKIM_CONFIG_HOSTS

# Install the LDAP extension to postfix
echo "postfix	postfix/main_mailer_type	select	No configuration" | debconf-set-selections
aptGetInstall postfix-ldap

# Install postgrey
aptGetInstall postgrey
# change the port, delay
sed -i -e "s/10023/127.0.0.1:60000 --delay=60/g" /etc/default/postgrey

# Install the postmaster report
aptGetInstall pflogsumm

# Deploy config files and modify values
install -o root -g root -m 644 $ARCHIVE_FOLDER/postfix/master.cf $POSTFIX_CONFIG_FOLDER/
install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/postfix/header_checks.regexp $POSTFIX_CONFIG_FOLDER/header_checks.regexp
install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/postfix/main.cf $POSTFIX_MAIN_CONFIG
sed -i -e "s/\[-VMAIL_UID-\]/$VMAIL_UID/g" -e "s/\[-VMAIL_GID-\]/$VMAIL_GID/g" $POSTFIX_MAIN_CONFIG
eseriReplaceValues $POSTFIX_MAIN_CONFIG
[ -n "$EMAIL_DOMAIN" ] && sed -i -e "/^virtual_mailbox_domains/s|$|, $EMAIL_DOMAIN|" $POSTFIX_MAIN_CONFIG
touch   /etc/postfix/whitelist
postmap /etc/postfix/whitelist

install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/postfix/client_access $POSTFIX_CLIENT_ACCESS
eseriReplaceValues $POSTFIX_CLIENT_ACCESS
postmap $POSTFIX_CLIENT_ACCESS
touch $POSTFIX_TRANSPORT
postmap $POSTFIX_TRANSPORT
mkdir $POSTFIX_LDAP_CONFIG_FOLDER
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/virtual_alias_maps.cf $POSTFIX_LDAP_VIRTUAL_ALIAS_MAPS
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_LDAP_VIRTUAL_ALIAS_MAPS
eseriReplaceValues $POSTFIX_LDAP_VIRTUAL_ALIAS_MAPS
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/virtual_alias_forward_maps.cf $POSTFIX_LDAP_VIRTUAL_ALIAS_FORWARD_MAPS
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_LDAP_VIRTUAL_ALIAS_FORWARD_MAPS
eseriReplaceValues $POSTFIX_LDAP_VIRTUAL_ALIAS_FORWARD_MAPS
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/virtual_alias_onlyforward_maps.cf $POSTFIX_LDAP_VIRTUAL_ALIAS_ONLYFORWARD_MAPS
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_LDAP_VIRTUAL_ALIAS_ONLYFORWARD_MAPS
eseriReplaceValues $POSTFIX_LDAP_VIRTUAL_ALIAS_ONLYFORWARD_MAPS
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/virtual_mailbox_limits.cf $POSTFIX_LDAP_VIRTUAL_MAILBOX_LIMIT
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_LDAP_VIRTUAL_MAILBOX_LIMIT
eseriReplaceValues $POSTFIX_LDAP_VIRTUAL_MAILBOX_LIMIT
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/virtual_mailbox_maps.cf $POSTFIX_LDAP_VIRTUAL_MAILBOX_MAPS
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_LDAP_VIRTUAL_MAILBOX_MAPS
eseriReplaceValues $POSTFIX_LDAP_VIRTUAL_MAILBOX_MAPS
install -o root -g $POSTFIX_USER -m 640 $TEMPLATE_FOLDER/etc/postfix/ldap/smtpd_sender_login_maps.cf $POSTFIX_SENDER_LOGIN_MAPS
sed -i -e "s/\[-LDAP_PASSWORD_POSTFIX-\]/$LDAP_POSTFIX_PW/g" $POSTFIX_SENDER_LOGIN_MAPS
eseriReplaceValues $POSTFIX_SENDER_LOGIN_MAPS
if [ -n "$EMAIL_DOMAIN" ]; then
	echo "$EMAIL_DOMAIN" > /etc/mailname
else
	echo "$DOMAIN" > /etc/mailname
fi

# Deploy Certificates
install -o root -g root -m 644 $ARCHIVE_FOLDER/smtp.${DOMAIN}_cert.pem $SMTP_SSL_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/smtp.${DOMAIN}_key.pem $SMTP_SSL_PRIVATE_KEY
adduser $POSTFIX_USER ssl-cert

# Create aliases database
sed -i -e "s/^\(postmaster: *\)root/\1 postmaster@$DOMAIN/g"  /etc/aliases
echo "root: sysadmin@$SYSTEM_ANCHOR_DOMAIN" >> /etc/aliases
postalias /etc/aliases

# Purge ssmtp
dpkg --purge ssmtp

# DSpam folder in the Postfix chroot
install -o $POSTFIX_USER -g $DSPAM_USER -m 770 -d $POSTFIX_DSPAM_FOLDER

###############################################
# Install Amavis
aptGetInstall amavisd-new spamassassin clamav-daemon libnet-dns-perl libmail-spf-query-perl \
              pyzor razor arj bzip2 cabextract cpio file gzip lha nomarch pax rar unrar unzip zip zoo

# these users need to be in each others groups
adduser amavis clamav
adduser clamav amavis

# Disable spamassassin
sed -i -e "s/ \(\['SpamAssassin', 'Amavis::SpamControl::SpamAssassin' \],\)/ ###C4 \1/g" /usr/sbin/amavisd-new
# Amavis it was too aggressive for us. permit the banned content
sed -i -e "s/\(\$final_banned_destiny *= \)D_BOUNCE;/\1 D_PASS;/g" /etc/amavis/conf.d/20-debian_defaults
# Allow attachments with .bat - This is for EnterpriseLibre new user welcome email with attachement.
sed -i -e 's/|bat|/|/g' /etc/amavis/conf.d/20-debian_defaults

# uncommented to enable:
sed -i -e "s/\#\(\@bypass_virus_checks_maps\)/\1/g" /etc/amavis/conf.d/15-content_filter_mode
sed -i -e "s/\#\( *\\\%bypass_virus_checks\)/\1/g"  /etc/amavis/conf.d/15-content_filter_mode

# install a first set of virus sigs
tar --directory=/var/lib/clamav xzf archive/Email/clamav/clamav-daily.cld.tar.gz
chown clamav /var/lib/clamav/daily.cld
tar --directory=/var/lib/clamav xzf archive/Email/clamav/clamav-main.cvd.tar.gz
chown clamav /var/lib/clamav/main.cvd

###############################################
# Install Dovecot
aptGetInstall dovecot-imapd

# Deploy config files and modify values
install -o root -g root -m 644 $ARCHIVE_FOLDER/dovecot/dovecot.pam /etc/pam.d/dovecot
install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/dovecot/dovecot.conf $DOVECOT_CONFIG
parseCapabilities $DOVECOT_CONFIG
sed -i -e "s/\[-VMAIL_UID-\]/$VMAIL_UID/g" -e "s/\[-VMAIL_GID-\]/$VMAIL_GID/g" $DOVECOT_CONFIG
eseriReplaceValues $DOVECOT_CONFIG
install -o root -g root -m 640 $TEMPLATE_FOLDER/etc/dovecot/dovecot-ldap.conf $DOVECOT_LDAP_CONFIG
sed -i -e "s/\[-LDAP_PASSWORD_DOVECOT-\]/$LDAP_DOVECOT_PW/g" $DOVECOT_LDAP_CONFIG
eseriReplaceValues $DOVECOT_LDAP_CONFIG

# Deploy Keytab
install -o root -g $DOVECOT_USER -m 440 $ARCHIVE_FOLDER/hera.dovecot.keytab $DOVECOT_KEYTAB

# Deploy Certificates
install -o root -g root -m 644 $ARCHIVE_FOLDER/imap.${DOMAIN}_cert.pem $IMAP_SSL_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/imap.${DOMAIN}_key.pem $IMAP_SSL_PRIVATE_KEY
adduser $DOVECOT_USER ssl-cert

# Install Dovecot cron to check if process is running currently. If not, then it would restart dovecot.
# Added as a counter to when the server reboots, the container go through a suspend/resume which in turn causes the dovecot process to not load properly (ie. /var/run/dovecot/auth-master gets owned by root instead of vmail - which creates problems. Logs show errors about imap-login and managesieve-login failing with a permissions denied error.)
install -o root -g root -m 644 -t /etc/cron.d/ $ARCHIVE_FOLDER/files/etc/cron.d/dovecot

###############################################
hasCapability MailingLists
if [ $? -eq 0 ] ; then
	# Configure postfix hook
	if [ -n "$EMAIL_DOMAIN" ]; then
		echo "lists.$EMAIL_DOMAIN	mailman:" >>$POSTFIX_TRANSPORT
	else
		echo "lists.$DOMAIN	mailman:" >>$POSTFIX_TRANSPORT
	fi
	postmap $POSTFIX_TRANSPORT

	# Install Mailman
	debconf-set-selections $ARCHIVE_FOLDER/mailman/mailman.seed
	aptGetInstall mailman apache2-mpm-prefork

	#Deploy new ports.conf
	install -o www-data -g www-data -m 755 $TEMPLATE_FOLDER/etc/apache2/ports.conf /etc/apache2/ports.conf
	sed -i -e "s/\[-NETWORK-\]/$NETWORK/g" /etc/apache2/ports.conf

	# Deploy config files and modify values
	install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/apache2/sites-available/mailinglists /etc/apache2/sites-available/mailinglists
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-IP_ADDRESS-\]/$IP/" /etc/apache2/sites-available/mailinglists
	install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/mailman/mm_cfg.py /etc/mailman/
	eseriReplaceValues /etc/apache2/sites-available/mailinglists
	if [ -n "$EMAIL_DOMAIN" ]; then
		sed -i -e "s/\[-EMAIL_DOMAIN-\]/$EMAIL_DOMAIN/g" /etc/mailman/mm_cfg.py
	else
		sed -i -e "s/\[-EMAIL_DOMAIN-\]/$DOMAIN/g" /etc/mailman/mm_cfg.py
	fi
	eseriReplaceValues /etc/mailman/mm_cfg.py

	# Apache config
	#Setup default site
	install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/apache2/sites-available/default /etc/apache2/sites-available/default
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-IP_ADDRESS-\]/$IP/" /etc/apache2/sites-available/default
	a2ensite default

	a2ensite mailinglists

	# Create Apache root folder for mailman
	mkdir /var/lib/mailman/www/

	# Create Site Password & the default list
	MAILMAN_LISTCREATOR_PW=$(getPassword MAILMAN_LISTCREATOR_PASSWORD)
	MAILMAN_MAILMANLIST_PW=$(getPassword MAILMAN_MAILMANLIST_PASSWORD)

	mmsitepass -c "$MAILMAN_LISTCREATOR_PW"
	newlist -q mailman $IT_MAN_USER@$DOMAIN "$MAILMAN_MAILMANLIST_PW"

	# mailing list for postmaster
	# it could have a different password but same is good enough
	newlist -q postmaster $IT_MAN_USER@$DOMAIN "$MAILMAN_MAILMANLIST_PW"
fi
###############################################
hasCapability SOGo
if [ $? -eq 0 ] ; then
	# Create master user and password for Dovecot
	DOVECOT_MASTER_USER_PASSWORD=$(getPassword DOVECOT_MASTER_USER_PASSWORD)
	htpasswd -b -c -s /etc/dovecot/passwd.masterusers proxy "$DOVECOT_MASTER_USER_PASSWORD"
fi
###############################################
# Passwd file for EmailOnly Users - Initially empty
touch /etc/dovecot/passwd.emailonlyusers

# Restart servers (Note: The & is important after dspam start otherwise the ssh session will hang)
/etc/init.d/dspam start &
/etc/init.d/dovecot restart
/etc/init.d/dk-filter restart
/etc/init.d/dkim-filter restart
/etc/init.d/postfix restart
/etc/init.d/mailman start
/etc/init.d/apache2 reload

##################
##### Amanda #####
##################

hasCapability Amanda
if [ $? -eq 0 ]; then
    BACKUP_SERVER=$(getParameter backup_server)

    # Install the required packages
    aptGetInstall libcurl3
    aptGetInstall libreadline5
    aptGetInstall xinetd
    dpkg -i $ARCHIVE_FOLDER/packages/amanda/libkrb53_1.8.3+dfsg-4squeeze5_all.deb
    dpkg -i $ARCHIVE_FOLDER/packages/amanda/amanda-backup-client_3.3.1-1Ubuntu804_i386.deb

    # Copy the xinetd configuration for Amanda
    install -o root -g root -m 644 /var/lib/amanda/example/xinetd.amandaclient /etc/xinetd.d/amandaclient
    /etc/init.d/xinetd restart

    # Adding the Backup Server details
    cd /var/lib/amanda
    echo $BACKUP_SERVER backup amdump >> .amandahosts
    echo AnyDish65 >> .am_passphrase
    chown amandabackup:disk ~amandabackup/.amandahosts
    chown amandabackup:disk ~amandabackup/.am_passphrase
    chown amandabackup:disk ~amandabackup/.profile
    chmod 700 ~amandabackup/.amandahosts
    chmod 700 ~amandabackup/.am_passphrase
    chown amandabackup:disk /usr/sbin/amcryptsimple
    chmod 750 /usr/sbin/amcryptsimple

    # Copy the conf file for amrecover
    install -o amandabackup -g disk -m 600 $TEMPLATE_FOLDER/etc/amanda/amanda-client.conf /etc/amanda/amanda-client.conf
    sed -i "s|\[-BACKUP_SERVER-\]|$BACKUP_SERVER|" /etc/amanda/amanda-client.conf

    # Copy the excludePath file
    install -o amandabackup -g disk -d /etc/amanda/exclude
    install -o amandabackup -g disk -m 644 -t /etc/amanda/exclude/ $ARCHIVE_FOLDER/files/etc/amanda/exclude/excludePath
fi

exit 0
