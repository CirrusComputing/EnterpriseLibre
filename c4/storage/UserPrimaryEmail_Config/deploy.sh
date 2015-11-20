#!/bin/bash
#
# User primary email config script - v1.4
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
echo "$(date) Change User Email"

# Get the system parameters.
eseriGetDNS
eseriGetNetwork

USERNAMES=$(getParameter username)
OLD_EMAILS=$(getParameter old_email)
NEW_EMAILS=$(getParameter new_email)
DOMAIN_CONFIG_VERSION=$(getParameter domain_config_version)
DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)

# Tokenize usernames, old_emails and new_emails variables
USERNAMES=( $USERNAMES )
OLD_EMAILS=( $OLD_EMAILS )
NEW_EMAILS=( $NEW_EMAILS )

for (( i=0; i<${#USERNAMES[@]}; i++ )); do
    USERNAME=${USERNAMES[$i]}
    OLD_EMAIL=${OLD_EMAILS[$i]}
    NEW_EMAIL=${NEW_EMAILS[$i]}
    echo "$USERNAME $OLD_EMAIL $NEW_EMAIL"

    # Change email attribute in LDAP
    if [ $SHORT_NAME == 'chaos' ]; then
	su - -c "./bin/eseriChangeUserPrimaryEmailLDAP '$USERNAME' '$NEW_EMAIL'" eseriman
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
	    

            # User home directory
	    USER_HOME=/home/$USERNAME

	    XML_FILE=$USER_HOME/userprimaryemail_config.xml
	    su - -c "gconftool-2 --dump /apps/evolution/mail > $XML_FILE" $USERNAME
	    sed -i "s|$OLD_EMAIL|$NEW_EMAIL|g" $XML_FILE

	    # Do extra config for domain config version 2.12
	    if [ $DOMAIN_CONFIG_VERSION == '2.12' ]; then
		# Replace OLD_EMAIL_PREFIX%40CLOUD_DOMAIN with NEW_EMAIL_PREFIX%40CLOUD_DOMAIN
		# Gconf dump file
		# Passwordless keyring file
		# Evolution expand INBOX on Evolution start file
		sed -i -e "s|$(echo $OLD_EMAIL | sed 's|@|%40|')|$(echo $NEW_EMAIL | sed 's|@|%40|')|g" -e "s|$OLD_EMAIL|$NEW_EMAIL|g" $XML_FILE $USER_HOME/.gnome2/keyrings/default.keyring $USER_HOME/.evolution/mail/config/folder-tree-expand-state.xml
	    fi


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
UPDATE mediawiki.mwuser set user_email = '$NEW_EMAIL' WHERE LOWER(user_name) = '$USERNAME';
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
	    echo "UPDATE vtiger_users SET email1 = '$NEW_EMAIL' WHERE user_name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	    echo "UPDATE vtiger_mail_accounts SET mail_id = '$NEW_EMAIL' WHERE user_id = (SELECT id FROM vtiger_users WHERE user_name = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	    # Do extra config for domain config version 2.12
	    if [ $DOMAIN_CONFIG_VERSION == '2.12' ]; then
		echo "UPDATE vtiger_mail_accounts SET mail_username = '$NEW_EMAIL' WHERE mail_username = '$OLD_EMAIL' AND user_id = (SELECT id FROM vtiger_users WHERE user_name = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	    fi
	fi
    fi

    #####################
    ##### Timesheet #####
    #####################
    hasCapability Timesheet
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE timesheet_user SET email_address = '$NEW_EMAIL' WHERE username = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL timesheet
	fi
    fi

    ################
    ##### SOGo #####
    ################
    hasCapability SOGo
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
UPDATE session_attribute SET value = '$NEW_EMAIL' WHERE sid = '$USERNAME' AND name = 'email';
EOF" postgres	
	fi
    fi

    ########################
    ##### MailingLists #####
    ########################
    hasCapability MailingLists
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hera' ]; then
	    /usr/lib/mailman/bin/clone_member --admin --remove --quiet $OLD_EMAIL $NEW_EMAIL
	fi
    fi

    #####################
    ##### SQLLedger #####
    #####################
    hasCapability SQLLedger
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
            su - -c "psql -d sql-ledger <<EOF
UPDATE employee SET email = '$NEW_EMAIL' WHERE login = '$USERNAME';
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
UPDATE users SET mail = '$NEW_EMAIL' WHERE login = '$USERNAME';
EOF" postgres			
	fi
    fi

    #########################
    ##### PHPScheduleIt #####
    #########################
    hasCapability PHPScheduleIt
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE users SET email = '$NEW_EMAIL' WHERE username = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL phpscheduleit
	fi
    fi

    ##################
    ##### Drupal #####
    ##################
    hasCapability Drupal
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE drupal_users SET mail = '$NEW_EMAIL' and init = '$NEW_EMAIL' WHERE name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	fi
    fi

    ###################
    ##### CiviCRM #####
    ###################
    hasCapability CiviCRM
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    DRUPAL_UID=$(echo "SELECT uid from drupal_users WHERE name = '$USERNAME';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | tail -n 1)
	    echo "UPDATE civicrm_uf_match SET uf_name = '$NEW_EMAIL' WHERE uf_id = '$DRUPAL_UID';" | mysql -uroot -p$DB_PASSWORD_MYSQL civicrm
	    echo "UPDATE civicrm_contact SET sort_name = '$NEW_EMAIL' WHERE sort_name = '$OLD_EMAIL' AND id = (SELECT contact_id FROM civicrm_uf_match WHERE uf_id = '$DRUPAL_UID');" | mysql -uroot -p$DB_PASSWORD_MYSQL civicrm
	    echo "UPDATE civicrm_contact SET display_name = '$NEW_EMAIL' WHERE display_name = '$OLD_EMAIL' AND id = (SELECT contact_id FROM civicrm_uf_match WHERE uf_id = '$DRUPAL_UID');" | mysql -uroot -p$DB_PASSWORD_MYSQL civicrm
	    echo "UPDATE civicrm_email SET email = '$NEW_EMAIL' WHERE email = '$OLD_EMAIL' AND id = (SELECT contact_id FROM civicrm_uf_match WHERE uf_id = '$DRUPAL_UID');" | mysql -uroot -p$DB_PASSWORD_MYSQL civicrm
	fi
    fi

    ######################
    ##### ChurchInfo #####
    ######################
    hasCapability ChurchInfo
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    echo "UPDATE person_per SET per_Email = '$NEW_EMAIL' WHERE per_ID = (SELECT usr_per_ID FROM user_usr WHERE usr_UserName = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo
	    echo "UPDATE userconfig_ucfg SET ucfg_value = '$NEW_EMAIL' WHERE ucfg_name = 'sFromEmailAddress' AND ucfg_per_id = (SELECT usr_per_ID FROM user_usr WHERE usr_UserName = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo
	fi
    fi

    ##################
    ##### Moodle #####
    ##################
    hasCapability Moodle
    if [ $? -eq 0 ]; then
	if [ $SHORT_NAME == 'hades' ]; then
	    su - -c "psql -d moodle <<EOF
UPDATE mdl_user SET email='$NEW_EMAIL' WHERE username = '$USERNAME';
EOF" postgres
	    su - -c "psql -d moodle <<EOF
UPDATE mdl_config SET value='$NEW_EMAIL' WHERE value = '$OLD_EMAIL' and name = 'supportemail';
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
UPDATE res_partner SET email='$NEW_EMAIL' WHERE id = (SELECT partner_id FROM res_users WHERE login = '$USERNAME');
EOF" postgres	
	fi
    fi
done

exit 0
