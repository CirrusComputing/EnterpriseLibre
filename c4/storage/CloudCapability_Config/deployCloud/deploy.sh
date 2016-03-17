#!/bin/bash
#
# CloudCapability_Config deploy script - v2.9
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

################
##### HERA #####
################
if [ $SHORT_NAME == 'hera' ]; then
    hasCapability MailingLists
    if [ $? -eq 0 ]; then
	hasCapabilityEnabled MailingLists
	if [ $? -eq 0 ]; then
	    a2ensite mailinglists
	    init_process '/etc/init.d/mailman' 'restart'
	else
	    a2ensite mailinglists
	    init_process '/etc/init.d/mailman' 'stop'
	fi
    fi

    init_process '/etc/init.d/apache2' 'reload'
fi

####################
##### POSEIDON #####
####################
if [ $SHORT_NAME == 'poseidon' ]; then
    CAPABILITIES=( Vtiger Nuxeo Trac Wiki SQLLedger Timesheet OrangeHRM )
    A2ENSITE=''
    A2DISSITE=''
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	hasCapability $CAPABILITY 
	if [ $? -eq 0 ]; then
	    hasCapabilityEnabled $CAPABILITY
	    if [ $? -eq 0 ]; then 
		A2ENSITE+=" $(to_lower $CAPABILITY)"
	    else 
		A2DISSITE+=" $(to_lower $CAPABILITY)"
	    fi
	fi
    done

    [[ $A2ENSITE != '' ]] && a2ensite $A2ENSITE
    [[ $A2DISSITE != '' ]] && a2dissite $A2DISSITE
    init_process '/etc/init.d/apache2' 'reload'
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    hasCapability OpenERP
    if [ $? -eq 0 ]; then
	hasCapabilityEnabled OpenERP
	if [ $? -eq 0 ]; then
	    init_process '/etc/init.d/openerp' 'restart'
	else
	    init_process '/etc/init.d/openerp' 'stop'
	fi
    fi

    CAPABILITIES=( Redmine PHPScheduleIt Drupal CiviCRM ChurchInfo Moodle OpenERP )
    A2ENSITE=''
    A2DISSITE=''
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	hasCapability $CAPABILITY 
	if [ $? -eq 0 ]; then
	    hasCapabilityEnabled $CAPABILITY
	    if [ $? -eq 0 ]; then 
		A2ENSITE+=" $(to_lower $CAPABILITY)"
	    else 
		A2DISSITE+=" $(to_lower $CAPABILITY)"
	    fi
	fi
    done

    [[ $A2ENSITE != '' ]] && a2ensite $A2ENSITE
    [[ $A2DISSITE != '' ]] && a2dissite $A2DISSITE
    init_process '/etc/init.d/apache2' 'reload'
fi

###############
#####CHAOS#####
###############
if [ $SHORT_NAME == 'chaos' ]; then
    CAPABILITIES=( LibreOffice Gimp Scribus Inkscape FreeMind VUE ProjectLibre )
    CAPABILITY_FILENAMES=( libreoffice gimp scribus inkscape freemind vue projectlibre )
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	CAPABILITY_FILENAME=${CAPABILITY_FILENAMES[$i]}
	hasCapability $CAPABILITY 
	if [ $? -eq 0 ]; then
	    hasCapabilityEnabled $CAPABILITY
	    if [ $? -eq 0 ]; then 
		chmod 755 /usr/bin/$CAPABILITY_FILENAME
	    else 
		chmod 750 /usr/bin/$CAPABILITY_FILENAME
	    fi
	fi
    done

    # Favorites menu
    FAVORITES_MENU=' Start Here...::firefox http://wiki.enterpriselibre.org/::EnterpriseLibreHelpAndSupport::1,'
    if [ -f "/usr/local/bin/EnterpriseLibreSystemManager" ]; then
	FAVORITES_MENU+='System Manager::sudo /usr/local/bin/EnterpriseLibreSystemManager::EnterpriseLibreSystemManager::1,'
    fi
    FAVORITES_MENU+='EnterpriseLibre Manager::sudo /usr/local/bin/EnterpriseLibreCloudManager::EnterpriseLibreCloudManager::1,Email \& Calendar::evolution::evolution::1,Shared Folder::file:///srv/shared::inode-directory::3,Browsing::firefox %u::firefox::1'
    CAPABILITIES=( LibreOffice Wiki )
    CAPABILITY_ITEMS=( ",Word Processing::libreoffice -writer %U::libreoffice-writer::1,Spreadsheets::libreoffice -calc %U::libreoffice-calc::1" ",Wiki::firefox http://wiki.$DOMAIN/::wiki::1" )
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	CAPABILITY_ITEM=${CAPABILITY_ITEMS[$i]}
	hasCapability $CAPABILITY 
	if [ $? -eq 0 ]; then
	    hasCapabilityEnabled $CAPABILITY
	    if [ $? -eq 0 ]; then 
		FAVORITES_MENU+=$CAPABILITY_ITEM
	    fi
	fi
    done
  
    #Update favorites menu
    sed -i "s|/apps/gnomenu/favorites.*|/apps/gnomenu/favorites [$FAVORITES_MENU]|" /usr/share/gconf/defaults/99_EnterpriseLibre-gnomenu
    update-gconf-defaults
fi

exit 0
