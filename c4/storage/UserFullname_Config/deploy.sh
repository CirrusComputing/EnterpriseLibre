#!/bin/bash
#
# User fullname config script - v1.0
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
echo "$(date) Change User Fullname"

# Get the system parameters.
eseriGetDNS
eseriGetNetwork

USERNAMES=$(getParameter username)
OLD_FIRSTNAMES=$(getParameter old_firstname)
OLD_LASTNAMES=$(getParameter old_lastname)
NEW_FIRSTNAMES=$(getParameter new_firstname)
NEW_LASTNAMES=$(getParameter new_lastname)
DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)

# Tokenize usernames, firstnames and lastnames variables
USERNAMES=( $USERNAMES )
OLD_FIRSTNAMES=( $OLD_FIRSTNAMES )
OLD_LASTNAMES=( $OLD_LASTNAMES )
NEW_FIRSTNAMES=( $NEW_FIRSTNAMES )
NEW_LASTNAMES=( $NEW_LASTNAMES )

for (( i=0; i<${#USERNAMES[@]}; i++ )); do
    USERNAME=${USERNAMES[$i]}
    OLD_FIRSTNAME=${OLD_FIRSTNAMES[$i]}
    OLD_LASTNAME=${OLD_LASTNAMES[$i]}
    NEW_FIRSTNAME=${NEW_FIRSTNAMES[$i]}
    NEW_LASTNAME=${NEW_LASTNAMES[$i]}
    echo "$USERNAME | $OLD_FIRSTNAME $OLD_LASTNAME | $NEW_FIRSTNAME $NEW_LASTNAME"

    # Change name attributes in LDAP
    if [ $SHORT_NAME == 'chaos' ]; then
	su - -c "./bin/eseriChangeUserFullnameLDAP '$USERNAME' '$NEW_FIRSTNAME' '$NEW_LASTNAME'" eseriman
    fi

    # Capabilities

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
	    
	    XML_FILE=/home/$USERNAME/userfullname_config.xml
	    su - -c "gconftool-2 --dump /apps/evolution/mail > $XML_FILE" $USERNAME
	    sed -i "s|$OLD_FIRSTNAME $OLD_LASTNAME|$NEW_FIRSTNAME $NEW_LASTNAME|g" $XML_FILE
	    su - -c "gconftool-2 --load $XML_FILE" $USERNAME
	    rm $XML_FILE
	fi
    fi

    ################
    ##### Wiki #####
    ################
    hasCapability Wiki
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    su - -c "psql -d wikidb <<EOF
UPDATE mediawiki.mwuser SET user_real_name = '$NEW_FIRSTNAME $NEW_LASTNAME' WHERE LOWER(user_name) = '$USERNAME';
EOF" postgres
	    OPTIONS=$(su - -c "psql -d wikidb <<EOF
SELECT user_options FROM mediawiki.mwuser WHERE LOWER(user_name) = '$USERNAME';
EOF" postgres | awk 'NR>2' | awk '{$1=$1}1' | head -n -2 | sed "s|\(nickname=.*\)$OLD_FIRSTNAME $OLD_LASTNAME\(.*\)|\1$NEW_FIRSTNAME $NEW_LASTNAME\2|")
	su - -c "psql -d wikidb <<EOF
UPDATE mediawiki.mwuser SET user_options = '$OPTIONS' WHERE LOWER(user_name) = '$USERNAME';
EOF" postgres
	fi
    fi

    #################
    ##### Nuxeo #####
    #################
    hasCapability Nuxeo
    # No change

    ##################
    ##### Vtiger #####
    ##################
    hasCapability Vtiger
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE vtiger_users SET first_name = '$NEW_FIRSTNAME', last_name = '$NEW_LASTNAME' WHERE user_name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	fi
    fi

    #####################
    ##### Timesheet #####
    #####################
    hasCapability Timesheet
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE timesheet_user SET first_name = '$NEW_FIRSTNAME', last_name = '$NEW_LASTNAME' WHERE username = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL timesheet
	fi
    fi

    ###################
    ##### WebMail #####
    ###################
    hasCapability WebMail
    # No change

    #####################
    ##### OrangeHRM #####
    #####################
    hasCapability OrangeHRM
    # No change

    ################
    ##### Trac #####
    ################
    hasCapability Trac
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
            su - -c "psql -d trac <<EOF
UPDATE session_attribute SET value = '$NEW_FIRSTNAME $NEW_LASTNAME' WHERE sid = '$USERNAME' AND name = 'name';
EOF" postgres	
	fi
    fi

    ########################
    ##### MailingLists #####
    ########################
    hasCapability MailingLists
    # No change

    #####################
    ##### SQLLedger #####
    #####################
    hasCapability SQLLedger
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
            su - -c "psql -d sql-ledger <<EOF
UPDATE employee SET name = '$NEW_FIRSTNAME $NEW_LASTNAME' WHERE login = '$USERNAME';
EOF" postgres		
	fi
    fi

    ###################
    ##### Redmine #####
    ###################
    hasCapability Redmine
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
            su - -c "psql -d redmine <<EOF
UPDATE users SET firstname = '$NEW_FIRSTNAME', lastname = '$NEW_LASTNAME' WHERE login = '$USERNAME';
EOF" postgres			
	fi
    fi

    #########################
    ##### PHPScheduleIt #####
    #########################
    hasCapability PHPScheduleIt
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE users SET fname = '$NEW_FIRSTNAME', lname = '$NEW_LASTNAME' WHERE username = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL phpscheduleit
	fi
    fi

    ##################
    ##### Drupal #####
    ##################
    hasCapability Drupal
    # No change

    ###################
    ##### CiviCRM #####
    ###################
    hasCapability CiviCRM
    # No change

    ######################
    ##### ChurchInfo #####
    ######################
    hasCapability ChurchInfo
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE person_per SET per_FirstName = '$NEW_FIRSTNAME', per_LastName = '$NEW_LASTNAME' WHERE per_ID = (SELECT usr_per_ID FROM user_usr WHERE usr_UserName = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo
	    echo "UPDATE userconfig_ucfg SET ucfg_value = '$NEW_FIRSTNAME $NEW_LASTNAME' WHERE ucfg_name = 'sFromName' AND ucfg_per_id = (SELECT usr_per_ID FROM user_usr WHERE usr_UserName = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo
	fi
    fi

    ##################
    ##### Moodle #####
    ##################
    hasCapability Moodle
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    su - -c "psql -d moodle <<EOF
UPDATE mdl_user SET firstname = '$NEW_FIRSTNAME', lastname = '$NEW_LASTNAME' WHERE username = '$USERNAME';
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
UPDATE res_partner SET name='$NEW_FIRSTNAME $NEW_LASTNAME' WHERE id = (SELECT partner_id FROM res_users WHERE login = '$USERNAME');
EOF" postgres
	    SIGNATURE=$(su - -c "psql -d openerp <<EOF
SELECT signature FROM res_users WHERE login = '$USERNAME';
EOF" postgres | awk 'NR>2' | awk '{$1=$1}1' | head -n -2 | sed "s|$OLD_FIRSTNAME $OLD_LASTNAME|$NEW_FIRSTNAME $NEW_LASTNAME|")
	su - -c "psql -d openerp <<EOF
UPDATE res_users SET signature = '$SIGNATURE' WHERE login = '$USERNAME';
EOF" postgres
	fi
    fi
done

exit 0
