#!/bin/bash
#
# Web server 2 deploy script - v1.8
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2013 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy Web Server 2"

ORGNAME=$(getParameter short_domain)
IT_MAN_USER=$(getParameter manager_username)
ORG_FULL_NAME=$(getParameter longname)

eseriGetDNS
eseriGetNetwork

# Install necessary packages
aptGetInstall apache2 libapache2-mod-auth-kerb libapache2-mod-passenger php-gettext php-log php-mail php-mail-mime php-net-smtp mysql-client-5.5 curl php5 php5-tidy php5-mysql php5-pgsql php5-mcrypt php5-ldap php5-imap php5-gd php5-common php5-cli php-pear libapache2-mod-php5 unzip patch

a2enmod rewrite
a2enmod headers
a2enmod passenger
a2enmod auth_kerb

# Set up PHP5
# install -o root -g root -m 644 $ARCHIVE_FOLDER/files/etc/php5/apache2/php.ini /etc/php5/apache2/php.ini
# install -o root -g root -m 644 $ARCHIVE_FOLDER/files/etc/php5/cli/php.ini /etc/php5/cli/php.ini

# Set up Apache2
# Copy Keytab
mv $ARCHIVE_FOLDER/trident.apache2.keytab /etc/apache2/apache2.keytab
chown www-data /etc/apache2/apache2.keytab
chmod 0400 /etc/apache2/apache2.keytab
# Enable default site
install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/apache2/sites-available/default /etc/apache2/sites-available/default
sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-IP-\]/$IP/" /etc/apache2/sites-available/default
a2ensite default
# Deploy new ports.conf
install -o www-data -g www-data -m 755 $TEMPLATE_FOLDER/etc/apache2/ports.conf /etc/apache2/ports.conf
sed -i -e "s/\[-NETWORK-\]/$NETWORK/g" /etc/apache2/ports.conf

# Deploy eseriman user
adduser --gecos "Eseriman" --disabled-password eseriman --home $ESERIMAN_HOME
chmod 750 $ESERIMAN_HOME
install -o root -g root -m 755 -d $ESERIMAN_HOME/bin
install -o eseriman -g eseriman -m 700 -d $ESERIMAN_HOME/.ssh
install -o eseriman -g eseriman -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys.c3 $ESERIMAN_HOME/.ssh/authorized_keys
SUDOERS_ESERIMAN='/etc/init.d/apache2, /usr/sbin/a2ensite, /usr/sbin/a2dissite'

# Needs to be upgraded:
# Timesheet
# Nuxeo
# Mediawiki
# SQL-ledger
# system manager

###################
##### Redmine #####
###################
hasCapability Redmine
if [ $? -eq 0 ] ; then
	REDMINE_FOLDER=/usr/share/redmine
	REDMINE_ETC_FOLDER=/etc/redmine/default
	DB_PASSWORD_REDMINE=$(getPassword DB_PASSWORD_REDMINE)

	# Redmine Installation
	echo "redmine redmine/instances/default/internal/skip-preseed select true" | debconf-set-selections
        echo "dbconfig-common dbconfig-common/database-type select pgsql" | debconf-set-selections
        echo "redmine redmine/instances/default/dbconfig-install boolean false" | debconf-set-selections
	aptGetInstall redmine redmine-pgsql

	# Redmine Configuration
	install -o root -g www-data -m 640 $TEMPLATE_FOLDER/etc/redmine/default/database.yml $REDMINE_ETC_FOLDER
	sed -i -e "s|\[-DB_PASSWORD_REDMINE-\]|$DB_PASSWORD_REDMINE|g;s|\[-DOMAIN-\]|$DOMAIN|g" $REDMINE_ETC_FOLDER/database.yml
	install -o root -g www-data -m 640 $TEMPLATE_FOLDER/etc/redmine/default/configuration.yml $REDMINE_ETC_FOLDER
	sed -i -e "s|\[-DOMAIN-\]|$DOMAIN|g" $REDMINE_ETC_FOLDER/configuration.yml
	install -o root -g root -m 644 $TEMPLATE_FOLDER/transient/settings.yml $REDMINE_FOLDER/config/
	sed -i -e "s|\[-DOMAIN-\]|$DOMAIN|g" $REDMINE_FOLDER/config/settings.yml
	# Setting server timezone to UTC, since there is no offset information in the timestamps stored in the DB.
	sed -i '/# config.active_record.default_timezone/s|#||' $REDMINE_FOLDER/config/environment.rb

	# Installing HTTP SSO Module
	tar -C $REDMINE_FOLDER/vendor/plugins/ -zxvf $ARCHIVE_FOLDER/Redmine/plugins/redmine_http_auth.tar.gz
	install -o root -g root -m 644 $TEMPLATE_FOLDER/transient/http_auth_patch.rb $REDMINE_FOLDER/vendor/plugins/redmine_http_auth/lib/
	sed -i -e "s|\[-REALM-\]|$REALM|g" $REDMINE_FOLDER/vendor/plugins/redmine_http_auth/lib/http_auth_patch.rb
	
	# Apache2 Configuration
	install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/apache2/sites-available/redmine /etc/apache2/sites-available/redmine
        sed -i -e "s|\[-DOMAIN-\]|$DOMAIN|g;s|\[-REALM-\]|$REALM|g;s|\[-IP-\]|$IP|g" /etc/apache2/sites-available/redmine
	a2ensite redmine
	
	# Eseriman C3 Script
	install -o root -g root -m 500 $TEMPLATE_FOLDER/var/lib/eseriman/bin/createRedmineUser.sh $ESERIMAN_HOME/bin/
	sed -i -e "s|\[-DB_PASSWORD_REDMINE-\]|$DB_PASSWORD_REDMINE|g" $ESERIMAN_HOME/bin/createRedmineUser.sh
	chmod u+s $ESERIMAN_HOME/bin/createRedmineUser.sh

	#Sudoers eseriman
	SUDOERS_ESERIMAN+=', /var/lib/eseriman/bin/createRedmineUser.sh'
