#!/bin/bash
#
# Domain Config Deploy Script - v4.2
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

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SHORT_DOMAIN=$(getParameter short_domain)
NEW_CONFIG_VERSION=$(getParameter new_config_version)

# Mark start point in log file.
echo "Domain Config $NEW_CONFIG_VERSION"

OLD_EMAIL_DOMAIN=$(getParameter old_email_domain)
OLD_IMAP_SERVER=$(getParameter old_imap_server)
OLD_ALIAS_DOMAIN=$(getParameter old_alias_domain)
OLD_WEBSITE_IP=$(getParameter old_website_ip)

NEW_EMAIL_DOMAIN=$(getParameter new_email_domain)
NEW_IMAP_SERVER=$(getParameter new_imap_server)
NEW_ALIAS_DOMAIN=$(getParameter new_alias_domain)
NEW_WEBSITE_IP=$(getParameter new_website_ip)

USERNAMES=$(getParameter username)
EMAIL_PREFIXES=$(getParameter email_prefix)
PASSWORDS=$(getParameter password)

# Tokenize usernames, email_prefixs and passwords variables
USERNAMES=( $USERNAMES )
EMAIL_PREFIXES=( $EMAIL_PREFIXES )
PASSWORDS=( $PASSWORDS )    

determine_mail_login()
{
    USERNAME=$1
    EMAIL_PREFIX=$2
    NEW_EMAIL_DOMAIN=$3
    
    MAIL_LOGIN=$USERNAME
    MAIL_LOGIN_ESCAPED=$USERNAME
    if [ $NEW_CONFIG_VERSION == '2.12' ]; then
	MAIL_LOGIN=$EMAIL_PREFIX@$NEW_EMAIL_DOMAIN
	MAIL_LOGIN_ESCAPED=$EMAIL_PREFIX%40$NEW_EMAIL_DOMAIN
    fi
}

flush_dns_cache()
{
    # Flush cache for old & new domain.
    rndc flushname $1
    rndc flushname $2
}

update_apache2_sites()
{
    FILES=$4
    [[ -z "$FILES" ]] && FILES='*'
    for SEARCH_STRING in $3; do
	sed -i "/$SEARCH_STRING/s|$1|$2|" /etc/apache2/sites-available/$FILES
    done
    init_process '/etc/init.d/apache2' 'reload'
}

