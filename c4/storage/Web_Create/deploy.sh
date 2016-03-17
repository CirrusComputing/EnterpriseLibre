#!/bin/bash
#
# Web server deploy script - v3.4
#
# Created by Gregory Wolgemuth <gwolgemuth@cirruscomputing.com>
# Modified by Karoly Molnar <kmolnar@cirruscomputing.com> and Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# 2013 Feb RWL Upgraded SQL-ledger to 3.0.4 
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
# First things first, we do the initial Apache installation
# This includes all the modules, as well as the Kerberos key

. ${0%/*}/archive/eseriCommon

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
NETWORK=$(getParameter network)
ORG=$(getParameter short_domain)
IT_MAN_USER=$(getParameter manager_username)
ORG_FULL_NAME=$(getParameter longname)
SYSMANAGER_PASSWORD=$(getPassword DB_PASSWORD_SYSTEMMANAGER)

IP_ADDRESS="$NETWORK.32"
DOMAIN=`hostname -d`
REALM=`cat /etc/krb5.conf | grep default_realm | awk '{print $3}'`
BASE_DN=`cat /etc/ldap/ldap.conf | grep "^BASE" | grep -o "dc=.*"`

archive=${0%/*}/archive
template=${0%/*}/template
ESERIMAN_HOME=/var/lib/eseriman

# Install necessary packages
aptGetInstall libapache2-mod-chroot apache2 libapache2-mod-auth-kerb libapache2-mod-python patch libapache2-mod-wsgi python-clearsilver python-pysqlite2 python-subversion python-support subversion trac python-psycopg2 php-gettext php-log php-mail php-mail-mime php-net-smtp mysql-client-5.1 mediawiki libcatalyst-perl librpc-xml-perl libxml-simple-perl libcatalyst-modules-perl libconfig-general-perl libdbd-pg-perl curl php5 php5-tidy php5-mysql php5-pgsql php5-mcrypt php5-ldap php5-imap php5-gd php5-common php5-cli php-pear libapache2-mod-php5 unzip

a2enmod proxy_ajp
a2enmod rewrite
a2enmod headers
a2enmod auth_kerb
a2enmod mod_chroot

mv $archive/poseidon.apache2.keytab /etc/apache2/apache2.keytab
chown www-data /etc/apache2/apache2.keytab
chmod 0400 /etc/apache2/apache2.keytab

mv $archive/files/etc/php5/apache2/php.ini /etc/php5/apache2/php.ini
mv $archive/files/etc/php5/cli/php.ini /etc/php5/cli/php.ini

#Deploy new ports.conf
install -o www-data -g www-data -m 755 $template/etc/apache2/ports.conf /etc/apache2/ports.conf
sed -i -e "s/\[-NETWORK-\]/$NETWORK/g" /etc/apache2/ports.conf

# Deploy eseriman user if Vtiger or SQLLedger is being deployed
function deployEseriman
{
	adduser --gecos "Eseriman" --disabled-password eseriman --home $ESERIMAN_HOME
	chmod 750 $ESERIMAN_HOME
	install -o root -g root -m 755 -d $ESERIMAN_HOME/bin
	mv $template/var/lib/eseriman/bin/ldapUser.sh $ESERIMAN_HOME/bin/
}

hasCapability Vtiger
if [ $? -eq 0 ] ; then
	deployEseriman
else
	hasCapability SQLLedger
	if [ $? -eq 0 ] ; then
		deployEseriman
	fi
fi

# Timesheet
hasCapability Timesheet
if [ $? -eq 0 ] ; then
	#Adding timesheet to sites-available under /etc/apache2
	TIMESHEET_PASSWORD=$(getPassword DB_PASSWORD_TIMESHEET)
	cat $template/etc/apache2/sites-available/timesheet | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-NETWORK-\]|$NETWORK|;s|\[-REALM-\]|$REALM|;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" > /etc/apache2/sites-available/timesheet

	#Untar timesheet
	tar -C /var/lib/ -zxvf $archive/Timesheet/timesheet-ng-1.5.2/timesheet-ng-1.5.2.tar.gz		
	sed -i -e "s/__DBHOST__/mysql.$DOMAIN/g;s/__DBNAME__/timesheet/g;s/__DBUSER__/timesheet/g;s/__DBPASS__/$TIMESHEET_PASSWORD/g;s/__DBPASSWORDFUNCTION__/SHA1/g" /var/lib/timesheet/database_credentials.inc

	#Putting in proper permissions
	chown -R root:root /var/lib/timesheet
	cd /var/lib/timesheet
	chown www-data:www-data .htaccess
	chown www-data:www-data database_credentials.inc
	chown www-data:www-data table_names.inc

	#Adding timesheet to sites-enabled under /etc/apache2
	a2ensite timesheet
fi

# Nuxeo
hasCapability Nuxeo
if [ $? -eq 0 ] ; then
	install -o root -g root -m 644 $template/etc/apache2/sites-available/nuxeo /etc/apache2/sites-available/nuxeo
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/g;s/\[-REALM-\]/$REALM/g;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" /etc/apache2/sites-available/nuxeo

	a2ensite nuxeo
fi

# Mediawiki
hasCapability Wiki
if [ $? -eq 0 ] ; then
	WIKI_PASSWORD=$(getPassword DB_PASSWORD_WIKI)
	WIKI_LDAP_PASSWORD=$(getPassword LDAP_PASSWORD_WIKI)
	install -o root -g root -m 644 $template/etc/apache2/sites-available/wiki /etc/apache2/sites-available/wiki
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/g;s/\[-REALM-\]/$REALM/g;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" /etc/apache2/sites-available/wiki
	install -o root -g root -m 644 $template/etc/mediawiki/LocalSettings.php /etc/mediawiki/LocalSettings.php
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/g;s/\[-REALM-\]/$REALM/g;s/\[-DB_PASSWORD_WIKI-\]/$WIKI_PASSWORD/g;s|\[-TIMEZONE-\]|$TIMEZONE|g;s/\[-LDAP_BASE_DN-\]/$BASE_DN/g;s/\[-LDAP_PASSWORD_WIKI-\]/$WIKI_LDAP_PASSWORD/g" /etc/mediawiki/LocalSettings.php
	install -o root -g root -m 644 $archive/Wiki/*.php /var/lib/mediawiki/extensions/
	install -o root -g root -m 644 $archive/Wiki/wikEd.js /var/lib/mediawiki/extensions/

	a2ensite wiki
fi
hasCapability OrangeHRM
if [ $? -eq 0 ] ; then
	# OrangeHRM
	ORANGEHRM_PASSWORD=$(getPassword DB_PASSWORD_ORANGEHRM)
	cd /root
	tar -xzf $archive/OrangeHRM/orangehrm-2.5.tar.gz
	mv /root/orangehrm-2.5/orangehrm-2.5 /var/lib/orangehrm
	chown -R root:root /var/lib/orangehrm
	chmod -R 644 /var/lib/orangehrm
	if [ ! -d /var/lib/orangehrm/lib/confs/temp ] ; then
		mkdir /var/lib/orangehrm/lib/confs/temp
	fi
	chown www-data:www-data /var/lib/orangehrm/lib/confs/temp
	chmod 755 /var/lib/orangehrm/lib/confs/temp
	cat $template/etc/apache2/sites-available/orangehrm | sed -e "s/\[-DOMAIN-\]/$DOMAIN/g;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" > /etc/apache2/sites-available/orangehrm
	chown root:root /etc/apache2/sites-available/orangehrm
	chmod 644 /etc/apache2/sites-available/orangehrm
	cat $template/var/lib/orangehrm/lib/confs/Conf.php | sed -e "s/\[-DOMAIN-\]/$DOMAIN/g;s/\[-DB_PASSWORD_ORANGEHRM-\]/$ORANGEHRM_PASSWORD/" > /var/lib/orangehrm/lib/confs/Conf.php
	chown root:root /var/lib/orangehrm/lib/confs/Conf.php
	chmod 644 /var/lib/orangehrm/lib/confs/Conf.php
	chown www-data:www-data /var/lib/orangehrm/.htaccess
	find /var/lib/orangehrm/ -type d -exec chmod a+x {} \;

	a2ensite orangehrm

	#Cleanup OrangeHRM
	rm -rf /root/orangehrm-2.5
fi
hasCapability Trac
if [ $? -eq 0 ] ; then
	TRAC_PASSWORD=$(getPassword DB_PASSWORD_TRAC)
	# Start Trac installation
	# First, install and layout SVN
	mkdir /var/lib/svn
	svnadmin create /var/lib/svn/$ORG
	mkdir svntmp && cd svntmp
	mkdir trunk
	mkdir branches
	mkdir tags
	svn import . file:///var/lib/svn/$ORG --message 'Initial repository layout'
	cd ../
	rm -rf svntmp

	# Now work on adding in Trac itself
	mkdir -p /var/lib/trac/$ORG
	trac-admin /var/lib/trac/$ORG initenv "$ORG" "postgres://trac:$TRAC_PASSWORD@pgsql.$DOMAIN/trac" svn /var/lib/svn/$ORG

	# Fine tune Trac
	sed -i -e "s/^max_size.*$/max_size = 524288/" \
	-e "s/^alt = \(please configure the \[header_logo\] section in trac.ini\)/alt = /" \
	-e "s|^src = site/your_project_logo.png|src = common/trac_banner.png|" \
	-e "s/^always_notify_owner.*$/always_notify_owner = true/" \
	-e "s/^always_notify_reporter.*$/always_notify_reporter = true/" \
	-e "s/^smtp_enabled.*$/smtp_enabled = true/" \
	-e "s/^smtp_port.*$/smtp_port = 10026/" \
	-e "s/^smtp_from.*$/smtp_from = trac@$DOMAIN/" \
	-e "s/^smtp_replyto.*$/smtp_replyto = trac@$DOMAIN/" \
	-e "s/^smtp_server.*$/smtp_server = smtp.$DOMAIN/" \
	-e "s|^url.*$|url = http://trac.$DOMAIN/|" \
	-e "s/^restrict_owner.*$/restrict_owner = true/" \
	-e "s/^default_charset.*$/default_charset = utf-8/" \
	-e "s|^templates_dir.*$|templates_dir = /usr/share/trac/templates|" \
	-e "s|^link.*$|link = http://trac.$DOMAIN/|" \
	-e "s/^name.*$/name = $ORG_FULL_NAME Trac/" \
	-e "s/^descr.*$/descr = $ORG_FULL_NAME Trac Project/" \
	-e "s/^log_type.*$/log_type = file/" \
	-e "s|^log_file.*$|log_file = /var/lib/trac/$ORG/log/trac.log|" \
	-e "s/^max_preview_size.*$/max_preview_size = 524288/" /var/lib/trac/$ORG/conf/trac.ini

	# Integrate Trac with Apache
	patch /usr/share/pyshared/trac/web/api.py $archive/Trac/api.py.diff
	patch /usr/share/pyshared/trac/web/auth.py $archive/Trac/auth.py.diff
	patch /usr/share/pyshared/trac/web/chrome.py $archive/Trac/chrome.py.diff
	patch /usr/share/pyshared/trac/web/main.py $archive/Trac/main.py.diff
	mkdir /var/lib/trac/$ORG/apache /var/lib/trac/$ORG/eggs/
	chown www-data /var/lib/trac/$ORG/eggs /var/lib/trac/$ORG/attachments/
	install -o root -g root -m 644 $template/transient/trac.wsgi /var/lib/trac/$ORG/apache/trac.wsgi
	sed -i -e "s/\[-ORG-\]/$ORG/" /var/lib/trac/$ORG/apache/trac.wsgi
	install -o root -g root -m 644 $template/etc/apache2/sites-available/trac /etc/apache2/sites-available/trac
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-REALM-\]/$REALM/;s/\[-ORG-\]/$ORG/;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" /etc/apache2/sites-available/trac
	a2ensite trac

	# Create the admin group and add the IT Manager to it
	trac-admin /var/lib/trac/$ORG/ permission add authenticated REPORT_CREATE REPORT_MODIFY
	trac-admin /var/lib/trac/$ORG/ permission add trac.admin CONFIG_VIEW MILESTONE_ADMIN REPORT_ADMIN ROADMAP_ADMIN TICKET_ADMIN TRAC_ADMIN WIKI_ADMIN
	trac-admin /var/lib/trac/$ORG/ permission add $IT_MAN_USER trac.admin

	# Make sure that www-data can write the log folder and the files in it
	chown www-data:www-data -R /var/lib/trac/$ORG/log/
fi

hasCapability Vtiger
if [ $? -eq 0 ] ; then
	DB_PASSWORD_VTIGER=$(getPassword DB_PASSWORD_VTIGER)
	VTIGER_LDAP_PASSWORD=$(getPassword LDAP_PASSWORD_VTIGER)
	#Setup VTiger
	mkdir /var/lib/vtigercrm
	tar -xzf $archive/VTiger/vtiger54.tar.gz -C /var/lib/vtigercrm
	rm /var/lib/vtigercrm/install.php
	rm -rf /var/lib/vtigercrm/install/

	#Generate unique key
	dd if=/dev/urandom of=/tmp/randseed bs=1024 count=1
	VTIGER_UNIQUE_KEY=`cat /tmp/randseed | md5sum | awk '{print $1'}`
	rm /tmp/randseed

	install -o root -g root -m 644 $template/var/lib/vtigercrm/config.inc.php /var/lib/vtigercrm/config.inc.php
	sed -i -e "s/\[-DB_PASSWORD_VTIGER-\]/$DB_PASSWORD_VTIGER/;s/\[-DOMAIN-\]/$DOMAIN/;s/\[-REALM-\]/$REALM/;s/\[-LDAP_BASE_DN-\]/$BASE_DN/;s/\[-LDAP_PASSWORD_VTIGER-\]/$VTIGER_LDAP_PASSWORD/;s/\[-VTIGER_UNIQUE_KEY-\]/$VTIGER_UNIQUE_KEY/" /var/lib/vtigercrm/config.inc.php

	install -o root -g root -m 644 $template/var/lib/vtigercrm/include/ldap/config.ldap.php /var/lib/vtigercrm/include/ldap/config.ldap.php
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-LDAP_BASE_DN-\]/$BASE_DN/g;s/\[-LDAP_PASSWORD_VTIGER-\]/$VTIGER_LDAP_PASSWORD/" /var/lib/vtigercrm/include/ldap/config.ldap.php

	install -o root -g root -m 644 $template/var/lib/vtigercrm/cron/config.cron.php /var/lib/vtigercrm/cron/config.cron.php
	install -o root -g root -m 644 $template/var/lib/vtigercrm/cron/config.cron.php /var/lib/vtigercrm/config.cron.php
	sed -i -e "s/\[-VTIGER_UNIQUE_KEY-\]/$VTIGER_UNIQUE_KEY/" /var/lib/vtigercrm/cron/config.cron.php
	sed -i -e "s/\[-VTIGER_UNIQUE_KEY-\]/$VTIGER_UNIQUE_KEY/" /var/lib/vtigercrm/config.cron.php

	#Added for vTiger 5.4 to configure user timezone
	install -o root -g root -m 644 $template/var/lib/vtigercrm/modules/Users/Users.php /var/lib/vtigercrm/modules/Users/Users.php
	sed -i -e "s|\[-TIMEZONE-\]|$TIMEZONE|" /var/lib/vtigercrm/modules/Users/Users.php

	install -o root -g root -m 644 $template/etc/apache2/sites-available/vtiger /etc/apache2/sites-available/vtiger
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-REALM-\]/$REALM/;s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" /etc/apache2/sites-available/vtiger

	#Portal configuration
	mkdir /var/lib/vtigercrm/portal
	unzip $archive/VTiger/vtigercrm-customerportal-5.4.0.zip -d /var/lib/vtigercrm/portal
	install -o root -g root -m 644 $template/var/lib/vtigercrm/portal/PortalConfig.php /var/lib/vtigercrm/portal/PortalConfig.php
	sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/" /var/lib/vtigercrm/portal/PortalConfig.php
	
	chown -R www-data:www-data /var/lib/vtigercrm/
	find /var/lib/vtigercrm/ -type d -exec chmod 755 {} \;
	find /var/lib/vtigercrm/ -type f -exec chmod 644 {} \;
	a2ensite vtiger

	#Change the www-data user's crontab
	echo "30 * * * * sh /var/lib/vtigercrm/cron/modules/SalesOrder/RecurringInvoiceCron.sh >> /var/log/vtiger_cron.log 2>&1
*/5 * * * * sh /var/lib/vtigercrm/cron/modules/com_vtiger_workflow/com_vtiger_workflow.sh >> /var/log/vtiger_cron.log 2>&1" | crontab -u www-data -
	touch /var/log/vtiger_cron.log
	chown www-data:www-data /var/log/vtiger_cron.log
	chmod u+x /var/lib/vtigercrm/cron/modules/SalesOrder/RecurringInvoiceCron.sh
	chmod u+x /var/lib/vtigercrm/cron/modules/com_vtiger_workflow/com_vtiger_workflow.sh

	#Setting up logrotate
        mv $archive/files/etc/logrotate.d/vtiger_cron /etc/logrotate.d/
        logrotate /etc/logrotate.conf
fi

# Deploy SQL Ledger
#
# Chart of Accounts:
#   Default
#   Australia_General_0000
#   Australia_General_00000
#   Austria
#   Bahasa-Indonesia_Default
#   Belgium
#   Brazil_General
#   Canada-English_General
#   Canada-French_General
#   Colombia-PUC
#   Colombia-utf8-PUC
#   Czech-Republic
#   Danish_Default
#   Dutch_Default
#   Dutch_Standard
#   Egypt-UTF8
#   Egypt_UTF8
#   Estonian_KA2
#   Estonian_UTF8
#   France
#   German-Sample
#   Germany-SKR03
#   Hungary
#   Italy_General
#   Italy_cc2424
#   Latvia
#   Norwegian_Default
#   Paraguay
#   Poland
#   Simplified-Chinese_Default-UTF8
#   Simplified-Chinese_Default
#   Slovak-Republic
#   Slovak-Republic-utf
#   Spain-ISO
#   Spain-UTF8
#   Sweden
#   Sweden_Agriculture
#   Sweden_Church_Society
#   Swiss-German
#   Traditional-Chinese_Default-UTF8
#   Traditional-Chinese_Default
#   UCOA-Form990
#   UCOA-Form990EZ
#   UK_General
#   US_General
#   US_Manufacturing
#   US_Service_Company
#   Venezuela_Default
# 
function CURL {
	if [ ! -e $COOKIE ]; then
		curl -c $COOKIE -d "$2" http://sql-ledger.$DOMAIN/$1
	else
		curl -b $COOKIE -c $COOKIE -d "$2" http://sql-ledger.$DOMAIN/$1
	fi
}

hasCapability SQLLedger
if [ $? -eq 0 ] ; then
	# Read parameters
	DB_PASSWORD_SQL_LEDGER=$(getPassword DB_PASSWORD_SQL_LEDGER)
	SQL_LEDGER_PASSWORD_ADMIN=$(getPassword SQL_LEDGER_PASSWORD_ADMIN)
	LDAP_PASSWORD_LIBNSS=$(getPassword LDAP_PASSWORD_LIBNSS)
	SQL_LEDGER_CHART_OF_ACCOUNTS_PARAMETER=$(getParameter sql_ledger_chart_of_accounts)

	# Check SQL-Ledger Chart of accounts
	SQL_LEDGER_CHART_OF_ACCOUNTS=
	for SL_CHART_OF_ACCOUNTS in "Default" "Australia_General_0000" "Australia_General_00000" "Austria" "Bahasa-Indonesia_Default" "Belgium" "Brazil_General" "Canada-English_General" "Canada-French_General" "Colombia-PUC" "Colombia-utf8-PUC" "Czech-Republic" "Danish_Default" "Dutch_Default" "Dutch_Standard" "Egypt-UTF8" "Egypt_UTF8" "Estonian_KA2" "Estonian_UTF8" "France" "German-Sample" "Germany-SKR03" "Hungary" "Italy_General" "Italy_cc2424" "Latvia" "Norwegian_Default" "Paraguay" "Poland" "Simplified-Chinese_Default-UTF8" "Simplified-Chinese_Default" "Slovak-Republic" "Slovak-Republic-utf" "Spain-ISO" "Spain-UTF8" "Sweden" "Sweden_Agriculture" "Sweden_Church_Society" "Swiss-German" "Traditional-Chinese_Default-UTF8" "Traditional-Chinese_Default" "UCOA-Form990" "UCOA-Form990EZ" "UK_General" "US_General" "US_Manufacturing" "US_Service_Company" "Venezuela_Default"; do
		if [ "$SQL_LEDGER_CHART_OF_ACCOUNTS_PARAMETER" = "$SL_CHART_OF_ACCOUNTS" ]; then
			SQL_LEDGER_CHART_OF_ACCOUNTS=$SQL_LEDGER_CHART_OF_ACCOUNTS_PARAMETER
			break
		fi
	done

	# If no SQL-Ledger Chart of account is defined use the Default
	if [ -z $SQL_LEDGER_CHART_OF_ACCOUNTS ]; then
		SQL_LEDGER_CHART_OF_ACCOUNTS="Default"

		if [ -z $SQL_LEDGER_CHART_OF_ACCOUNTS_PARAMETER ]; then
			echo "Warning: No SQL-Ledger Chart of account is defined"
		else
			echo "Warning: The SQL-Ledger Chart of account is non valid, reverting to Default"
		fi
	fi

	# Install packages
	aptGetInstall texlive-latex-extra

	cd /root
	tar -xzf $archive/sql-ledger/sql-ledger-3.0.4.tar.gz
	chown -R root:root sql-ledger
	mv sql-ledger /usr/share/

	cd /usr/share/sql-ledger
	mkdir /var/lib/sql-ledger
	mv users templates spool css /var/lib/sql-ledger/
	chown -R www-data:www-data /var/lib/sql-ledger/
	ln -s /var/lib/sql-ledger/users .
	ln -s /var/lib/sql-ledger/templates .
	ln -s /var/lib/sql-ledger/spool .
	ln -s /var/lib/sql-ledger/css .

	install -o root -g root -m 600 -t /usr/share/sql-ledger $archive/sql-ledger/sql-ledger.conf

	install -o root -g root -m 644 $template/etc/apache2/sites-available/sqlledger /etc/apache2/sites-available/sqlledger
	eseriReplaceValues /etc/apache2/sites-available/sqlledger
	sed -i -e "s|\[-IP_ADDRESS-\]|$IP_ADDRESS|" /etc/apache2/sites-available/sqlledger
	a2ensite sqlledger

	/etc/init.d/apache2 reload

	cd /root 
	COOKIE=$(mktemp)

	# login with admin password
echo " ============go to admin"
	curl http://sql-ledger.$DOMAIN/admin.pl

	D="new_password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&confirm_password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&path=bin%2Fmozilla"
        D+="&action=Continue"
        D+="&nextsub=do_change_password"
echo " ============give passwd and confirm ${SQL_LEDGER_PASSWORD_ADMIN} " 
	CURL admin.pl $D

	# Create DB: click 'add dataset'
        D="path=bin%2Fmozilla"
        D+="&dbdriver=Pg"
	D+="&action=Add%20Dataset"
echo " ============click add dataset"
	CURL admin.pl $D


	# enter password because we are outside the trusted domain
	D="password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&submit=Continue"
        D+="&action=add_dataset"
        D+="&admin=0"
	D+="&charset="
        D+="&dbdriver=Pg"
        D+="&dbversion=3.0.0"
        D+="&favicon=favicon.ico"
        D+="&path=bin%2Fmozilla"
	D+="&root%20login=1"
	D+="&stylesheet=sql-ledger.css"
	D+="&timeout=86400"
        D+="&version=3.0.4"
echo " ============enter password because we are outside the trusted domain"
        CURL admin.pl $D

	# give dbhost pgsql.${DOMAIN} and passwd ${DB_PASSWORD_SQL_LEDGER} 
	D="dbhost=pgsql.${DOMAIN}"
	D+="&dbport=5432"
	D+="&dbuser=sql-ledger"
	D+="&dbpasswd=${DB_PASSWORD_SQL_LEDGER}"
	D+="&dbdefault=template1"
	D+="&action=Continue"
	D+="&dbdriver=Pg"
	D+="&path=bin%2Fmozilla"
	D+="&nextsub=create_dataset"
        D+="&callback=admin.pl%3Faction%3Dlist_datasets%26path%3Dbin%2Fmozilla" 
echo " ============give dbhost pgsql.${DOMAIN} and passwd ${DB_PASSWORD_SQL_LEDGER} "
	CURL admin.pl "$D"

	# enter password again because we are outside the trusted domain
	D="password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&submit=Continue"

        D+="&action=continue"
        D+="&admin=0"
        D+="&callback=admin.pl%3Faction%3Dlist_datasets%26path%3Dbin%2Fmozilla" 
	D+="&charset="
	D+="&dbdefault=template1"
        D+="&dbdriver=Pg"
	D+="&dbhost=pgsql.${DOMAIN}"
	D+="&dbpasswd=${DB_PASSWORD_SQL_LEDGER}"
	D+="&dbport=5432"
	D+="&dbuser=sql-ledger"
        D+="&dbversion=3.0.0"
        D+="&favicon=favicon.ico"
	D+="&nextsub=create_dataset"
        D+="&path=bin%2Fmozilla"
	D+="&root%20login=1"
	D+="&stylesheet=sql-ledger.css"
	D+="&timeout=86400"
        D+="&version=3.0.4"
echo " ============enter password because we are outside the trusted domain"
        CURL admin.pl $D

	D="db=sql-ledger"
	D+="&company=${ORG_FULL_NAME}"
	D+="&mastertemplates=Default"
	D+="&encoding=UTF8"
	D+="&chart=${SQL_LEDGER_CHART_OF_ACCOUNTS}"
	D+="&action=Continue"
	D+="&dbdriver=Pg"
	D+="&dbuser=sql-ledger"
	D+="&dbhost=pgsql.${DOMAIN}"
	D+="&dbport=5432"
	D+="&dbpasswd=${DB_PASSWORD_SQL_LEDGER}"
	D+="&dbdefault=template1"
	D+="&path=bin%2Fmozilla"
	D+="&nextsub=dbcreate"
	D+="&callback=admin.pl%3Faction%3Dlist_datasets%26path%3Dbin%2Fmozilla"
echo " ============give ${ORG_FULL_NAME} ${SQL_LEDGER_CHART_OF_ACCOUNTS} continue "
	CURL admin.pl "$D"

	# enter password again because we are outside the trusted domain
	D="password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&submit=Continue"

        D+="&action=continue"
        D+="&admin=0"
        D+="&callback=admin.pl%3Faction%3Dlist_datasets%26path%3Dbin%2Fmozilla" 
	D+="&charset="
	D+="&chart=${SQL_LEDGER_CHART_OF_ACCOUNTS}"
	D+="&company=${ORG_FULL_NAME}"
	D+="&db=sql-ledger"
	D+="&dbdefault=template1"
        D+="&dbdriver=Pg"
	D+="&dbhost=pgsql.${DOMAIN}"
	D+="&dbpasswd=${DB_PASSWORD_SQL_LEDGER}"
	D+="&dbport=5432"
	D+="&dbuser=sql-ledger"
        D+="&dbversion=3.0.0"
	D+="&encoding=UTF8"
        D+="&favicon=favicon.ico"
	D+="&mastertemplates=Default"
	D+="&nextsub=dbcreate"
        D+="&path=bin%2Fmozilla"
	D+="&root%20login=1"
	D+="&stylesheet=sql-ledger.css"
	D+="&timeout=86400"
        D+="&version=3.0.4"
echo " ============enter password because we are outside the trusted domain or maybe because curl does not ident as FF"
        CURL admin.pl $D

echo " ============goto login page  "
	curl http://sql-ledger.$DOMAIN/login.pl
	D="login=admin"
        D+="&password=${SQL_LEDGER_PASSWORD_ADMIN}"
        D+="&action=Login"
        D+="&js="        
        D+="&path=bin%2Fmozilla"
echo " ============login to test "
        CURL login.pl $D

	# Clean up
	rm $COOKIE

	# Install eseriman script and files
	install -o root -g root -m 700 -t /var/lib/eseriman/bin $template/var/lib/eseriman/bin/sql-ledger-add-user

	sed -i -e "s/\[-DB_PASSWORD_SQL_LEDGER-\]/$DB_PASSWORD_SQL_LEDGER/" \
	  -e "s/\[-SQL_LEDGER_PASSWORD_ADMIN-\]/$SQL_LEDGER_PASSWORD_ADMIN/" \
	  -e "s/\[-ORG_FULL_NAME-\]/$ORG_FULL_NAME/" \
	  -e "s/\[-LDAP_PASSWORD_LIBNSS-\]/$LDAP_PASSWORD_LIBNSS/" \
	  /var/lib/eseriman/bin/sql-ledger-add-user
	install -o root -g root -m 700 -d /var/lib/eseriman/bin/awk
	install -o root -g root -m 600 -t /var/lib/eseriman/bin/awk $archive/sql-ledger/sql-ledger-members-read-password.awk
	install -o root -g root -m 600 -t /var/lib/eseriman/bin/awk $archive/sql-ledger/sql-ledger-members-set-password.awk
	install -o root -g root -m 600 -t /var/lib/eseriman/bin/awk $archive/sql-ledger/urlencode.awk 
fi

# Setup Cloud Manager
tar -C /var/www/ -zxf $ARCHIVE_FOLDER/cloudmanager/cloudmanager.tar.gz
install -o root -g root -m 644 $template/etc/apache2/sites-available/cloudmanager /etc/apache2/sites-available/cloudmanager
sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-REALM-\]/$REALM/;s/\[-IP_ADDRESS-\]/$IP_ADDRESS/" /etc/apache2/sites-available/cloudmanager
eseriReplaceValues /var/www/cloudmanager/enterpriselibre_cloudmanager.conf
echo " ============"
a2ensite cloudmanager

