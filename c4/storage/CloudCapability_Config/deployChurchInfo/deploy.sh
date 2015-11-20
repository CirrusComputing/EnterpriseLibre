#!/bin/bash
#
# ChurchInfo deploy script - v2.0
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
echo "$(date) Deploy ChurchInfo"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    dns_add_cname 'churchinfo' 'trident' 'internal'
fi

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    apache2_site_config 'churchinfo-proxy' 'churchinfo' 'null' 'null'
fi

#####################
##### APHRODITE #####
#####################
if [ $SHORT_NAME == 'aphrodite' ]; then
    ldap_ldif_config 'churchinfo'
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    CHURCHINFO_VERSION=1.2.13
    DB_PASSWORD_CHURCHINFO=$(getPassword DB_PASSWORD_CHURCHINFO)
    CHURCHINFO_BASE_FOLDER=/var/lib
    CHURCHINFO_INSTALLATION_FOLDER=$CHURCHINFO_BASE_FOLDER/churchinfo
    CHURCHINFO_INCLUDE_FOLDER=$CHURCHINFO_INSTALLATION_FOLDER/Include
    SUDOERS_FILE=/etc/sudoers

    tar -C $CHURCHINFO_BASE_FOLDER -zxf $ARCHIVE_FOLDER/churchinfo/churchinfo-$CHURCHINFO_VERSION.tar.gz
    chown -R www-data:www-data $CHURCHINFO_INSTALLATION_FOLDER

    # ChurchInfo Configuration
    install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/$CHURCHINFO_INCLUDE_FOLDER/Config.php $CHURCHINFO_INCLUDE_FOLDER
    sed -i -e "s|\[-DB_PASSWORD_CHURCHINFO-\]|$DB_PASSWORD_CHURCHINFO|g" $CHURCHINFO_INCLUDE_FOLDER/Config.php
    eseriReplaceValues $CHURCHINFO_INCLUDE_FOLDER/Config.php

    # Apache2 Configuration
    apache2_site_config 'churchinfo' 'churchinfo' 'enable' 't'

    # Eseriman C3 Configuration
    deploy_eseriman_script 'createChurchInfoUser.sh changeChurchInfoUserPassword.sh'
    sed -i -e "s|\[-DB_PASSWORD_CHURCHINFO-\]|$DB_PASSWORD_CHURCHINFO|g" /var/lib/eseriman/bin/createChurchInfoUser.sh
    sed -i -e "s|\[-DB_PASSWORD_CHURCHINFO-\]|$DB_PASSWORD_CHURCHINFO|g" /var/lib/eseriman/bin/changeChurchInfoUserPassword.sh

    # Modify sudoers file
    sed -i '/^Cmnd_Alias ESERIMAN.*/ {s||\0, /var/lib/eseriman/bin/createChurchInfoUser.sh, /var/lib/eseriman/bin/changeChurchInfoUserPassword.sh|g;} ' $SUDOERS_FILE

    # Configure Existing users
    configure_existing_users "createChurchInfoUser.sh" "USERNAME EMAIL_PREFIX FIRSTNAME LASTNAME CLOUD_DOMAIN MD5_PASSWORD"
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    CHURCHINFO_VERSION=1.2.13
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)
    DB_PASSWORD_CHURCHINFO=$(getPassword DB_PASSWORD_CHURCHINFO)
    echo "CREATE DATABASE churchinfo CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "CREATE USER 'churchinfo'@'trident.$DOMAIN' IDENTIFIED BY '$DB_PASSWORD_CHURCHINFO';" | mysql -uroot -p$DB_PASSWORD_MYSQL
    echo "GRANT ALL ON churchinfo.* TO 'churchinfo'@'trident.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -p$DB_PASSWORD_MYSQL
    eseriReplaceValues $TEMPLATE_FOLDER/transient/churchinfo-$CHURCHINFO_VERSION.template
    cat $TEMPLATE_FOLDER/transient/churchinfo-$CHURCHINFO_VERSION.template | sed -e "s|\[-TIMEZONE-\]|$TIMEZONE|g" | mysql -uroot -p$DB_PASSWORD_MYSQL churchinfo    
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    deploy_start_menu_items 'non-profit' 'churchinfo'
fi

exit 0
