#!/bin/bash
#
# Server timezone deploy script - v1.5
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file.
echo "$(date) Change Server Timezone"

# Get the system parameters.
eseriGetDNS
eseriGetNetwork

NEW_TIMEZONE=$(getParameter new_timezone)
DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)

# Check timezone information.
if [ ! -f /usr/share/zoneinfo/$NEW_TIMEZONE ]; then
    echo "The system doesn't know the specified timezone: '$NEW_TIMEZONE'. Exiting"
    exit 1
fi

# Reconfigure timezone.
rm /etc/localtime
ln -s /usr/share/zoneinfo/$NEW_TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

################
##### Wiki #####
################
hasCapability Wiki
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'poseidon' ]; then
	# sed -i 's|$wgLocaltimezone = "$OLD_TIMEZONE";|$wgLocaltimezone = "$NEW_TIMEZONE";|g' /etc/mediawiki/LocalSettings.php
	# Better alternate.
	sed -i "/^\$wgLocaltimezone = /s|\"\([^\"]*\)\"|\"$NEW_TIMEZONE\"|" /etc/mediawiki/LocalSettings.php
	/etc/init.d/apache2 restart
    fi
fi

#################
##### Nuxeo #####
#################
hasCapability Nuxeo
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'cronus' ]; then
	# sed -i 's|user.timezone=$OLD_TIMEZONE "|user.timezone=$NEW_TIMEZONE "|g' /etc/init.d/nuxeo
	# Better alternate.
	sed -i "s|user.timezone=\([^ ]*\) |user.timezone=$NEW_TIMEZONE |" /etc/init.d/nuxeo
	/etc/init.d/nuxeo restart > /dev/null
	wait
    fi
fi

##################
##### Vtiger #####
##################
hasCapability Vtiger
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'poseidon' ]; then
	# Vtiger server timezone should be set to UTC becase vtiger 5.4.0 introduced user timezones.
	# For new users.
	# sed -i 's|$OLD_TIMEZONE|$NEW_TIMEZONE|g' /var/lib/vtigercrm/modules/Users/Users.php
	# Better alternate.
	sed -i "/time_zone/s|\"\([^\"]*\)\";|\"$NEW_TIMEZONE\";|" /var/lib/vtigercrm/modules/Users/Users.php
	/etc/init.d/apache2 restart
    fi
fi

#####################
##### Timesheet #####
#####################
hasCapability Timesheet
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'hades' ]; then
	echo "UPDATE timesheet_config SET timezone = '$NEW_TIMEZONE' WHERE LDAPBaseDN='ou=people,$LDAP_BASE';" | mysql -uroot -p$DB_PASSWORD_MYSQL timesheet
    fi
fi

################
##### SOGo #####
################
hasCapability SOGo
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'gaia' ]; then
	# sed -i 's|<string>$OLD_TIMEZONE</string>|<string>$NEW_TIMEZONE</string>|g' /home/sogo/GNUstep/Defaults/.GNUstepDefaults
	# Better alternate.
	sed -i '/<key>SOGoTimeZone<\/key>/!b;n;/<string>/s|<string>\([^<]*\)</string>|<string>$NEW_TIMEZONE</string>|' /home/sogo/GNUstep/Defaults/.GNUstepDefaults
	sed -i "s|\$NEW_TIMEZONE|$NEW_TIMEZONE|" /home/sogo/GNUstep/Defaults/.GNUstepDefaults
	/etc/init.d/sogo restart
	/etc/init.d/apache2 restart
    fi
fi

#####################
##### OrangeHRM #####
#####################
hasCapability OrangeHRM
# No server configuration here.

################
##### Trac #####
################
hasCapability Trac
# Timezone for new users is set to default server timezone.
# No server configuration here.

########################
##### MailingLists #####
########################
hasCapability MailingLists
# No server configuration here.

#####################
##### SQLLedger #####
#####################
hasCapability SQLLedger
# No server configuration here.

###################
##### Redmine #####
###################
hasCapability Redmine
# Timezone for new users is set to the timezone in /etc/timezone.
# No server configuration here.

#########################
##### PHPScheduleIt #####
#########################
hasCapability PHPScheduleIt
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'trident' ]; then
	# Timezone for new users is set to the timezone in /etc/timezone.
	# sed -i "s|$conf\['settings'\]\['server.timezone'\] = '$OLD_TIMEZONE';|$conf\['settings'\]\['server.timezone'\] = '$NEW_TIMEZONE';|g;" /var/lib/phpscheduleit/config/config.php
	# Better alternate.
	sed -i "/server.timezone/s|'\([^']*\)';|'$NEW_TIMEZONE';|g" /var/lib/phpscheduleit/config/config.php
        /etc/init.d/apache2 restart
    fi
fi

##################
##### Drupal #####
##################
hasCapability Drupal
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'hades' ]; then
	# Timezone for new users is set to the timezone in /etc/timezone.
	SIZE=${#NEW_TIMEZONE}
	echo "UPDATE drupal_variable SET value = 's:$SIZE:\"$NEW_TIMEZONE\";' WHERE name = 'date_default_timezone';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	DOMAIN_IDS=$(echo "SELECT domain_id FROM drupal_domain_conf;" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | awk 'NR>1')
	for i in ${DOMAIN_IDS[*]}; do
	    SETTINGS=$(echo "SELECT settings FROM drupal_domain_conf WHERE domain_id = $i;" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | awk 'NR==2' | sed "s|s:21:\"date_default_timezone\";s:[0-9]*:\"\([^\"]*\)\";|s:21:\"date_default_timezone\";s:$SIZE:\"$NEW_TIMEZONE\";|g")
	    echo "UPDATE drupal_domain_conf SET settings = '$SETTINGS' WHERE domain_id = $i;" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	done
    fi
fi

###################
##### CiviCRM #####
###################
hasCapability CiviCRM
# Configuration done in Drupal.
# No special server configuration here.

######################
##### ChurchInfo #####
######################
hasCapability ChurchInfo
if [ $? -eq 0 ]; then
    if [ $SHORT_NAME == 'hades' ]; then
	echo "UPDATE config_cfg SET cfg_value = '$NEW_TIMEZONE', cfg_default = '$NEW_TIMEZONE' WHERE cfg_name = 'sTimeZone'"  | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo
    fi
fi

##################
##### Moodle #####
##################
hasCapability Moodle
# Moodle users have user timezone which is set to 99 (default server timezone).
# Moodle servers default timezone is also set to 99 (default server timezone)
# No server configuration here.

###################
##### OpenERP #####
###################
hasCapability OpenERP
# Timezone for new users is set to the timezone in /etc/timezone.
# No server configuration here.

exit 0