fi
	
#########################
##### PHPScheduleIt #####
#########################
hasCapability PHPScheduleIt
if [ $? -eq 0 ] ; then
	PHPSCHEDULEIT_FOLDER=/var/lib/phpscheduleit
	DB_PASSWORD_PHPSCHEDULEIT=$(getPassword DB_PASSWORD_PHPSCHEDULEIT)

	# PHPScheduleIt Installation
	tar -C /var/lib/ -zxvf $ARCHIVE_FOLDER/PHPScheduleIt/phpscheduleit-2.4.2.tar.gz
	rm -rf $PHPSCHEDULEIT_FOLDER/Web/install/
	chmod 770 $PHPSCHEDULEIT_FOLDER/Web/uploads/images/
	chown -R www-data:www-data $PHPSCHEDULEIT_FOLDER
	install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/transient/config.php $PHPSCHEDULEIT_FOLDER/config/
	sed -i -e "s|\[-TIMEZONE-\]|$TIMEZONE|g;s|\[-IT_MAN_USER-\]|$IT_MAN_USER|g;s|\[-DOMAIN-\]|$DOMAIN|g;s|\[-DB_PASSWORD_PHPSCHEDULEIT-\]|$DB_PASSWORD_PHPSCHEDULEIT|g;" $PHPSCHEDULEIT_FOLDER/config/config.php
	
	# Apply SSO patch
	patch -u $PHPSCHEDULEIT_FOLDER/lib/Application/Authentication/WebAuthentication.php < $ARCHIVE_FOLDER/PHPScheduleIt/patch/WebAuthentication.php.diff
	patch -u $PHPSCHEDULEIT_FOLDER/lib/Application/Authentication/IAuthentication.php < $ARCHIVE_FOLDER/PHPScheduleIt/patch/IAuthentication.php.diff

	# Apache2 Configuration
        install -o root -g root -m 644 $TEMPLATE_FOLDER/etc/apache2/sites-available/phpscheduleit /etc/apache2/sites-available/phpscheduleit
        sed -i -e "s|\[-DOMAIN-\]|$DOMAIN|g;s|\[-REALM-\]|$REALM|g;s|\[-IP-\]|$IP|g" /etc/apache2/sites-available/phpscheduleit
        a2ensite phpscheduleit
	
	# Eseriman C3 Script
        install -o root -g root -m 500 $TEMPLATE_FOLDER/var/lib/eseriman/bin/createPHPScheduleItUser.sh $ESERIMAN_HOME/bin/
        sed -i -e "s|\[-DB_PASSWORD_PHPSCHEDULEIT-\]|$DB_PASSWORD_PHPSCHEDULEIT|g;s|\[-ORGNAME-\]|$ORGNAME|g" $ESERIMAN_HOME/bin/createPHPScheduleItUser.sh
        chmod u+s $ESERIMAN_HOME/bin/createPHPScheduleItUser.sh

	# Sudoers eseriman
        SUDOERS_ESERIMAN+=', /var/lib/eseriman/bin/createPHPScheduleItUser.sh'
fi

# Modify sudoers file
cat >>/etc/sudoers <<EOF

# Eseri specific settings
Cmnd_Alias ESERIMAN = $SUDOERS_ESERIMAN
eseriman ALL=NOPASSWD: ESERIMAN
EOF
/etc/init.d/apache2 restart

exit 0
