#!/bin/bash
#
# CiviCRM deploy script - v2.1
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
echo "$(date) Deploy CiviCRM"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    dns_add_cname 'civicrm' 'trident' 'internal'
fi

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    apache2_site_config 'civicrm-proxy' 'civicrm' 'null' 'null'
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    DB_PASSWORD_DRUPAL=$(getPassword DB_PASSWORD_DRUPAL)
    DB_PASSWORD_CIVICRM=$(getPassword DB_PASSWORD_CIVICRM)
    DRUPAL_BASE_FOLDER=/var/lib
    DRUPAL_INSTALLATION_FOLDER=$DRUPAL_BASE_FOLDER/drupal
    DRUPAL_DEFAULT_SITES_FOLDER=$DRUPAL_INSTALLATION_FOLDER/sites/default

    #CiviCRM Configuration
    install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/$DRUPAL_DEFAULT_SITES_FOLDER/civicrm.settings.php $DRUPAL_DEFAULT_SITES_FOLDER
    sed -i -e "s|\[-DB_PASSWORD_DRUPAL-\]|$DB_PASSWORD_DRUPAL|g;s|\[-DB_PASSWORD_CIVICRM-\]|$DB_PASSWORD_CIVICRM|g" $DRUPAL_DEFAULT_SITES_FOLDER/civicrm.settings.php
    eseriReplaceValues $DRUPAL_DEFAULT_SITES_FOLDER/civicrm.settings.php

    #Apache2 Configuration
    apache2_site_config 'civicrm' 'civicrm' 'enable' 't'
fi

################3
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    CIVICRM_VERSION=4.4.3
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)
    DB_PASSWORD_CIVICRM=$(getPassword DB_PASSWORD_CIVICRM)
    SHORT_DOMAIN=$(getParameter short_domain)
    ALIAS_DOMAIN=$(getParameter alias_domain)
    echo "CREATE DATABASE civicrm CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "CREATE USER 'civicrm'@'trident.$DOMAIN' IDENTIFIED BY '$DB_PASSWORD_CIVICRM';" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "GRANT ALL ON civicrm.* TO 'civicrm'@'trident.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    eseriReplaceValues $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION.template
    cat $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION.template | sed -e "s|\[-SHORT_DOMAIN-\]|$SHORT_DOMAIN|g" | mysql -uroot -p$DB_PASSWORD_MYSQL civicrm
    
    #Domain Access module configuration on drupal database
    NEXT_DOMAIN_ID=`echo "SELECT MAX(domain_id + 1) FROM drupal_domain;" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | awk 'NR==2' | sed "s|^.* ||"`
    eseriReplaceValues $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION-domain-access.template
    sed -i -e "s|\[-SHORT_DOMAIN-\]|$SHORT_DOMAIN|g;s|\[-NEXT_DOMAIN_ID-\]|$NEXT_DOMAIN_ID|g;s|\[-TIMEZONE-\]|$TIMEZONE|g" $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION-domain-access.template
    replace_serialized_length $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION-domain-access.template
    cat $TEMPLATE_FOLDER/transient/civicrm-$CIVICRM_VERSION-domain-access.template | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    deploy_start_menu_items 'non-profit' 'civicrm'
fi

exit 0
