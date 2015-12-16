#!/bin/bash
#
# System Anchor Config Deploy Script - v1.1
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

OLD_SYSTEM_ANCHOR_DOMAIN=$(getParameter old_system_anchor_domain)
OLD_SYSTEM_ANCHOR_IP=$(getParameter old_system_anchor_ip)
OLD_SYSTEM_ANCHOR_NETMASK=$(getParameter old_system_anchor_netmask)
NEW_SYSTEM_ANCHOR_DOMAIN=$(getParameter new_system_anchor_domain)
NEW_SYSTEM_ANCHOR_IP=$(getParameter new_system_anchor_ip)
NEW_SYSTEM_ANCHOR_NETMASK=$(getParameter new_system_anchor_netmask)
OLD_SHORT_DOMAIN=${OLD_SYSTEM_ANCHOR_DOMAIN%%.*}
NEW_SHORT_DOMAIN=${NEW_SYSTEM_ANCHOR_DOMAIN%%.*}
OLD_LDAP_BASE=$LDAP_BASE
NEW_LDAP_BASE=""
NEW_TMP_DOMAIN=$NEW_SYSTEM_ANCHOR_DOMAIN
while true; do
    NEW_SUBDOMAIN=${NEW_TMP_DOMAIN%%.*}
    [ -z $NEW_LDAP_BASE ] && NEW_LDAP_FIRST_DC=${NEW_SUBDOMAIN} || NEW_LDAP_BASE="${NEW_LDAP_BASE},"
    NEW_LDAP_BASE="${NEW_LDAP_BASE}dc=${NEW_SUBDOMAIN}"
    [ $NEW_TMP_DOMAIN = ${NEW_TMP_DOMAIN#*.} ] && break
    NEW_TMP_DOMAIN=${NEW_TMP_DOMAIN#*.}
done

# Mark start point in log file.
echo "System Anchor Config $NEW_SYSTEM_ANCHOR_DOMAIN $NEW_SYSTEM_ANCHOR_IP $NEW_SYSTEM_ANCHOR_NETMASK"

flush_dns_cache()
{
    # Flush cache for old & new domain.
    rndc flushname $1
    rndc flushname $2
}

# Common folders
OPENVZ_CONFIG_FOLDER=/etc/vz
SHOREWALL_CONFIG_FOLDER=/etc/shorewall
CA_CERT_FOLDER=/usr/share/ca-certificates
SSL_CONFIG_FOLDER=/etc/ssl
SSL_CERT_FOLDER=$SSL_CONFIG_FOLDER/certs
SSL_KEY_FOLDER=$SSL_CONFIG_FOLDER/private
BIND_CONFIG_FOLDER=/etc/bind
APACHE2_CONFIG_FOLDER=/etc/apache2
ESERIMAN_HOME_FOLDER=/var/lib/eseriman
SSMTP_CONFIG_FOLDER=/etc/ssmtp
POSTFIX_CONFIG_FOLDER=/etc/postfix
DOVECOT_CONFIG_FOLDER=/etc/dovecot
MAILMAN_CONFIG_FOLDER=/etc/mailman
DSPAM_CONFIG_FOLDER=/etc/dspam
ORANGEHRM_FOLDER=/var/lib/orangehrm
SQLLEDGER_FOLDER=/var/lib/sql-ledger
VTIGERCRM_FOLDER=/var/lib/vtigercrm
TIMESHEET_FOLDER=/var/lib/timesheet
TRAC_FOLDER=/var/lib/trac
NUXEO_FOLDER=/var/lib/nuxeo
OPENFIRE_CONFIG_FOLDER=/etc/openfire
JAVA_CONFIG_FOLDER=/etc/java-6-sun
SOGO_FOLDER=/var/lib/freebusy
REDMINE_CONFIG_FOLDER=/etc/redmine
REDMINE_FOLDER=/usr/share/redmine
PHPSCHEDULEIT_FOLDER=/var/lib/phpscheduleit

replace_anchor_domain()
{
    sed -i -e "s|$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN)|$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)|g" -e "s|$(to_upper $OLD_SYSTEM_ANCHOR_DOMAIN)|$(to_upper $NEW_SYSTEM_ANCHOR_DOMAIN)|g" $1
}

replace_ldap_base()
{
    sed -i "s|$OLD_LDAP_BASE|$NEW_LDAP_BASE|g" $1
}

replace_short_domain()
{
    sed -i -e "s|$(to_lower $OLD_SHORT_DOMAIN)|$(to_lower $NEW_SHORT_DOMAIN)|g" -e "s|$(to_upper $OLD_SHORT_DOMAIN)|$(to_upper $NEW_SHORT_DOMAIN)|g" $1
}

replace_anchor_ip()
{
    sed -i "s/$(echo "$OLD_SYSTEM_ANCHOR_IP" | sed 's|\.|\\\.|g')/$(echo "$NEW_SYSTEM_ANCHOR_IP" | sed 's|\.|\\\.|g')/g" $1
}

replace_anchor_netmask()
{
    sed -i "s/$(echo "$OLD_SYSTEM_ANCHOR_NETMASK" | sed 's|\.|\\\.|g')/$(echo "$NEW_SYSTEM_ANCHOR_NETMASK" | sed 's|\.|\\\.|g')/g" $1
}

remove_old_cert_key()
{
    if [ $OLD_SYSTEM_ANCHOR_DOMAIN != $NEW_SYSTEM_ANCHOR_DOMAIN ]; then
	rm -f $SSL_CERT_FOLDER/$1.pem
	rm -f $SSL_KEY_FOLDER/$1.pem
    fi
}

if [ $(hostname -s) == 'server' ]; then
    ##################
    ##### SERVER #####
    ##################
    replace_anchor_domain "/etc/resolv.conf 
/etc/sysconfig/network 
$OPENVZ_CONFIG_FOLDER/conf/*"
    replace_anchor_ip "$OPENVZ_CONFIG_FOLDER/conf/1003.conf 
$SHOREWALL_CONFIG_FOLDER/orgs.local/VZ/rules 
$SHOREWALL_CONFIG_FOLDER/orgs.local/VZ/proxyarp"
    replace_anchor_netmask "$OPENVZ_CONFIG_FOLDER/conf/1003.conf"
    
    init_process '/etc/init.d/shorewall' 'restart'
else
    ######################
    ##### CONTAINERS #####
    #####################
    if [ $OLD_SYSTEM_ANCHOR_DOMAIN != $NEW_SYSTEM_ANCHOR_DOMAIN ]; then
	rm -rf $CA_CERT_FOLDER/$OLD_SYSTEM_ANCHOR_DOMAIN
    fi
    
    replace_anchor_domain "/etc/krb5.conf 
/etc/ldap/ldap.conf 
/etc/ca-certificates.conf 
/etc/mailname "
    replace_ldap_base "/etc/ldap/ldap.conf"

    if [ $SHORT_NAME != 'hera' ]; then
	replace_anchor_domain "$SSMTP_CONFIG_FOLDER/ssmtp.conf 
$SSMTP_CONFIG_FOLDER/revaliases"
	replace_short_domain "$SSMTP_CONFIG_FOLDER/revaliases"
    fi
    
    update-ca-certificates
fi

################
##### ZEUS #####
################
if [ $SHORT_NAME == 'zeus' ]; then
    if [ $OLD_SYSTEM_ANCHOR_DOMAIN != $NEW_SYSTEM_ANCHOR_DOMAIN ]; then
	mv $BIND_CONFIG_FOLDER/db.$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN).internal $BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internal
	mv $BIND_CONFIG_FOLDER/db.$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN).internalreverse $BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internalreverse
	mv $BIND_CONFIG_FOLDER/db.$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN).external $BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).external
	mv $BIND_CONFIG_FOLDER/zones/internal/$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN).conf $BIND_CONFIG_FOLDER/zones/internal/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).conf
	mv $BIND_CONFIG_FOLDER/zones/external/$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN).conf $BIND_CONFIG_FOLDER/zones/external/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).conf
    fi

    replace_anchor_domain "$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internal 
$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internalreverse 
$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).external 
$BIND_CONFIG_FOLDER/named.conf.local 
$BIND_CONFIG_FOLDER/named.conf.external 
$BIND_CONFIG_FOLDER/named.conf.internal 
$BIND_CONFIG_FOLDER/zones/internal/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).conf 
$BIND_CONFIG_FOLDER/zones/external/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).conf "

    # Update serial
    dns_update_serial "$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internal"
    dns_update_serial "$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).internalreverse"
    dns_update_serial "$BIND_CONFIG_FOLDER/db.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).external"
    # Flush dns cache
    flush_dns_cache $OLD_SYSTEM_ANCHOR_DOMAIN $NEW_SYSTEM_ANCHOR_DOMAIN
fi
    
##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    remove_old_cert_key "ssl.$OLD_SYSTEM_ANCHOR_DOMAIN"
    replace_anchor_domain "$APACHE2_CONFIG_FOLDER/sites-available/*"
    replace_anchor_ip "$APACHE2_CONFIG_FOLDER/ports.conf 
$APACHE2_CONFIG_FOLDER/sites-available/* 
$SHOREWALL_CONFIG_FOLDER/rules 
$SHOREWALL_CONFIG_FOLDER/masq"
fi

##################
##### APOLLO #####
##################
if [ $SHORT_NAME == 'apollo' ]; then
    replace_anchor_domain "$APACHE2_CONFIG_FOLDER/sites-available/* 
/var/lib/backup/.duply/*/exclude 
/var/lib/backup/.duply/*/conf 
/etc/nagios3/nagios.cfg 
/etc/nagios3/cgi.cfg 
/etc/nagios3/conf.d/contacts_nagios2.cfg 
/etc/nagios3/servers/* 
/etc/nagios3/clouds/* 
/var/www/loginsite/cirrusopen_loginsite.conf"
    replace_short_domain "/etc/nagios3/clouds/$(to_lower $OLD_SHORT_DOMAIN).cfg"

    mv /etc/nagios3/clouds/$(to_lower $OLD_SHORT_DOMAIN).cfg /etc/nagios3/clouds/$(to_lower $NEW_SHORT_DOMAIN).cfg
    rm -f /etc/nagios3/conf.d/ngraph/serviceext/$(to_lower $OLD_SHORT_DOMAIN)_*.cfg
fi

##################
##### ATHENA #####
##################
if [ $SHORT_NAME == 'athena' ]; then
    SUPERUSER=$(getParameter manager_username)
    SUPERUSER_PASSWORD=$(getParameter manager_password)
    MASTER_PASSWORD_KRB5=$(getPassword MASTER_PASSWORD_KRB5)
    ADMIN_PASSWORD_KRB5=$(getPassword ADMIN_PASSWORD_KRB5)
    KRB5_CONFIG_FOLDER=/etc/krb5kdc
    KRB5_KADMIN_KEYTAB=${KRB5_CONFIG_FOLDER}/kadm5.keytab

    init_process '/etc/init.d/krb5-kdc' 'stop'
    init_process '/etc/init.d/krb5-admin-server' 'stop'

    # Destroy old database/
    kdb5_util -r $(to_upper $OLD_SYSTEM_ANCHOR_DOMAIN) destroy -f
    rm -f $KRB5_KADMIN_KEYTAB
    rm -f /tmp/*.keytab

    replace_anchor_domain "$KRB5_CONFIG_FOLDER/kadm5.acl 
$KRB5_CONFIG_FOLDER/kdc.conf"

    # Create new database
    kdb5_util -r $(to_upper $NEW_SYSTEM_ANCHOR_DOMAIN) -P $MASTER_PASSWORD_KRB5 create -s
    kadmin.local -q "ktadd -k $KRB5_KADMIN_KEYTAB kadmin/admin kadmin/changepw"

    # Add policies for the different principal types
    kadmin.local -q "addpol users"
    kadmin.local -q "addpol admins"
    kadmin.local -q "addprinc -policy admins -pw $ADMIN_PASSWORD_KRB5 root/admin"
    kadmin.local -q "addprinc -randkey HTTP/apollo.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/apollo.apache2.keytab HTTP/apollo.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey host/aphrodite.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/aphrodite.host.keytab host/aphrodite.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey ldap/aphrodite.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/aphrodite.slapd.keytab ldap/aphrodite.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey host/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/hera.host.keytab host/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey imap/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/hera.dovecot.keytab imap/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey smtp/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/hera.dovecot.keytab smtp/hera.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey HTTP/poseidon.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/poseidon.apache2.keytab HTTP/poseidon.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey xmpp/erato.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/erato.openfire.keytab xmpp/erato.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey HTTP/gaia.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/gaia.apache2.keytab HTTP/gaia.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey HTTP/trident.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/trident.apache2.keytab HTTP/trident.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey host/chaos.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "ktadd -k /tmp/chaos.host.keytab host/chaos.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)"
    kadmin.local -q "addprinc -randkey eseriman/admin"
    kadmin.local -q "ktadd -k /tmp/chaos.eseriman_admin.keytab eseriman/admin"
    kadmin.local -q "addprinc -policy users -pw $SUPERUSER_PASSWORD $SUPERUSER"

    replace_ldap_base "/etc/ldap/slapd.d/cn=config/olcDatabase={1}hdb.ldif"
    # Dump LDAP database dump
    /usr/sbin/slapcat > /tmp/ldapdump
    # Replace Values
    replace_anchor_domain "/tmp/ldapdump"
    replace_ldap_base "/tmp/ldapdump"
    replace_short_domain "/tmp/ldapdump"
    # Load the updated dump
    init_process '/etc/init.d/slapd' 'stop'
    rm -rf /var/lib/ldap/*
    /usr/sbin/slapadd -l /tmp/ldapdump
    chown -R openldap:openldap /var/lib/ldap
    init_process '/etc/init.d/slapd' 'start';
fi

#####################
##### APHRODITE #####
#####################
if [ $SHORT_NAME == 'aphrodite' ]; then
    remove_old_cert_key "aphrodite.$OLD_SYSTEM_ANCHOR_DOMAIN"
    replace_anchor_domain "/etc/nagios/nrpe_local.cfg 
/etc/ldap/slapd.d/cn=config.ldif"
    replace_ldap_base "/etc/nagios/nrpe_local.cfg 
/etc/ldap/slapd.d/cn=config.ldif 
/etc/ldap/slapd.d/cn=config/olcDatabase={1}hdb.ldif"

    # Dump LDAP database dump
    /usr/sbin/slapcat > /tmp/ldapdump
    # Replace Values
    replace_anchor_domain "/tmp/ldapdump"
    replace_ldap_base "/tmp/ldapdump"
    replace_short_domain "/tmp/ldapdump"
    # Load the updated dump
    init_process '/etc/init.d/slapd' 'stop'
    rm -rf /var/lib/ldap/*
    /usr/sbin/slapadd -l /tmp/ldapdump
    chown -R openldap:openldap /var/lib/ldap
 
    # To avoid the "tls init def ctx failed 207" error
    # gnutls being unable to use the key generated by openssl to read the cert generated by openssl
    aptGetInstall gnutls-bin
    certtool -k < $SSL_KEY_FOLDER/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem > /tmp/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem
    mv /tmp/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem $SSL_KEY_FOLDER/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem
    chmod 640 $SSL_KEY_FOLDER/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem
    chown root:ssl-cert $SSL_KEY_FOLDER/aphrodite.$NEW_SYSTEM_ANCHOR_DOMAIN.pem
    init_process '/etc/init.d/slapd' 'start';
fi

#################
##### HADES #####
#################
if [ $SHORT_NAME == 'hades' ]; then
    DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)
    
    # Nagios
    replace_anchor_domain "/etc/nagios/nrpe_local.cfg"

    # PgSQL dump
    su - -c "pg_dumpall -c -U postgres" postgres > /tmp/postgresdump
    # Dump prime database, so that we can load it back.
    su - -c "pg_dump prime" postgres > /tmp/primedump
    replace_anchor_domain "/tmp/postgresdump"
    replace_ldap_base "/tmp/postgresdump"
    replace_short_domain "/tmp/postgresdump"
    # Load dump and Restart Process
    init_process '/etc/init.d/postgresql-8.4' 'restart'
    su -c 'psql -f /tmp/postgresdump postgres' postgres
    # Openfire changes that are not reflected when the db dump is loaded.
    su - -c "echo UPDATE ofproperty SET propvalue = REPLACE\(propvalue,\'$OLD_SYSTEM_ANCHOR_DOMAIN\',\'$NEW_SYSTEM_ANCHOR_DOMAIN\'\) WHERE name = \'ldap.host\' | psql -d openfire" postgres
    su - -c "echo UPDATE ofproperty SET propvalue = REPLACE\(propvalue,upper\(\'$OLD_SYSTEM_ANCHOR_DOMAIN\'\),upper\(\'$NEW_SYSTEM_ANCHOR_DOMAIN\'\)\) WHERE name = \'sasl.realm\' | psql -d openfire" postgres
    su - -c "echo UPDATE ofproperty SET propvalue = REPLACE\(propvalue,\'$OLD_LDAP_BASE\',\'$NEW_LDAP_BASE\'\) WHERE name = \'ldap.baseDN\' OR name = \'ldap.adminDN\' | psql -d openfire" postgres
    # Drop new prime database and load from the dump file created before anchor domain changes.
    init_process '/etc/init.d/postgresql-8.4' 'restart'
    su -c 'dropdb prime' postgres
    su -c 'createdb prime -O prime_owner' postgres
    su -c 'psql -f /tmp/primedump prime' postgres    
    init_process '/etc/init.d/postgresql-8.4' 'restart';

    # MySQL dump
    mysqldump --user=root --password=$DB_PASSWORD_MYSQL -A > /tmp/mysqldump
    replace_anchor_domain "/tmp/mysqldump"
    replace_ldap_base "/tmp/mysqldump"
    replace_short_domain "/tmp/mysqldump"
    # Load dump and Restart Process
    init_process '/etc/init.d/mysql restart'
    mysql --user=root --password=$DB_PASSWORD_MYSQL -A < /tmp/mysqldump
    init_process '/etc/init.d/mysql' 'restart';
fi


################
##### HERA #####
################
if [ $SHORT_NAME == 'hera' ]; then
    DOVECOT_PASSWORD_PROXY=$(getPassword DOVECOT_PASSWORD_PROXY)

    remove_old_cert_key "imap.$OLD_SYSTEM_ANCHOR_DOMAIN"
    remove_old_cert_key "smtp.$OLD_SYSTEM_ANCHOR_DOMAIN"
    remove_old_cert_key "dkim.$OLD_SYSTEM_ANCHOR_DOMAIN"

    cp $SSL_KEY_FOLDER/dkim.$NEW_SYSTEM_ANCHOR_DOMAIN.pem /etc/mail/dkim.key
    
    replace_anchor_domain "/etc/ldap.conf 
/etc/dkim-filter.conf 
/etc/default/dk-filter 
/etc/aliases 
$APACHE2_CONFIG_FOLDER/sites-available/* 
$DOVECOT_CONFIG_FOLDER/dovecot-sql.conf 
$DOVECOT_CONFIG_FOLDER/dovecot-ldap.conf 
$DOVECOT_CONFIG_FOLDER/dovecot.conf 
$MAILMAN_CONFIG_FOLDER/mm_cfg.py 
$DSPAM_CONFIG_FOLDER/dspam.conf 
$POSTFIX_CONFIG_FOLDER/ldap/* 
$POSTFIX_CONFIG_FOLDER/transport 
$POSTFIX_CONFIG_FOLDER/relay_domains 
$POSTFIX_CONFIG_FOLDER/main.cf"
    
    replace_ldap_base "/etc/ldap.conf 
/etc/dkim-filter.conf 
/etc/default/dk-filter 
$DOVECOT_CONFIG_FOLDER/dovecot-ldap.conf 
$DOVECOT_CONFIG_FOLDER/dovecot.conf 
$MAILMAN_CONFIG_FOLDER/mm_cfg.py 
$DSPAM_CONFIG_FOLDER/dspam.conf 
$POSTFIX_CONFIG_FOLDER/ldap/* 
$POSTFIX_CONFIG_FOLDER/main.cf"
    
    replace_short_domain "/etc/aliases"
    
    postmap $POSTFIX_CONFIG_FOLDER/transport $POSTFIX_CONFIG_FOLDER/relay_domains
    postalias /etc/aliases

    # Change the password for the dovecot proxy user
    htpasswd -b -c -s $DOVECOT_CONFIG_FOLDER/passwd.masterusers proxy "$DOVECOT_PASSWORD_PROXY"
fi

####################
##### POSEIDON #####
####################
if [ $SHORT_NAME == 'poseidon' ]; then
    replace_anchor_domain "/etc/mediawiki/LocalSettings.php 
/var/www/acc/cirrusopen_accountmanager.conf 
/var/www/sysman/cirrusopen_systemmanager.conf 
$APACHE2_CONFIG_FOLDER/sites-available/* 
$ORANGEHRM_FOLDER/lib/confs/Conf.php 
$SQLLEDGER_FOLDER/users/members 
$SQLLEDGER_FOLDER/users/admin@sql-ledger.conf 
$VTIGERCRM_FOLDER/portal/PortalConfig.php 
$VTIGERCRM_FOLDER/user_privileges/user_privileges_5.php 
$VTIGERCRM_FOLDER/include/ldap/config.ldap.php 
$VTIGERCRM_FOLDER/config.inc.php 
$TIMESHEET_FOLDER/database_credentials.inc 
$TRAC_FOLDER/$(to_lower $OLD_SHORT_DOMAIN)/conf/trac.ini"

    replace_ldap_base "/etc/mediawiki/LocalSettings.php 
$VTIGERCRM_FOLDER/include/ldap/config.ldap.php 
$VTIGERCRM_FOLDER/config.inc.php"

    replace_short_domain "$APACHE2_CONFIG_FOLDER/sites-available/trac 
$SQLLEDGER_FOLDER/users/members 
$SQLLEDGER_FOLDER/users/admin@sql-ledger.conf 
$ESERIMAN_HOME_FOLDER/bin/sql-ledger-add-user 
$TRAC_FOLDER/$(to_lower $OLD_SHORT_DOMAIN)/apache/trac.wsgi 
$TRAC_FOLDER/$(to_lower $OLD_SHORT_DOMAIN)/conf/trac.ini"

    # Configure Trac
    mv /var/lib/trac/$(to_lower $OLD_SHORT_DOMAIN)/ /var/lib/trac/$(to_lower $NEW_SHORT_DOMAIN)/
fi

##################
##### CRONUS #####
##################
if [ $SHORT_NAME == 'cronus' ]; then
    KEYSTORE_PASSWORD_NUXEO_SYSTEM=$(getPassword KEYSTORE_PASSWORD_NUXEO_SYSTEM)
    
    # Delete old CA cert and import new CA cert - Java Keystore
    keytool -delete -noprompt -keystore $JAVA_CONFIG_FOLDER/security/cacerts -storepass "$KEYSTORE_PASSWORD_NUXEO_SYSTEM" -alias mykey
    keytool -import -noprompt -file $CA_CERT_FOLDER/$NEW_SYSTEM_ANCHOR_DOMAIN/CA.crt -storepass "$KEYSTORE_PASSWORD_NUXEO_SYSTEM" -keystore $JAVA_CONFIG_FOLDER/security/cacerts

    replace_anchor_domain "$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/datasources/default-repository-ds.xml 
$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/datasources/unified-nuxeo-ds.xml 
$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/datasources/nxtags-ds.xml 
$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/config/default-ldap-users-directory-bundle.xml 
$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/config/notification-config.xml 
$NUXEO_FOLDER/server/default/deploy/mail-service.xml 
$NUXEO_FOLDER/server/default/log/*"
    replace_ldap_base "$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/config/default-ldap-groups-directory-bundle.xml 
$NUXEO_FOLDER/server/default/deploy/nuxeo.ear/config/default-ldap-users-directory-bundle.xml"
fi

#################
##### ERATO #####
#################
if [ $SHORT_NAME == 'erato' ]; then
    KEYSTORE_PASSWORD_XMPP_SYSTEM=$(getPassword KEYSTORE_PASSWORD_XMPP_SYSTEM)
    KEYSTORE_PASSWORD_XMPP=$(getPassword KEYSTORE_PASSWORD_XMPP)
  
    remove_old_cert_key "xmpp.$OLD_SYSTEM_ANCHOR_DOMAIN"
    remove_old_cert_key "xmpp.${OLD_SYSTEM_ANCHOR_DOMAIN}_dsa"

    # Delete old CA cert and import new CA cert - Java Keystore
    keytool -delete -noprompt -keystore $JAVA_CONFIG_FOLDER/security/cacerts -storepass "$KEYSTORE_PASSWORD_XMPP_SYSTEM" -alias mykey
    keytool -import -noprompt -file $CA_CERT_FOLDER/$NEW_SYSTEM_ANCHOR_DOMAIN/CA.crt -storepass "$KEYSTORE_PASSWORD_XMPP_SYSTEM" -keystore $JAVA_CONFIG_FOLDER/security/cacerts

    # Delete old system anchor cert and import new system anchor cert - XMPP Keystore
    keytool -delete -noprompt -keystore $OPENFIRE_CONFIG_FOLDER/security/truststore -storepass "$KEYSTORE_PASSWORD_XMPP" -alias $OLD_SYSTEM_ANCHOR_DOMAIN    
    keytool -importcert -noprompt -file $CA_CERT_FOLDER/$NEW_SYSTEM_ANCHOR_DOMAIN/CA.crt -storepass "$KEYSTORE_PASSWORD_XMPP" -keystore $OPENFIRE_CONFIG_FOLDER/security/truststore -alias $NEW_SYSTEM_ANCHOR_DOMAIN

    # Export PKCS12 for certs
    openssl pkcs12 -export -in $SSL_CERT_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}.pem -inkey $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}.pem -out $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}.pkcs12 -passout "pass:pass"
    openssl pkcs12 -export -in $SSL_CERT_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}_dsa.pem -inkey $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}_dsa.pem -out $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}_dsa.pkcs12 -passout "pass:pass"
    
    # Delete old xmpp system anchor cert and import new xmpp system anchor cert - XMPP Keystore
    keytool -delete -noprompt -keystore $OPENFIRE_CONFIG_FOLDER/security/keystore -storepass "$KEYSTORE_PASSWORD_XMPP" -alias $(hostname -s).${OLD_SYSTEM_ANCHOR_DOMAIN}_1
    keytool -delete -noprompt -keystore $OPENFIRE_CONFIG_FOLDER/security/keystore -storepass "$KEYSTORE_PASSWORD_XMPP" -alias $(hostname -s).${OLD_SYSTEM_ANCHOR_DOMAIN}_2
    keytool -importkeystore -v -noprompt -deststorepass "$KEYSTORE_PASSWORD_XMPP" -destkeystore $OPENFIRE_CONFIG_FOLDER/security/keystore -srckeystore $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}.pkcs12 -srcstorepass "pass" -alias 1 -destalias $(hostname -s).${NEW_SYSTEM_ANCHOR_DOMAIN}_1 -srcstoretype PKCS12 -destkeypass "$KEYSTORE_PASSWORD_XMPP"
    keytool -importkeystore -v -noprompt -deststorepass "$KEYSTORE_PASSWORD_XMPP" -destkeystore $OPENFIRE_CONFIG_FOLDER/security/keystore -srckeystore $SSL_KEY_FOLDER/xmpp.${NEW_SYSTEM_ANCHOR_DOMAIN}_dsa.pkcs12 -srcstorepass "pass" -alias 1 -destalias $(hostname -s).${NEW_SYSTEM_ANCHOR_DOMAIN}_2 -srcstoretype PKCS12 -destkeypass "$KEYSTORE_PASSWORD_XMPP"

    replace_anchor_domain "/root/.pgpass 
$OPENFIRE_CONFIG_FOLDER/openfire.xml 
$OPENFIRE_CONFIG_FOLDER/gss.conf"
fi

###################
##### GAIA #####
###################
if [ $SHORT_NAME == 'gaia' ]; then
    replace_anchor_domain "$APACHE2_CONFIG_FOLDER/conf.d/sogo.conf 
$APACHE2_CONFIG_FOLDER/sites-available/sogo 
$DOVECOT_CONFIG_FOLDER/dovecot-ldap.conf 
$SOGO_FOLDER/index.php 
/home/sogo/GNUstep/Defaults/.GNUstepDefaults"
    replace_ldap_base "$APACHE2_CONFIG_FOLDER/sites-available/sogo 
$DOVECOT_CONFIG_FOLDER/dovecot-ldap.conf 
/home/sogo/GNUstep/Defaults/.GNUstepDefaults"
fi

###################
##### TRIDENT #####
###################
if [ $SHORT_NAME == 'trident' ]; then
    replace_anchor_domain "$APACHE2_CONFIG_FOLDER/sites-available/* 
$REDMINE_CONFIG_FOLDER/default/configuration.yml 
$REDMINE_CONFIG_FOLDER/default/database.yml 
$REDMINE_FOLDER/config/settings.yml 
$REDMINE_FOLDER/vendor/plugins/redmine_http_auth/lib/http_auth_patch.rb 
$PHPSCHEDULEIT_FOLDER/config/config.php"
    replace_short_domain "$ESERIMAN_HOME_FOLDER/bin/createPHPScheduleItUser.sh"
fi

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    SUPERUSER=$(getParameter manager_username)
    SUPERUSER_HOME_FOLDER=/home/$SUPERUSER
       
    # Kill Evolution and Gconf.
    evolution_pid=$(ps -C evolution -o pid= -o ruser= | grep $SUPERUSER | awk '{print $1}')
    if [[ $evolution_pid -ne '' ]]; then
        kill -9 $evolution_pid
    fi
    gconfd_pid=$(ps -C gconfd-2 -o pid= -o ruser= | grep $SUPERUSER | awk '{print $1}')
    if [[ $gconfd_pid -ne '' ]]; then
        kill -9 $gconfd_pid
    fi

    # Kill Pidgin
    pidgin_pid=$(ps -C pidgin -o pid= -o ruser= | grep $SUPERUSER | awk '{print $1}')
    if [[ $pidgin_pid -ne '' ]]; then
	kill -9 $pidgin_pid
    fi

    replace_anchor_domain "/etc/ldap.conf 
/etc/firefox/pref/firefox.js 
/etc/Muttrc 
/usr/share/gconf/defaults/99_CirrusOpen-gnomenu 
/usr/lib/firefox-24.1.1esr/defaults/pref/firefox.js 
/usr/local/share/applications/* 
/usr/local/share/CirrusOpen/CirrusOpenDSPAMTrain 
/usr/local/share/CirrusOpen/glade/CirrusOpenCloudManager.glade 
/var/lib/gconf/debian.defaults/%gconf-tree.xml 
$SUPERUSER_HOME_FOLDER/.gconfxml 
$SUPERUSER_HOME_FOLDER/.evolutionconf.xml 
$SUPERUSER_HOME_FOLDER/.purple/accounts.xml 
$SUPERUSER_HOME_FOLDER/.purple/blist.xml
$SUPERUSER_HOME_FOLDER/.mozilla/firefox/ifl4l6s1.default/sessionstore.js 
$SUPERUSER_HOME_FOLDER/.evolution/mail/local/Postmaster 
$SUPERUSER_HOME_FOLDER/.evolution/mail/config/folder-tree-expand-state.xml 
$SUPERUSER_HOME_FOLDER/.evolution/mail/imap/superuser@imap.$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN)/folders/INBOX/* 
$SUPERUSER_HOME_FOLDER/.gnome2/panel2.d/default/launchers/personal-wiki.desktop 
$SUPERUSER_HOME_FOLDER/.gnome2/keyrings/default.keyring 
$SUPERUSER_HOME_FOLDER/.gconf/apps/evolution/*/%gconf.xml"
    
    replace_ldap_base "/etc/ldap.conf 
$SUPERUSER_HOME_FOLDER/.gconfxml 
$SUPERUSER_HOME_FOLDER/.evolutionconf.xml 
$SUPERUSER_HOME_FOLDER/.mozilla/firefox/ifl4l6s1.default/sessionstore.js 
$SUPERUSER_HOME_FOLDER/.gconf/apps/evolution/mail/%gconf.xml 
$SUPERUSER_HOME_FOLDER/.gconf/apps/evolution/addressbook/%gconf.xml"

    replace_short_domain "$SUPERUSER_HOME_FOLDER/.gconfxml  
$SUPERUSER_HOME_FOLDER/.evolutionconf.xml 
$SUPERUSER_HOME_FOLDER/.mozilla/firefox/ifl4l6s1.default/sessionstore.js 
$SUPERUSER_HOME_FOLDER/.gconf/apps/evolution/mail/%gconf.xml"

    # Kill Evolution and Gconf.
    evolution_pid=$(ps -C evolution -o pid= -o ruser= | grep $SUPERUSER | awk '{print $1}')
    if [[ $evolution_pid -ne '' ]]; then
        kill -9 $evolution_pid
    fi
    gconfd_pid=$(ps -C gconfd-2 -o pid= -o ruser= | grep $SUPERUSER | awk '{print $1}')
    if [[ $gconfd_pid -ne '' ]]; then
        kill -9 $gconfd_pid
    fi

    # Load gconf xml data
    su - -c "gconftool-2 --load $SUPERUSER_HOME_FOLDER/.gconfxml " $SUPERUSER

    # Update favorites menu
    update-gconf-defaults

    # Rename the cache directory instead of evolution having to download all the emails again.
    if [ $OLD_SYSTEM_ANCHOR_DOMAIN != $NEW_SYSTEM_ANCHOR_DOMAIN ]; then
	mv /home/$SUPERUSER/.evolution/mail/imap/$SUPERUSER@imap.$(to_lower $OLD_SYSTEM_ANCHOR_DOMAIN) /home/$SUPERUSER/.evolution/mail/imap/$SUPERUSER@imap.$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)
    fi

    # C3 Backwards Compatibility - For evolution certutil import
    ln -s $CA_CERT_FOLDER/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)/CA.crt $CA_CERT_FOLDER/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN)/$(to_lower $NEW_SYSTEM_ANCHOR_DOMAIN).crt
fi

exit 0