#Setup default site
install -o root -g root -m 644 $template/etc/apache2/sites-available/default /etc/apache2/sites-available/default
sed -i -e "s/\[-DOMAIN-\]/$DOMAIN/;s/\[-IP_ADDRESS-\]/$IP_ADDRESS/" /etc/apache2/sites-available/default
a2ensite default

/etc/init.d/apache2 restart

hasCapability Vtiger
if [ $? -eq 0 ] ; then
    # Eseriman C3 scripts
    install -o root -g root -m 500 $TEMPLATE_FOLDER/var/lib/eseriman/bin/createVtigerIMAPPassword.sh $ESERIMAN_HOME/bin/
    sed -i -e "s|\[-DB_PASSWORD_VTIGER-\]|$DB_PASSWORD_VTIGER|g" $ESERIMAN_HOME/bin/createVtigerIMAPPassword.sh
    chmod u+s $ESERIMAN_HOME/bin/createVtigerIMAPPassword.sh	

    install -o root -g root -m 500 $TEMPLATE_FOLDER/var/lib/eseriman/bin/changeVtigerIMAPPassword.sh $ESERIMAN_HOME/bin/
    sed -i -e "s|\[-DB_PASSWORD_VTIGER-\]|$DB_PASSWORD_VTIGER|g" $ESERIMAN_HOME/bin/changeVtigerIMAPPassword.sh
    chmod u+s $ESERIMAN_HOME/bin/changeVtigerIMAPPassword.sh	
    
    chown root:root $ESERIMAN_HOME/bin/*.sh
    chmod 0500 $ESERIMAN_HOME/bin/*.sh
    chmod u+s $ESERIMAN_HOME/bin/*.sh
    install -o eseriman -g eseriman -m 700 -d $ESERIMAN_HOME/.ssh
    install -o eseriman -g eseriman -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys.c3 $ESERIMAN_HOME/.ssh/authorized_keys
    
    # Modify sudoers file
    cat >>/etc/sudoers <<EOF

# Eseri specific settings
Cmnd_Alias ESERIMAN = /etc/init.d/apache2, /usr/sbin/a2ensite, /usr/sbin/a2dissite, /var/lib/eseriman/bin/changeVtigerIMAPPassword.sh, /var/lib/eseriman/bin/createVtigerIMAPPassword.sh, /var/lib/eseriman/bin/sql-ledger-add-user
eseriman ALL=NOPASSWD: ESERIMAN
EOF

fi

exit 0
