#!/bin/bash
#
# User timezone deploy script - v1.7
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
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

# Mark start point in log file.
echo "$(date) Change User Timezone"

# Get the system parameters.
eseriGetDNS
eseriGetNetwork

NEW_TIMEZONES=$(getParameter new_timezone)
USERNAMES=$(getParameter username)
DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)

# Tokenize usernames, old_emails and new_emails variables
NEW_TIMEZONES=( $NEW_TIMEZONES )
USERNAMES=( $USERNAMES )

for (( i=0; i<${#USERNAMES[@]}; i++ )); do
    NEW_TIMEZONE=${NEW_TIMEZONES[$i]}
    USERNAME=${USERNAMES[$i]}
    echo "$USERNAME $NEW_TIMEZONE"


    # Check timezone information.
    if [ ! -f /usr/share/zoneinfo/$NEW_TIMEZONE ]; then
	echo "The system doesn't know the specified timezone: '$NEW_TIMEZONE'. Exiting"
	exit 1
    fi

    ###################
    ##### Desktop #####
    ###################
    hasCapability Desktop
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'chaos' ]; then
	    sed -i '/export TZ=/d' /home/$USERNAME/.profile
	    echo "export TZ='$NEW_TIMEZONE'" >> /home/$USERNAME/.profile
	fi
    fi

    #################
    ##### Email #####
    #################
    hasCapability Email
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'chaos' ]; then
	    # Kill Evolution
	    evolution_pid=$(ps -C evolution -o pid= -o ruser= | grep $USERNAME | sed "s/ $USERNAME//")
	    if [[ $evolution_pid -ne '' ]]; then
		kill -9 $evolution_pid
	    fi
	    # Kill Gconfd
	    gconfd_pid=$(ps -C gconfd-2 -o pid= -o ruser= | grep $USERNAME | sed "s/ $USERNAME//")
	    if [[ $gconfd_pid -ne '' ]]; then
		kill -9 $gconfd_pid
	    fi
	    
	    # Set Gconf values for calendar
	    su - -c "gconftool-2 --set /apps/evolution/calendar/display/timezone --type=string '$NEW_TIMEZONE'" $USERNAME
	    su - -c "gconftool-2 --set /apps/evolution/calendar/display/use_system_timezone --type=bool 'False'" $USERNAME
	fi
    fi

    ################
    ##### Wiki #####
    ################
    hasCapability Wiki
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    DATE=$(TZ="$NEW_TIMEZONE" date +%s -d "$(date +'%F %R:%S')")
	    DATE_UTC=$(TZ="UTC" date +%s -d "$(date +'%F %R:%S')")
	    OFFSET=$(( ($DATE_UTC - $DATE) / 60 ))
	    
	    OPTIONS=$(su - -c "psql -d wikidb <<EOF
SELECT user_options FROM mediawiki.mwuser WHERE LOWER(user_name) = '$USERNAME';
EOF" postgres | awk 'NR>2' | awk '{$1=$1}1' | head -n -2 | sed "s|timecorrection=.*|timecorrection=ZoneInfo\|$OFFSET\|$NEW_TIMEZONE|")
	    
	    echo "$OPTIONS" | grep 'timecorrection='
            if [ $? -ne 0 ]; then
		OPTIONS=$(echo -e "$OPTIONS\ntimecorrection=ZoneInfo|$OFFSET|$NEW_TIMEZONE")
            fi
	    
	    su - -c "psql -d wikidb <<EOF
UPDATE mediawiki.mwuser set user_options = '$OPTIONS' WHERE LOWER(user_name) = '$USERNAME';
EOF" postgres
	fi
    fi

    #################
    ##### Nuxeo #####
    #################
    hasCapability Nuxeo
    # Only server timezone available
    # No user configuration here.
    
    ##################
    ##### Vtiger #####
    ##################
    hasCapability Vtiger
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE vtiger_users SET time_zone = '$NEW_TIMEZONE' WHERE user_name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	fi
	if [ $SHORT_NAME == 'poseidon' ]; then
	    FILE=$(grep -l "'user_name'=>'$USERNAME'" /var/lib/vtigercrm/user_privileges/*)
	    sed -i "s|'time_zone'=>'\([^']*\)'|'time_zone'=>'$NEW_TIMEZONE'|" $FILE
	fi     
    fi
    
    #####################
    ##### Timesheet #####
    #####################
    hasCapability Timesheet
    # Only server timezone available
    # No user configuration here.
    
    ################
    ##### SOGo #####
    ################
    hasCapability SOGo
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    DEFAULTS=$(su - -c "psql -d sogo <<EOF
SELECT c_defaults FROM sogo_user_profile WHERE c_uid = '$USERNAME';
EOF" postgres | awk 'NR==3' | sed "/SOGoTimeZone/s|\"SOGoTimeZone\": \"\([^\"]*\)\",|\"SOGoTimeZone\": \"$NEW_TIMEZONE\",|")
	    su - -c "psql -d sogo <<EOF
UPDATE sogo_user_profile SET c_defaults = '$DEFAULTS' WHERE c_uid = '$USERNAME';
EOF" postgres
	fi
    fi
    
    #####################
    ##### OrangeHRM #####
    #####################
    hasCapability OrangeHRM
    # No user configuration here.
    
    ################
    ##### Trac #####
    ################
    hasCapability Trac
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    USER_TZ_SET=$(su - -c "psql -d trac <<EOF
SELECT COUNT(*) FROM session_attribute WHERE sid = '$USERNAME' AND name = 'tz';
EOF" postgres | awk 'NR==3' | sed 's| ||g')
	    
	    OFFSET=$(TZ="$NEW_TIMEZONE" date +%:z | sed 's|0\([1-9]\)|\1|')
	    if [[ "$OFFSET" == "+00:00" ]]; then
		NEW_TZ="GMT"
	    else
		NEW_TZ="GMT $OFFSET"
	    fi
	    
	    if [[ "$USER_TZ_SET" == "1" ]]; then
		su - -c "psql -d trac <<EOF
UPDATE session_attribute SET value = '$NEW_TZ' WHERE sid = '$USERNAME' AND name = 'tz';
EOF" postgres
	    else
		su - -c "psql -d trac <<EOF
INSERT INTO session_attribute (sid, authenticated, name, value) VALUES ('$USERNAME', 1, 'tz', '$NEW_TZ');
EOF" postgres
	    fi
	fi
    fi
    
    ########################
    ##### MailingLists #####
    ########################
    hasCapability MailingLists
    # No user configuration here.
    
    #####################
    ##### SQLLedger #####
    #####################
    hasCapability SQLLedger
    # No user configuration here.
    
    ###################
    ##### Redmine #####
    ###################
    hasCapability Redmine
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    su - -c "psql -d redmine <<EOF
UPDATE user_preferences SET time_zone='$NEW_TIMEZONE' WHERE user_id = (SELECT id FROM users WHERE login = '$USERNAME');
EOF" postgres
	fi
    fi
    
    #########################
    ##### PHPScheduleIt #####
    #########################
    hasCapability PHPScheduleIt
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE users SET timezone = '$NEW_TIMEZONE' WHERE username = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL phpscheduleit
	fi
    fi
    
    ##################
    ##### Drupal #####
    ##################
    hasCapability Drupal
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE drupal_users SET timezone = '$NEW_TIMEZONE' WHERE name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	fi
    fi
    
    ###################
    ##### CiviCRM #####
    ###################
    hasCapability CiviCRM
    # Configuration done in Drupal.
    # No special user configuration here.
    
    ######################
    ##### ChurchInfo #####
    ######################
    hasCapability ChurchInfo
    # No user configuration here.
    
    ##################
    ##### Moodle #####
    ##################
    hasCapability Moodle
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    DATE=$(TZ="$NEW_TIMEZONE" date +%s -d "$(date +'%F %R:%S')")
	    DATE_UTC=$(TZ="UTC" date +%s -d "$(date +'%F %R:%S')")
	    OFFSET=$(awk 'BEGIN{printf "%.1f", ('$DATE_UTC'-'$DATE') /'3600'}')
	    su - -c "psql -d moodle <<EOF
UPDATE mdl_user SET timezone='$OFFSET' WHERE username = '$USERNAME';
EOF" postgres
	fi
    fi
    
    ###################
    ##### OpenERP #####
    ###################
    hasCapability OpenERP
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    su - -c "psql -d openerp <<EOF
UPDATE res_partner SET tz='$NEW_TIMEZONE' WHERE id = (SELECT partner_id FROM res_users WHERE login = '$USERNAME');
EOF" postgres
	fi
    fi
    
done

exit 0
