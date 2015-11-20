#!/bin/bash
#
# Moodle deploy script - v2.2
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

# Mark start point in log file
echo "$(date) Deploy Moodle"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    dns_add_cname 'moodle' 'trident' 'internal'
fi

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    apache2_site_config 'moodle-proxy' 'moodle' 'null' 'null'
fi

#####################
##### APHRODITE #####
#####################
if [ $SHORT_NAME == 'aphrodite' ]; then
    ldap_ldif_config 'moodle'
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    MOODLE_VERSION=2.6.0
    DB_PASSWORD_MOODLE=$(getPassword DB_PASSWORD_MOODLE)
    ALIAS_DOMAIN=$(getParameter alias_domain)
    MOODLE_BASE_FOLDER=/var/lib
    MOODLE_INSTALLATION_FOLDER=$MOODLE_BASE_FOLDER/moodle
    MOODLE_DATA_FOLDER=$MOODLE_BASE_FOLDER/moodledata
    SUDOERS_FILE=/etc/sudoers

    tar -C $MOODLE_BASE_FOLDER -zxf $ARCHIVE_FOLDER/moodle/moodle-$MOODLE_VERSION.tar.gz
    chown -R www-data:www-data $MOODLE_INSTALLATION_FOLDER

    # Require packages
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y -q php5-curl php5-xmlrpc php5-intl >/dev/null

    # Moodle Configuration
    # Added extra config so that moodle doesn't show update notifications
    install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/$MOODLE_INSTALLATION_FOLDER/config.php $MOODLE_INSTALLATION_FOLDER
    sed -i -e "s|\[-DB_PASSWORD_MOODLE-\]|$DB_PASSWORD_MOODLE|g" $MOODLE_INSTALLATION_FOLDER/config.php
    eseriReplaceValues $MOODLE_INSTALLATION_FOLDER/config.php

    # Moodle Data Dir Configuration
    install -o www-data -g www-data -m 777 -d $MOODLE_DATA_FOLDER

    # Apache2 Configuration
    apache2_site_config 'moodle' 'moodle' 'enable' 't'

    # Eseriman C3 Configuration
    deploy_eseriman_script 'createMoodleUser.sh'
    sed -i -e "s|\[-DB_PASSWORD_MOODLE-\]|$DB_PASSWORD_MOODLE|g" /var/lib/eseriman/bin/createMoodleUser.sh

    # Modify sudoers file
    sed -i '/^Cmnd_Alias ESERIMAN.*/ {s||\0, /var/lib/eseriman/bin/createMoodleUser.sh|g;} ' $SUDOERS_FILE

    # Cron Configuration
    crontab -u www-data -l > /tmp/ct.tmp
    echo "*/15 * * * * /usr/bin/php  $MOODLE_INSTALLATION_FOLDER/admin/cli/cron.php >/dev/null" >> /tmp/ct.tmp
    cat /tmp/ct.tmp | crontab -u www-data -
    rm /tmp/ct.tmp

    # Configure Existing users
    configure_existing_users "createMoodleUser.sh" "USERNAME EMAIL_PREFIX FIRSTNAME LASTNAME CLOUD_DOMAIN TIMEZONE"
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    MOODLE_VERSION=2.6.0
    DB_PASSWORD_MOODLE=$(getPassword DB_PASSWORD_MOODLE)
    LDAP_PASSWORD_MOODLE=$(getPassword LDAP_PASSWORD_MOODLE)
    IT_MAN_USER=$(getParameter manager_username)
    SHORT_DOMAIN=$(getParameter short_domain)
    su - -c "psql -c \"CREATE ROLE moodle PASSWORD '$DB_PASSWORD_MOODLE' INHERIT LOGIN;\"" postgres
    su - -c "createdb moodle -O moodle --template=template0 --encoding utf-8" postgres
    #Configured moodle database with the following in table mdl_config (id, name, value)
    #(169,forcelogin,1),(141,guestloginbutton,0),(139,authpreventaccountcreatin,1),(3,auth,ldap),(19,siteadmins,2)
    eseriReplaceValues $TEMPLATE_FOLDER/transient/moodle-$MOODLE_VERSION.template
    cat $TEMPLATE_FOLDER/transient/moodle-$MOODLE_VERSION.template | sed -e "s|\[-SHORT_DOMAIN-\]|$SHORT_DOMAIN|g;s|\[-IT_MAN_USER-\]|$IT_MAN_USER|g;s|\[-LDAP_PASSWORD_MOODLE-\]|$LDAP_PASSWORD_MOODLE|g;" > /var/lib/postgresql/moodle-$MOODLE_VERSION.template
    chmod a+rx /var/lib/postgresql/moodle-$MOODLE_VERSION.template
    su -l -c "psql -d moodle -f moodle-$MOODLE_VERSION.template > /dev/null 2>&1" postgres
    rm /var/lib/postgresql/moodle-$MOODLE_VERSION.template
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    deploy_start_menu_items 'education' 'moodle'
fi

exit 0
