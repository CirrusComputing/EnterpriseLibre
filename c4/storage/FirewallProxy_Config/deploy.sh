#!/bin/bash
#
# Firewall Proxy Config Deploy Script - v2.9
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Get the system parameters.
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

# Mark start point in log file.
echo "Firewall Proxy Config"

CAPABILITIES=$(getParameter capability)
EXTERNAL_NAMES=$(getParameter external_name)
SSLS=$(getParameter ssl)
ALIAS_DOMAIN=$(getParameter alias_domain)

# Tokenize capabilities and external names variables
CAPABILITIES=( $CAPABILITIES )
EXTERNAL_NAMES=( $EXTERNAL_NAMES )
SSLS=( $SSLS )

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    # Empty out /etc/bind/db.externalcapabilities
    echo "" > /etc/bind/db.externalcapabilities

    CNAME_CONTAINERS=()
    for (( i=0; i<${#EXTERNAL_NAMES[@]}; i++ )); do
	CNAME_CONTAINERS[$i]='@'
    done

    dns_add_cname "${EXTERNAL_NAMES[*]}" "${CNAME_CONTAINERS[*]}" "external"
fi
    
##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    SHOREWALL_CONFIG_FOLDER=/etc/shorewall
    SHOREWALL_RULES_FILE=$SHOREWALL_CONFIG_FOLDER/rules
    APACHE2_CONFIG_FOLDER=/etc/apache2
    APACHE2_SITES_AVAILABLE=$APACHE2_CONFIG_FOLDER/sites-available
    APACHE2_SITES_ENABLED=$APACHE2_CONFIG_FOLDER/sites-enabled
    A2ENSITE='default default-ssl desktop custom-*'

    # Disable IMAP and SMTP in shorewall rules file
    sed -i "/^\(DNAT.*net.*loc:.*tcp.*993.*-.*# IMAP.*\)/s||#\1|g" $SHOREWALL_RULES_FILE
    sed -i "/^\(DNAT.*net.*loc:.*tcp.*465.*-.*# SMTP.*\)/s||#\1|g" $SHOREWALL_RULES_FILE

    # Replacing the old external name with the new one.
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	EXTERNAL_NAME=${EXTERNAL_NAMES[$i]}
	SSL=${SSLS[$i]}
	echo "$CAPABILITY $EXTERNAL_NAME $SSL"
	if [ $CAPABILITY == 'IMAP' ]; then
	    sed -i "/^#\(DNAT.*net.*loc:.*tcp.*993.*-.*# IMAP.*\)/s||\1|g" $SHOREWALL_RULES_FILE
	elif [ $CAPABILITY == 'SMTP' ]; then
	    sed -i "/^#\(DNAT.*net.*loc:.*tcp.*465.*-.*# SMTP.*\)/s||\1|g" $SHOREWALL_RULES_FILE
	else 
	    sed -i "s|\(.*ServerName\).*|\1 $EXTERNAL_NAME.$DOMAIN|" $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
	    sed -i "s|\(.*ServerAlias\).*|\1 $EXTERNAL_NAME.$ALIAS_DOMAIN|" $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
	    if [ $SSL == 't' ]; then
		sed -i '/<VirtualHost .*:.*>/s|:80>|:443>|' $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
		sed -i 's|SSLEngine Off|SSLEngine On|' $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
	    else
		sed -i '/<VirtualHost .*:.*>/s|:443>|:80>|' $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
		sed -i 's|SSLEngine On|SSLEngine Off|' $APACHE2_SITES_AVAILABLE/$(to_lower $CAPABILITY)
	    fi
	    A2ENSITE="$A2ENSITE $(to_lower $CAPABILITY)"
	fi
    done

    # Restart shorewall process
    init_process '/etc/init.d/shorewall' 'restart'

    # Remove all enabled sites.
    rm $APACHE2_SITES_ENABLED/*
    # Enable the new sites.
    a2ensite $A2ENSITE
    # Reload apache2 process
    init_process '/etc/init.d/apache2' 'reload'
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)	
    for (( i=0; i<${#CAPABILITIES[@]}; i++ )); do
	CAPABILITY=${CAPABILITIES[$i]}
	EXTERNAL_NAME=${EXTERNAL_NAMES[$i]}
	if [ $CAPABILITY == 'Drupal' ] || [ $CAPABILITY == 'CiviCRM' ]; then
	    # Check if alias already exists.
	    ALIAS_ID=$(echo "SELECT alias_id FROM drupal_domain_alias WHERE pattern='$EXTERNAL_NAME.$ALIAS_DOMAIN';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal |  awk 'NR==2' | sed "s|^.* ||")
	    # If alias does not exist.
	    if [[ -z "$ALIAS_ID" ]]; then
		# Get domain_id from drupal_domain_conf
		DOMAIN_ID=$(echo "SELECT domain_id FROM drupal_domain_conf WHERE settings REGEXP '.*\"site_name\";s:[0-9]*:\"$(to_lower $CAPABILITY).$DOMAIN\".*';" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | awk 'NR==2' | sed "s|^.* ||")
		# If can't get domain_id from previous statement, then get it from drupal_domain_alias table
		[[ -z "$DOMAIN_ID" ]] && DOMAIN_ID=$(echo "SELECT domain_id FROM drupal_domain_alias WHERE pattern='$(to_lower $CAPABILITY).$ALIAS_DOMAIN'" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal | awk 'NR==2' | sed "s|^.* ||")
		# Finally there is no way to grab the domain_id, so exit.
		[[ -z "$DOMAIN_ID" ]] && exit 1
		# If successfull in getting the domain_id, then insert the new alias.
		echo "INSERT INTO drupal_domain_alias (domain_id, pattern, redirect) values (2,'$EXTERNAL_NAME.$ALIAS_DOMAIN', 0);" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	    fi
	fi
    done    
fi

exit 0
