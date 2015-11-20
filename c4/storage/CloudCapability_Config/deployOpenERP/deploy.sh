#!/bin/bash
#
# OpenERP deploy script - v2.2
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy OpenERP"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    dns_add_cname 'openerp openerp-external' 'trident trident' 'internal'
fi

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    apache2_site_config 'openerp-proxy' 'openerp' 'null' 'null'
fi

#####################
##### APHRODITE #####
#####################
if [ $SHORT_NAME == 'aphrodite' ]; then
    ldap_ldif_config 'openerp   '
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    OPENERP_VERSION=7.0-20140116
    SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
    DB_PASSWORD_OPENERP=$(getPassword DB_PASSWORD_OPENERP)
    MASTER_PASSWORD_OPENERP=$(getPassword MASTER_PASSWORD_OPENERP)
    OPENERP_CONFIG_FOLDER=/etc/openerp
    OPENERP_SHARE_FOLDER=/usr/share/pyshared/openerp
    OPENERP_LIB_FOLDER=/usr/lib/pymodules/python2.7/openerp
    OPENERP_SHARE_ADDONS_FOLDER=$OPENERP_SHARE_FOLDER/addons
    OPENERP_LIB_ADDONS_FOLDER=$OPENERP_LIB_FOLDER/addons
    OPENERP_DEFAULT_SITES_FOLDER=$OPENERP_INSTALLATION_FOLDER/sites/default
    SUDOERS_FILE=/etc/sudoers

    # Configure OpenERP repository
    install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/openerp.list
    eseriReplaceValues /etc/apt/sources.list.d/openerp.list
    apt-get update >/dev/null

    # OpenERP Installation
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y -q --force-yes openerp >/dev/null

    # OpenERP Configuration
    install -o www-data -g www-data -m 644 $TEMPLATE_FOLDER/$OPENERP_CONFIG_FOLDER/openerp-server.conf $OPENERP_CONFIG_FOLDER/
    sed -i -e "s|\[-DB_PASSWORD_OPENERP-\]|$DB_PASSWORD_OPENERP|g;s|\[-MASTER_PASSWORD_OPENERP-\]|$MASTER_PASSWORD_OPENERP|g" $OPENERP_CONFIG_FOLDER/openerp-server.conf
    eseriReplaceValues $OPENERP_CONFIG_FOLDER/openerp-server.conf

    # OpenERP Database Configuration
    echo -e "\n; Specifying what template to create the database with for UTF8 encoding\ndb_template = template0" >> $OPENERP_CONFIG_FOLDER/openerp-server.conf

    # SSO Installation
    tar -C $OPENERP_SHARE_ADDONS_FOLDER/ -zxf $ARCHIVE_FOLDER/openerp/addons/smile_sso-$OPENERP_VERSION-custom-1.tar.gz
    tar -C $OPENERP_LIB_ADDONS_FOLDER/ -zxf $ARCHIVE_FOLDER/openerp/addons/smile_sso-$OPENERP_VERSION-custom-1-shortcut.tar.gz

    # SSO Configuration
    echo -e "\n; Smile_SSO configuration\nsmile_sso.shared_secret_pin = 0000\nsmile_sso.lifetime_duration = 31536000\nserver_wide_modules = web,smile_sso" >> $OPENERP_CONFIG_FOLDER/openerp-server.conf
    
    # OpenERP custom patches
    ## Replace OpenERP link with SSO Login link on standard login page
    patch -u $OPENERP_SHARE_ADDONS_FOLDER/web/static/src/xml/base.xml < $ARCHIVE_FOLDER/patches/base.xml.patch
    ## Direct user to sso_login on logout
    patch -u $OPENERP_SHARE_ADDONS_FOLDER/web/static/src/js/chrome.js < $ARCHIVE_FOLDER/patches/chrome.js.patch
    ## Remove the announcement that pops up if OpenERP is not registered
    patch -u $OPENERP_SHARE_ADDONS_FOLDER/mail/static/src/js/mail.js < $ARCHIVE_FOLDER/patches/mail.js.patch
    ## Auth_LDAP patch
    patch -u $OPENERP_SHARE_ADDONS_FOLDER/auth_ldap/users_ldap.py < $ARCHIVE_FOLDER/patches/users_ldap.py.patch

    # Apache2 Configuration
    a2enmod proxy proxy_http
    apache2_site_config 'openerp' 'openerp' 'enable' 't'

    # Eseriman C3 Configuration
    deploy_eseriman_script 'createOpenERPUser.sh'
    sed -i -e "s|\[-DB_PASSWORD_OPENERP-\]|$DB_PASSWORD_OPENERP|g" /var/lib/eseriman/bin/createOpenERPUser.sh
    
    # Modify sudoers file
    sed -i '/^Cmnd_Alias ESERIMAN.*/ {s||\0, /etc/init.d/openerp, /var/lib/eseriman/bin/createOpenERPUser.sh|g;} ' $SUDOERS_FILE

    # Restart OpenERP process
    init_process '/etc/init.d/openerp' 'restart'

    # Configure Existing users
    while [ "$(wget --spider -S http://openerp.$DOMAIN:8069 2>&1 | grep 'HTTP/' | awk '{print $2}')" != "200" ]; do
	sleep 5
    done
    configure_existing_users "createOpenERPUser.sh" "USERNAME EMAIL_PREFIX FIRSTNAME LASTNAME CLOUD_DOMAIN PASSWORD TIMEZONE"
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    OPENERP_VERSION=7.0-20140116
    DB_PASSWORD_OPENERP=$(getPassword DB_PASSWORD_OPENERP)
    LDAP_PASSWORD_OPENERP=$(getPassword LDAP_PASSWORD_OPENERP)
    IT_MAN_USER=$(getParameter manager_username)
    
    su - -c "psql -c \"CREATE ROLE openerp PASSWORD '$DB_PASSWORD_OPENERP' CREATEDB INHERIT LOGIN;\"" postgres
    su - -c "createdb openerp -O openerp --template=template0 --encoding utf-8" postgres
    #Configured openerp database with mail server settings, auth_ldap, smile_sso module and admin privileges (table res_groups_users_rel values (1,4),(1,6),(1,9))
    eseriReplaceValues $TEMPLATE_FOLDER/transient/openerp-$OPENERP_VERSION.template
    cat $TEMPLATE_FOLDER/transient/openerp-$OPENERP_VERSION.template | sed -e "s|\[-IT_MAN_USER-\]|$IT_MAN_USER|g;s|\[-LDAP_PASSWORD_OPENERP-\]|$LDAP_PASSWORD_OPENERP|g;" > /var/lib/postgresql/openerp-$OPENERP_VERSION.template
    chmod a+rx /var/lib/postgresql/openerp-$OPENERP_VERSION.template
    su -l -c "psql -d openerp -f openerp-$OPENERP_VERSION.template > /dev/null 2>&1" postgres
    rm /var/lib/postgresql/openerp-$OPENERP_VERSION.template
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    deploy_start_menu_items 'manufacturing' 'openerp'
fi

exit 0
