#!/bin/bash
#
# Drupal deploy script - v2.2
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
#1;2305;0c Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy Drupal"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    dns_add_cname 'drupal' 'trident' 'internal'
fi

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    apache2_site_config 'drupal-proxy' 'drupal' 'null' 'null'
fi

#####################
##### APHRODITE #####
#####################
if [ $SHORT_NAME == 'aphrodite' ]; then
    ldap_ldif_config 'drupal'
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    DRUPAL_VERSION=7.24
    DB_PASSWORD_DRUPAL=$(getPassword DB_PASSWORD_DRUPAL)
    DRUPAL_BASE_FOLDER=/var/lib
    DRUPAL_INSTALLATION_FOLDER=$DRUPAL_BASE_FOLDER/drupal
    DRUPAL_ALL_SITES_FOLDER=$DRUPAL_INSTALLATION_FOLDER/sites/all
    DRUPAL_DEFAULT_SITES_FOLDER=$DRUPAL_INSTALLATION_FOLDER/sites/default
    SUDOERS_FILE=/etc/sudoers

    tar -C $DRUPAL_BASE_FOLDER -zxf $ARCHIVE_FOLDER/drupal/drupal-$DRUPAL_VERSION.tar.gz
    chown -R www-data:www-data $DRUPAL_INSTALLATION_FOLDER

    # Drupal Configuration
    install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/$DRUPAL_DEFAULT_SITES_FOLDER/settings.php $DRUPAL_DEFAULT_SITES_FOLDER
    sed -i -e "s|\[-DB_PASSWORD_DRUPAL-\]|$DB_PASSWORD_DRUPAL|g" $DRUPAL_DEFAULT_SITES_FOLDER/settings.php
    eseriReplaceValues $DRUPAL_DEFAULT_SITES_FOLDER/settings.php

    # SSO Configuration
    patch -u $DRUPAL_INSTALLATION_FOLDER/modules/user/user.pages.inc < $ARCHIVE_FOLDER/patches/user.pages.inc.patch

    # Domain Access Module Configuration - For having multiple domain with their own frontpages.
    cp -p $DRUPAL_ALL_SITES_FOLDER/modules/domain/settings.inc $DRUPAL_DEFAULT_SITES_FOLDER
    cp -p $DRUPAL_ALL_SITES_FOLDER/modules/domain/settings_custom_url.inc $DRUPAL_DEFAULT_SITES_FOLDER
    cp -p $DRUPAL_ALL_SITES_FOLDER/modules/domain/domain.bootstrap.inc $DRUPAL_DEFAULT_SITES_FOLDER
    CONFIG="/**  
 * Add the domain module setup routine.
 */
include 'settings.inc';"
    echo "$CONFIG" >> $DRUPAL_DEFAULT_SITES_FOLDER/settings.php

    # Apache2 Configuration
    apache2_site_config 'drupal' 'drupal' 'enable' 't'

    # Eseriman C3 Configuration
    deploy_eseriman_script 'createDrupalUser.sh'
    sed -i -e "s|\[-DB_PASSWORD_DRUPAL-\]|$DB_PASSWORD_DRUPAL|g" /var/lib/eseriman/bin/createDrupalUser.sh

    # Modify sudoers file
    sed -i '/^Cmnd_Alias ESERIMAN.*/ {s||\0, /var/lib/eseriman/bin/createDrupalUser.sh|g;} ' $SUDOERS_FILE

    # Configure Existing users
    configure_existing_users "createDrupalUser.sh" "USERNAME EMAIL_PREFIX FIRSTNAME LASTNAME CLOUD_DOMAIN TIMEZONE"
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    DRUPAL_VERSION=7.24
    SHORT_DOMAIN=$(getParameter short_domain)
    ALIAS_DOMAIN=$(getParameter alias_domain)    
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)
    DB_PASSWORD_DRUPAL=$(getPassword DB_PASSWORD_DRUPAL)
    LDAP_PASSWORD_DRUPAL=$(getPassword LDAP_PASSWORD_DRUPAL)
    echo "CREATE DATABASE drupal CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "CREATE USER 'drupal'@'trident.$DOMAIN' IDENTIFIED BY '$DB_PASSWORD_DRUPAL';" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "GRANT ALL ON drupal.* TO 'drupal'@'trident.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    eseriReplaceValues $TEMPLATE_FOLDER/transient/drupal-$DRUPAL_VERSION.template
    sed -i -e "s|\[-SHORT_DOMAIN-\]|$SHORT_DOMAIN|g;s|\[-LDAP_PASSWORD_DRUPAL-\]|$LDAP_PASSWORD_DRUPAL|g;s|\[-TIMEZONE-\]|$TIMEZONE|g" $TEMPLATE_FOLDER/transient/drupal-$DRUPAL_VERSION.template
    replace_serialized_length $TEMPLATE_FOLDER/transient/drupal-$DRUPAL_VERSION.template
    cat $TEMPLATE_FOLDER/transient/drupal-$DRUPAL_VERSION.template | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    deploy_start_menu_items 'non-profit' 'null'
fi

exit 0