####################
##### SMC-ZEUS #####
####################
if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
    DNS_CONFIG_FOLDER=/etc/bind
    DNS_NAMED_CONF_INTERNAL_CUSTOMERZONES=$DNS_CONFIG_FOLDER/named.conf.internal.customerzones
    DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES=$DNS_CONFIG_FOLDER/named.conf.external.customerzones
    DNS_ORGS_FOLDER=$DNS_CONFIG_FOLDER/orgs
    DNS_INTERNAL_ORGS_FOLDER=$DNS_ORGS_FOLDER/internal
    DNS_EXTERNAL_ORGS_FOLDER=$DNS_ORGS_FOLDER/external
    if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
	DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ORGS_FOLDER/new_domain-internal-master.conf
	DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ORGS_FOLDER/new_domain-external-master.conf
    fi
    
    if [ $NEW_CONFIG_VERSION == '2.3' ]; then
	DNS_CONF_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ORGS_FOLDER/$NEW_EMAIL_DOMAIN.conf
	DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ORGS_FOLDER/$NEW_EMAIL_DOMAIN.conf
	
	if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
	    # Internal
	    install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	    INTERNAL_MASTER=$(grep "masters" $(echo $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE | sed "s|$NEW_EMAIL_DOMAIN|$OLD_EMAIL_DOMAIN|") | awk 'NR==1{print $3}')
	    sed -i -e  "s|\[-OLD_EMAIL_DOMAIN-\]|$OLD_EMAIL_DOMAIN|" -e "s|\[-NEW_EMAIL_DOMAIN-\]|$NEW_EMAIL_DOMAIN|" -e "s|\[-INTERNAL_MASTER-\]|$INTERNAL_MASTER|" $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_INTERNAL_CUSTOMERZONES
	    echo "include \"$DNS_CONF_CLOUD_INTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_INTERNAL_CUSTOMERZONES
	fi
	if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
	    # External
	    install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	    EXTERNAL_SECRET=$(grep "secret" $(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$NEW_EMAIL_DOMAIN|$OLD_EMAIL_DOMAIN|") | awk 'NR==1{print $2}' | sed "s|\"\(.*\)\";|\1|")
	    EXTERNAL_MASTER=$(grep "masters" $(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$NEW_EMAIL_DOMAIN|$OLD_EMAIL_DOMAIN|") | awk 'NR==1{print $3}')
	    sed -i -e  "s|\[-OLD_EMAIL_DOMAIN-\]|$OLD_EMAIL_DOMAIN|" -e "s|\[-NEW_EMAIL_DOMAIN-\]|$NEW_EMAIL_DOMAIN|" -e "s|\[-EXTERNAL_MASTER-\]|$EXTERNAL_MASTER|" -e "s|\[-EXTERNAL_SECRET-\]|$EXTERNAL_SECRET|" $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$NEW_EMAIL_DOMAIN|$OLD_EMAIL_DOMAIN|" | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	    echo "include \"$DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	fi
    elif [ $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	DNS_CONF_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ORGS_FOLDER/$OLD_EMAIL_DOMAIN.conf
	DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ORGS_FOLDER/$OLD_EMAIL_DOMAIN.conf
	
	if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
	    # Internal
	    rm $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_INTERNAL_CUSTOMERZONES
	fi
	if [ $SHORT_NAME == 'zeus' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
	    # External
	    rm $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|" | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	    sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	    echo "include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|")\";" >> $DNS_NAMED_CONF_EXTERNAL_CUSTOMERZONES
	fi
    fi
 
    # Remove Cache Files
    rm -f /var/cache/bind/db.$OLD_EMAIL_DOMAIN.*
    rm -f /var/cache/bind/db.$NEW_EMAIL_DOMAIN.*
    # Flush DNS and restart Bind9
    flush_dns_cache $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN
    init_process '/etc/init.d/bind9' 'reload'
fi

######################
##### SMC-HERMES #####
######################
if [ $SHORT_NAME == 'hermes' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias" "custom-$SHORT_DOMAIN-*"
    fi
fi

####################
##### SMC-HERA #####
####################
if [ $SHORT_NAME == 'hera' -a $DOMAIN == $SYSTEM_ANCHOR_DOMAIN ]; then
    POSTFIX_CONFIG_FOLDER=/etc/postfix
    POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
    POSTFIX_RELAY_DOMAINS=$POSTFIX_CONFIG_FOLDER/relay_domains
    POSTFIX_RELAY_HOSTS=$POSTFIX_CONFIG_FOLDER/relay_hosts

    if [ $NEW_CONFIG_VERSION == '2.2' -o $NEW_CONFIG_VERSION == '2.3' ]; then
	# Configure Transport
	echo "$NEW_EMAIL_DOMAIN smtp:smtp.$NEW_ALIAS_DOMAIN" >> $POSTFIX_TRANSPORT
	echo "lists.$NEW_EMAIL_DOMAIN smtp:smtp.$NEW_ALIAS_DOMAIN" >> $POSTFIX_TRANSPORT
	# Configure Relay Domains
	echo "$NEW_EMAIL_DOMAIN OK" >> $POSTFIX_RELAY_DOMAINS
	echo "lists.$NEW_EMAIL_DOMAIN OK" >> $POSTFIX_RELAY_DOMAINS
	# Configure Relay Hosts
	echo "@$NEW_EMAIL_DOMAIN smtp.$NEW_ALIAS_DOMAIN" >> $POSTFIX_RELAY_HOSTS
	echo "@lists.$NEW_EMAIL_DOMAIN smtp.$NEW_ALIAS_DOMAIN" >> $POSTFIX_RELAY_HOSTS
	postmap $POSTFIX_RELAY_HOSTS
    elif [ $NEW_CONFIG_VERSION == '2.2to1.1' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	# Configure Transport
 	sed -i "/^$OLD_EMAIL_DOMAIN/d" $POSTFIX_TRANSPORT
 	sed -i "/^lists.$OLD_EMAIL_DOMAIN/d" $POSTFIX_TRANSPORT
	# Configure Relay Domains
	sed -i "/^$OLD_EMAIL_DOMAIN/d" $POSTFIX_RELAY_DOMAINS
	sed -i "/^lists.$OLD_EMAIL_DOMAIN/d" $POSTFIX_RELAY_DOMAINS
	# Configure Relay Hosts
	sed -i "/^@$OLD_EMAIL_DOMAIN smtp.$OLD_ALIAS_DOMAIN/d" $POSTFIX_RELAY_HOSTS
	sed -i "/^@lists.$OLD_EMAIL_DOMAIN smtp.$OLD_ALIAS_DOMAIN/d" $POSTFIX_RELAY_HOSTS
    fi
    postmap $POSTFIX_TRANSPORT $POSTFIX_RELAY_DOMAINS $POSTFIX_RELAY_HOSTS   
    # Reload Postfix
    init_process '/etc/init.d/postfix' 'reload'
fi

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' -a $DOMAIN != $SYSTEM_ANCHOR_DOMAIN ]; then
    DEPLOY_TIME=$(date +%Y%m%d01)    
    DNS_CONFIG_FOLDER=/etc/bind
    DNS_DB_INTERNAL=$DNS_CONFIG_FOLDER/db.$DOMAIN.internal
    DNS_DB_EXTERNAL=$DNS_CONFIG_FOLDER/db.$DOMAIN.external
    DNS_NAMED_CONF_INTERNAL=$DNS_CONFIG_FOLDER/named.conf.internal
    DNS_NAMED_CONF_EXTERNAL=$DNS_CONFIG_FOLDER/named.conf.external	
    DNS_ZONES_FOLDER=$DNS_CONFIG_FOLDER/zones
    DNS_INTERNAL_ZONES_FOLDER=$DNS_ZONES_FOLDER/internal
    DNS_EXTERNAL_ZONES_FOLDER=$DNS_ZONES_FOLDER/external
    DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/new_domain-internal.conf
    DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ZONES_FOLDER/new_domain-external.conf
	
    if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' -o $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' ]; then	
	# Update db file with CNAME.
	if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' ]; then
	    sed -i "s|^.*\(imap.*IN.*CNAME\).*|imap\t\t\tIN\tCNAME\t$NEW_IMAP_SERVER\.|g" $DNS_DB_INTERNAL
	elif [ $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' ]; then
            sed -i "s|^.*\(imap.*IN.*CNAME\).*|imap\t\t\tIN\tCNAME\thera|g" $DNS_DB_INTERNAL
	fi
	
	dns_update_serial "$DNS_DB_INTERNAL"
	flush_dns_cache $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN
    fi
    
    if [ $NEW_CONFIG_VERSION == '2.3' ]; then
	DNS_DB_INTERNAL_NEW=$DNS_CONFIG_FOLDER/db.$NEW_EMAIL_DOMAIN.internal
	DNS_DB_EXTERNAL_NEW=$DNS_CONFIG_FOLDER/db.$NEW_EMAIL_DOMAIN.external
	DNS_CONF_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/$NEW_EMAIL_DOMAIN.conf
	DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ZONES_FOLDER/$NEW_EMAIL_DOMAIN.conf
	
        # Internal
	cp -p $DNS_DB_INTERNAL $DNS_DB_INTERNAL_NEW
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $DNS_DB_INTERNAL_NEW
	install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_INTERNAL_ZONE_FILE $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	sed -i "s|\[-NEW_EMAIL_DOMAIN-\]|$NEW_EMAIL_DOMAIN|" $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_INTERNAL 
	echo "include \"$DNS_CONF_CLOUD_INTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_INTERNAL
	
        # External
	mv $DNS_DB_EXTERNAL $DNS_DB_EXTERNAL_NEW
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $DNS_DB_EXTERNAL_NEW
	install -o root -g root -m 644 $TEMPLATE_FOLDER/$DNS_CONF_TEMPLATE_CLOUD_EXTERNAL_ZONE_FILE $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	sed -i "s|\[-NEW_EMAIL_DOMAIN-\]|$NEW_EMAIL_DOMAIN|" $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$NEW_EMAIL_DOMAIN|$OLD_EMAIL_DOMAIN|" | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL
	echo "include \"$DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE\";" >> $DNS_NAMED_CONF_EXTERNAL
	
	# Uncomment website records in external zone file
	if [ $NEW_WEBSITE_IP != '0.0.0.0' ]; then
	    sed -i -e "/.*www.*IN.*A/s|.*|www\t\t\tIN\tA\t$NEW_WEBSITE_IP|" -e "/.*www.*IN.*TXT/s|.*|www\t\t\tIN\tTXT\t\"v=spf1 -all\"|" $DNS_DB_EXTERNAL_NEW
	fi

	# Update serial and flush cache
	dns_update_serial "$DNS_DB_INTERNAL_NEW $DNS_DB_INTERNALREVERSE $DNS_DB_EXTERNAL_NEW"
	flush_dns_cache $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN
    fi

    if [ $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	DNS_DB_INTERNAL_NEW=$DNS_CONFIG_FOLDER/db.$OLD_EMAIL_DOMAIN.internal
	DNS_DB_EXTERNAL_NEW=$DNS_CONFIG_FOLDER/db.$OLD_EMAIL_DOMAIN.external
	DNS_CONF_CLOUD_INTERNAL_ZONE_FILE=$DNS_INTERNAL_ZONES_FOLDER/$OLD_EMAIL_DOMAIN.conf
	DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE=$DNS_EXTERNAL_ZONES_FOLDER/$OLD_EMAIL_DOMAIN.conf

        # Internal
	rm $DNS_DB_INTERNAL_NEW
	rm $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_INTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_INTERNAL

        # External
	mv $DNS_DB_EXTERNAL_NEW $DNS_DB_EXTERNAL
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $DNS_DB_EXTERNAL
	rm $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|" | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL
	sed -i "/^include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed 's|/|\\/|g')\"/d" $DNS_NAMED_CONF_EXTERNAL
	echo "include \"$(echo $DNS_CONF_CLOUD_EXTERNAL_ZONE_FILE | sed "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|")\";" >> $DNS_NAMED_CONF_EXTERNAL	
	
	# Comment out website records in external zone file
	sed -i -e "/.*www.*IN.*A/s|\(.*\)|;\1|" -e "/.*www.*IN.*TXT/s|\(.*\)|;\1|" $DNS_DB_EXTERNAL

	# Update serial and flush cache
	dns_update_serial "$DNS_DB_INTERNAL $DNS_DB_INTERNALREVERSE $DNS_DB_EXTERNAL"
	flush_dns_cache $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN
    fi
    
    init_process '/etc/init.d/bind9' 'reload'
fi
    
##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' -a $DOMAIN != $SYSTEM_ANCHOR_DOMAIN ]; then
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias"
    fi
fi

################
##### HERA #####
################
if [ $SHORT_NAME == 'hera' -a $DOMAIN != $SYSTEM_ANCHOR_DOMAIN ]; then
    POSTFIX_CONFIG_FOLDER=/etc/postfix
    POSTFIX_MAIN=$POSTFIX_CONFIG_FOLDER/main.cf
    POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
    POSTFIX_ALIASES=/etc/aliases

    # Update postfix main.cf
    if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' ]; then
	sed -i 's|^virtual_alias_maps|#virtual_alias_maps|' $POSTFIX_MAIN
    elif [ $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' ]; then
	sed -i 's|^#virtual_alias_maps|virtual_alias_maps|' $POSTFIX_MAIN
    elif [ $NEW_CONFIG_VERSION == '2.2' -o $NEW_CONFIG_VERSION == '2.3' ]; then
	sed -i "s|virtual_mailbox_domains\ =\ .*|virtual_mailbox_domains\ =\ $OLD_EMAIL_DOMAIN,\ $NEW_EMAIL_DOMAIN|" $POSTFIX_MAIN
	sed -i "s|relay_domains\ =\ .*|relay_domains\ =\ lists.$OLD_EMAIL_DOMAIN,\ lists.$NEW_EMAIL_DOMAIN|" $POSTFIX_MAIN
	echo -e "lists.$NEW_EMAIL_DOMAIN\tmailman:" >> $POSTFIX_TRANSPORT
	postmap $POSTFIX_TRANSPORT
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|" $POSTFIX_ALIASES
	postalias $POSTFIX_ALIASES
    elif [ $NEW_CONFIG_VERSION == '2.2to1.1' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	sed -i "s|virtual_mailbox_domains\ =\ .*|virtual_mailbox_domains\ =\ $NEW_EMAIL_DOMAIN,\ $NEW_EMAIL_DOMAIN|" $POSTFIX_MAIN
	sed -i "s|relay_domains\ =\ .*|relay_domains\ =\ lists.$NEW_EMAIL_DOMAIN|" $POSTFIX_MAIN
	sed -i "/lists.$OLD_EMAIL_DOMAIN/d" $POSTFIX_TRANSPORT
	postmap $POSTFIX_TRANSPORT
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|" $POSTFIX_ALIASES
	postalias $POSTFIX_ALIASES	
    fi
    init_process '/etc/init.d/postfix' 'reload'

    # Update dk-filter and dkim-filter
    DK_FILTER=/etc/default/dk-filter
    DKIM_FILTER=/etc/dkim-filter.conf
    if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' -o $NEW_CONFIG_VERSION == '2.2' -o $NEW_CONFIG_VERSION == '2.3' ]; then
	sed -i "s| $OLD_EMAIL_DOMAIN,lists.$OLD_EMAIL_DOMAIN | $OLD_EMAIL_DOMAIN,lists.$OLD_EMAIL_DOMAIN,$NEW_EMAIL_DOMAIN,lists.$NEW_EMAIL_DOMAIN |" $DK_FILTER
	sed -i "/Domain.*$OLD_EMAIL_DOMAIN/s|Domain.*|Domain\t\t\t$OLD_EMAIL_DOMAIN,lists.$OLD_EMAIL_DOMAIN,$NEW_EMAIL_DOMAIN,lists.$NEW_EMAIL_DOMAIN|" $DKIM_FILTER
    elif [ $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' -o $NEW_CONFIG_VERSION == '2.2to1.1' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	sed -i "s| $NEW_EMAIL_DOMAIN,lists.$NEW_EMAIL_DOMAIN,$OLD_EMAIL_DOMAIN,lists.$OLD_EMAIL_DOMAIN | $NEW_EMAIL_DOMAIN,lists.$NEW_EMAIL_DOMAIN |" $DK_FILTER
	sed -i "/Domain.*$NEW_EMAIL_DOMAIN/s|Domain.*|Domain\t\t\t$NEW_EMAIL_DOMAIN,lists.$NEW_EMAIL_DOMAIN|" $DKIM_FILTER
    fi
    init_process '/etc/init.d/dk-filter' 'restart'
    init_process '/etc/init.d/dkim-filter' 'restart'
    
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	# Change URL for mailing lists
	hasCapability MailingLists
	if [ $? -eq 0 ]; then
	    MAILMAN_FOLDER=/var/lib/mailman
	    for LIST in `ls $MAILMAN_FOLDER/lists`; do
		$MAILMAN_FOLDER/bin/withlist -l -r fix_url $LIST -u lists.$NEW_EMAIL_DOMAIN
	    done
	fi

        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias"
    fi

    # Sync email
    if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' -o $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' ]; then
	# Check if IMAPSYNC is installed, if not then install it.
	which imapsync
	[ $? -ne 0 ] && aptGetInstall imapsync

	for (( i=0; i<${#USERNAMES[@]}; i++ )); do
	    USERNAME=${USERNAMES[$i]}
	    EMAIL_PREFIX=${EMAIL_PREFIXES[$i]}
	    PASSWORD=${PASSWORDS[$i]}
	
  	    # Determine Mail Login.
	    determine_mail_login $USERNAME $EMAIL_PREFIX $NEW_EMAIL_DOMAIN
	    echo "$USERNAME | EMAIL $EMAIL_PREFIX@$NEW_EMAIL_DOMAIN | MAIL_LOGIN $MAIL_LOGIN"
	    
	    # We use localhost as imap server because at this point, the cloud dns is changed to point imap.cloud.newvirtualorgs.net -> imap.externalserver.com
	    if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' ]; then
		imapsync --host1 localhost --user1 $USERNAME --password1 $PASSWORD --authmech1 PLAIN --host2 $NEW_IMAP_SERVER --user2 $MAIL_LOGIN --password2 $PASSWORD --authmech2 PLAIN >/dev/null
	    elif [ $NEW_CONFIG_VERSION == '2.11to1.1' ]; then
		imapsync --host1 $OLD_IMAP_SERVER --user1 $USERNAME --password1 $PASSWORD --authmech1 PLAIN --host2 localhost --user2 $MAIL_LOGIN --password2 $PASSWORD --authmech2 PLAIN >/dev/null
	    elif [ $NEW_CONFIG_VERSION == '2.12to1.1' ]; then
		imapsync --host1 $OLD_IMAP_SERVER --user1 $EMAIL_PREFIX@$OLD_EMAIL_DOMAIN --password1 $PASSWORD --authmech1 PLAIN --host2 localhost --user2 $MAIL_LOGIN --password2 $PASSWORD --authmech2 PLAIN >/dev/null
	    fi
	done
    fi
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)

    hasCapability Vtiger
    if [ $? -eq 0 ]; then
	for (( i=0; i<${#USERNAMES[@]}; i++ )); do
	    USERNAME=${USERNAMES[$i]}
	    EMAIL_PREFIX=${EMAIL_PREFIXES[$i]}
	    
	    # Determine Mail Login.
	    determine_mail_login $USERNAME $EMAIL_PREFIX $NEW_EMAIL_DOMAIN
	    echo "$USERNAME | EMAIL $EMAIL_PREFIX@$NEW_EMAIL_DOMAIN | MAIL_LOGIN $MAIL_LOGIN"
	    
	    # Update vtiger_mail_accounts.
	    echo "UPDATE vtiger_mail_accounts SET mail_username = '$MAIL_LOGIN' WHERE user_id = (SELECT id FROM vtiger_users WHERE user_name = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger

	    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
 	        # Update imap server hostname.
		echo "UPDATE vtiger_mail_accounts SET mail_servername = 'imap.$NEW_ALIAS_DOMAIN' WHERE user_id = (SELECT id FROM vtiger_users WHERE user_name = '$USERNAME');" | mysql -uroot -p$DB_PASSWORD_MYSQL vtiger
	    fi
	done
    fi

    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	hasCapability Drupal
	if [ $? -eq 0 ]; then
	    echo "UPDATE drupal_domain_alias SET pattern = REPLACE(pattern, '$OLD_ALIAS_DOMAIN', '$NEW_ALIAS_DOMAIN');" | mysql -uroot -p$DB_PASSWORD_MYSQL drupal
	fi
    fi
fi

####################
##### POSEIDON #####
####################
if [ $SHORT_NAME == 'poseidon' ]; then    
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias"
    fi
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias"
    fi
fi

###################
##### GAIA #####
###################
if [ $SHORT_NAME == 'gaia' ]; then
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
        # Updating apache2 sites.
	update_apache2_sites $OLD_EMAIL_DOMAIN $NEW_EMAIL_DOMAIN "ServerAdmin ServerAlias"
    fi
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    for (( i=0; i<${#USERNAMES[@]}; i++ )); do
	USERNAME=${USERNAMES[$i]}
	EMAIL_PREFIX=${EMAIL_PREFIXES[$i]}
	PASSWORD=${PASSWORDS[$i]}
	
	# Determine Mail Login.
	determine_mail_login $USERNAME $EMAIL_PREFIX $NEW_EMAIL_DOMAIN
	echo "$USERNAME | EMAIL $EMAIL_PREFIX@$NEW_EMAIL_DOMAIN | MAIL_LOGIN $MAIL_LOGIN"

	# User home directory
	USER_HOME=/home/$USERNAME
	
	# Get User Fullname and Cloud Name.
	kinit -k -t $ESERIMAN_HOME/keytabs/eseriman-admin.keytab eseriman/admin
	FULL_NAME=$(ldapsearch -u "uid=$USERNAME" 2>/dev/null | grep displayName | sed -e "s|displayName: ||")
	kdestroy
	CLOUD_NAME=$(echo $(hostname -d) | sed -e "s|.$SYSTEM_ANCHOR_DOMAIN||" | tr '[:lower:]' '[:upper:]')
	
	# Kill Evolution and Gconf.
	evolution_pid=$(ps -C evolution -o pid= -o ruser= | grep $USERNAME | awk '{print $1}')
	if [[ $evolution_pid -ne '' ]]; then
	    kill -9 $evolution_pid
	fi
	gconfd_pid=$(ps -C gconfd-2 -o pid= -o ruser= | grep $USERNAME | awk '{print $1}')
	if [[ $gconfd_pid -ne '' ]]; then
	    kill -9 $gconfd_pid
	fi
	
	# Set Evolution gconftool-2 settings.
	if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' ]; then
	    URL_IMAP="imap://$MAIL_LOGIN_ESCAPED@imap.$NEW_ALIAS_DOMAIN/"
	    SAVE_PASSWORD="true"
	elif [ $NEW_CONFIG_VERSION == '2.11to1.1' -o $NEW_CONFIG_VERSION == '2.12to1.1' -o $NEW_CONFIG_VERSION == '2.2to1.1' -o $NEW_CONFIG_VERSION == '2.3to1.1' -o $NEW_CONFIG_VERSION == '2.2' -o $NEW_CONFIG_VERSION == '2.3' ]; then
	    URL_IMAP="imap://$MAIL_LOGIN_ESCAPED\;auth=GSSAPI@imap.$NEW_ALIAS_DOMAIN/"
	    SAVE_PASSWORD="false"
	fi
	URL_SMTP="smtp://$USERNAME\;auth=GSSAPI@smtp.$NEW_ALIAS_DOMAIN:587/"
	FOLDER_DRAFTS="imap://$MAIL_LOGIN_ESCAPED@imap.$NEW_ALIAS_DOMAIN/Drafts"
	FOLDER_SENT="imap://$MAIL_LOGIN_ESCAPED@imap.$NEW_ALIAS_DOMAIN/Sent"
	su - -c "gconftool-2 --set /apps/evolution/mail/accounts --type=list --list-type=string '[<?xml version=\"1.0\"?><account name=\"$EMAIL_PREFIX@$NEW_EMAIL_DOMAIN\" uid=\"1337374872.661.24\" enabled=\"true\"><identity><name>$FULL_NAME</name><addr-spec>$EMAIL_PREFIX@$NEW_EMAIL_DOMAIN</addr-spec><reply-to>$EMAIL_PREFIX@$NEW_EMAIL_DOMAIN</reply-to><organization>$CLOUD_NAME</organization><signature uid=\"\"/></identity><source save-passwd=\"$SAVE_PASSWORD\" keep-on-server=\"false\" auto-check=\"true\" auto-check-timeout=\"5\"><url>$URL_IMAP\;use_ssl=always\;command=ssh%20-C%20-l%20%25u%20%25h%20exec%20/usr/sbin/imapd\;imap_custom_headers\;filter</url></source><transport save-passwd=\"false\"><url>$URL_SMTP\;use_ssl=when-possible</url></transport><drafts-folder>$FOLDER_DRAFTS</drafts-folder><sent-folder>$FOLDER_SENT</sent-folder><auto-cc always=\"false\"><recipients></recipients></auto-cc><auto-bcc always=\"false\"><recipients></recipients></auto-bcc><receipt-policy policy=\"never\"/><pgp encrypt-to-self=\"false\" always-trust=\"false\" always-sign=\"false\" no-imip-sign=\"false\"/><smime sign-default=\"false\" encrypt-default=\"false\" encrypt-to-self=\"false\"/></account>]'" $USERNAME
	
	# Update passwordless keyrings
	DEFAULT_KEYRING_FILE=$USER_HOME/.gnome2/keyrings/default.keyring
	while grep -i '\[0\]' $DEFAULT_KEYRING_FILE >/dev/null; do
            LINE_START=($(grep -in '\[0\]' $DEFAULT_KEYRING_FILE | sed -e 's|\:\[0\]||'))
            LINE_START=$((${LINE_START[0]}-1))
            LINE_END=$(($LINE_START+28))
            awk -v m=$LINE_START -v n=$LINE_END 'm <= NR && NR <= n {next} {print}' $DEFAULT_KEYRING_FILE > $DEFAULT_KEYRING_FILE.tmp
            mv $DEFAULT_KEYRING_FILE.tmp $DEFAULT_KEYRING_FILE
	    # Remove trailing newline characters.
	    printf '%s\n' "$(cat $DEFAULT_KEYRING_FILE)" > $DEFAULT_KEYRING_FILE
	    chown $USERNAME:$USERNAME $DEFAULT_KEYRING_FILE
	done
	
	if [ $NEW_CONFIG_VERSION == '2.11' -o $NEW_CONFIG_VERSION == '2.12' ]; then
	    echo -e "\n[0]\nitem-type=0\ndisplay-name=imap://$MAIL_LOGIN_ESCAPED@$OLD_IMAP_SERVER/\nsecret=$PASSWORD\nmtime=1292615328\nctime=0\n\n[0:attribute0]\nname=application\ntype=string\nvalue=Evolution\n\n[0:attribute1]\nname=protocol\ntype=string\nvalue=imap\n\n[0:attribute2]\nname=server\ntype=string\nvalue=$OLD_IMAP_SERVER\n\n[0:attribute3]\nname=user\ntype=string\nvalue=$MAIL_LOGIN\n" >> $DEFAULT_KEYRING_FILE
	fi
	
	# Expand the INBOX mailbox/folder on Evolution start.
	echo -e "<?xml version=\"1.0\"?>\n<tree-state>\n  <node name=\"local\" expand=\"false\"/>\n  <node name=\"vfolder\" expand=\"false\"/>\n  <node name=\"1337374872.661.24\" expand=\"true\"><node name=\"INBOX\" expand=\"false\"/></node>\n  <selected uri=\"imap://$MAIL_LOGIN_ESCAPED@$OLD_IMAP_SERVER/INBOX\"/>\n</tree-state>" > $USER_HOME/.evolution/mail/config/folder-tree-expand-state.xml
	
	rm -rf $USER_HOME/.evolution/mail/config/et-expanded-imap*
	
	# Change Email Domain in all user addresses in LDAP (mail, eseriMailAlternateAddress, eseriMailSenderAddress)
	su - -c "$ESERIMAN_HOME/bin/eseriChangeUserEmailDomainLDAP \"$USERNAME\" \"$NEW_EMAIL_DOMAIN\" \"ALL\"" eseriman
	
	# Update domain
	if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
      	    # Gconf
	    GCONFTOOLDUMP_FILE=$USER_HOME/gconftooldump.xml
	    su - -c "gconftool-2 --dump /apps > $GCONFTOOLDUMP_FILE" $USERNAME
	    sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $GCONFTOOLDUMP_FILE
	    su - -c "gconftool-2 --load $GCONFTOOLDUMP_FILE" $USERNAME
	    rm $GCONFTOOLDUMP_FILE
	    # Keyring
	    sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $USER_HOME/.gnome2/keyrings/default.keyring
	    # Evolution
	    sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $USER_HOME/.evolution/mail/config/folder-tree-expand-state.xml
	    # Personal Wiki
	    sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $USER_HOME/.gnome2/panel2.d/default/launchers/personal-wiki.desktop
	    # Gnome-panel
	    gnome_panel_pid=$(ps -C gnome-panel -o pid= -o ruser= | grep $USERNAME | awk '{print $1}')
	    if [[ $gnome_panel_pid -ne '' ]]; then
		# Reload gnome-panel
		su - -c "killall gnome-panel" $USERNAME
		su - -c "/usr/local/share/CirrusOpen/CirrusOpenGnomeAppletReload &" $USERNAME
	    fi
	    # Pidgin
	    pidgin_pid=$(ps -C pidgin -o pid= -o ruser= | grep $USERNAME | awk '{print $1}')
	    if [[ $pidgin_pid -ne '' ]]; then
	        # Kill Pidin.
		kill -9 $pidgin_pid
	    fi
	    [ -f $USER_HOME/.purple/blist.xml ] && sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $USER_HOME/.purple/blist.xml
	    sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" $USER_HOME/.purple/accounts.xml
	    # Pidgin certificate
	    cp -p $USER_HOME/.purple/certificates/x509/tls_peers/xmpp.$OLD_EMAIL_DOMAIN $USER_HOME/.purple/certificates/x509/tls_peers/xmpp.$NEW_EMAIL_DOMAIN
	fi
    done
    
    if [ $NEW_CONFIG_VERSION == '2.3' -o $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	if [ $NEW_CONFIG_VERSION == '2.3' ]; then
	    TRUSTED_URIS="$OLD_EMAIL_DOMAIN, $NEW_EMAIL_DOMAIN"
	elif [ $NEW_CONFIG_VERSION == '2.3to1.1' ]; then
	    TRUSTED_URIS="$NEW_EMAIL_DOMAIN"
	fi
	
	# Update firefox trusted uris
	sed -i "/pref(\"network.negotiate-auth.trusted-uris\"/s|.*|pref(\"network.negotiate-auth.trusted-uris\", \"$TRUSTED_URIS\");|" /usr/lib/firefox*/defaults/pref/firefox.js /etc/firefox/pref/firefox.js
	# Update application shortcuts
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" /usr/local/share/applications/*
	# Update favorites menu
	sed -i "s|$OLD_EMAIL_DOMAIN|$NEW_EMAIL_DOMAIN|g" /usr/share/gconf/defaults/99_CirrusOpen-gnomenu
	update-gconf-defaults
    fi
fi

exit 0
