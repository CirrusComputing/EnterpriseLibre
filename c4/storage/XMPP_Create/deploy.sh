#!/bin/bash
#
# OpenFire deploy script - v2.1
#
# Created by Gregory Wolgemuth <gwolgemuth@cirruscomputing.com>
# Modified by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

eseriGetDNS
eseriGetNetwork

LDAP_XMPP_PASSWORD=$(getPassword LDAP_PASSWORD_OPENFIRE)
XMPP_POSTGRES_PASSWORD=$(getPassword DB_PASSWORD_OPENFIRE)
SYSTEM_KEYSTORE_PASSWORD=$(getPassword OPENFIRE_SYSTEM_KEYPASS)
XMPP_KEYSTORE_PASSWORD=$(getPassword OPENFIRE_KEYPASS)

OPENFIRE_CONFIG_FOLDER=/etc/openfire
JAVA_CONFIG_FOLDER=/etc/java-6-sun
SYSTEM_SSL_FOLDER=/etc/ssl
SYSTEM_SSL_CERTS_FOLDER=$SYSTEM_SSL_FOLDER/certs
SYSTEM_SSL_PRIVATE_FOLDER=$SYSTEM_SSL_FOLDER/private
XMPP_CERT=$SYSTEM_SSL_CERTS_FOLDER/xmpp.$DOMAIN.pem
XMPP_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/xmpp.$DOMAIN.pem
XMPP_PKCS12=$SYSTEM_SSL_PRIVATE_FOLDER/xmpp.$DOMAIN.pkcs12
XMPP_DSA_CERT=$SYSTEM_SSL_CERTS_FOLDER/xmpp.${DOMAIN}_dsa.pem
XMPP_DSA_KEY=$SYSTEM_SSL_PRIVATE_FOLDER/xmpp.${DOMAIN}_dsa.pem
XMPP_DSA_PKCS12=$SYSTEM_SSL_PRIVATE_FOLDER/xmpp.${DOMAIN}_dsa.pkcs12

# Add Canonical repository
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/canonical.list
eseriReplaceValues /etc/apt/sources.list.d/canonical.list
apt-get update

# Install Java
echo "sun-java6-bin     shared/accepted-sun-dlj-v1-1    boolean true" | debconf-set-selections
echo "sun-java6-jre     shared/accepted-sun-dlj-v1-1    boolean true" | debconf-set-selections

aptGetInstall sun-java6-jre

dpkg -i $ARCHIVE_FOLDER/openfire_3.6.4_all.deb

/etc/init.d/openfire stop
echo "Stopped openfire"

install -o openfire -g openfire -m 644 $ARCHIVE_FOLDER/ldapuseradd.jar /var/lib/openfire/plugins
install -o openfire -g openfire -m 400 $ARCHIVE_FOLDER/erato.openfire.keytab $OPENFIRE_CONFIG_FOLDER/xmpp.keytab

cat $TEMPLATE_FOLDER/$OPENFIRE_CONFIG_FOLDER/gss.conf | sed -e "s|\[-REALM-\]|$REALM|;s|\[-FQDN_HOSTNAME-\]|$FQDN_HOSTNAME|" > $OPENFIRE_CONFIG_FOLDER/gss.conf
chown openfire:openfire $OPENFIRE_CONFIG_FOLDER/gss.conf
chmod 644 $OPENFIRE_CONFIG_FOLDER/gss.conf

cat $TEMPLATE_FOLDER/$OPENFIRE_CONFIG_FOLDER/openfire.xml | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-DB_PASSWORD_OPENFIRE-\]|$XMPP_POSTGRES_PASSWORD|" > $OPENFIRE_CONFIG_FOLDER/openfire.xml

chown openfire:openfire $OPENFIRE_CONFIG_FOLDER/openfire.xml
chmod 640 $OPENFIRE_CONFIG_FOLDER/openfire.xml

# Deploy XMPP Certificates
install -o root -g root -m 644 $ARCHIVE_FOLDER/xmpp.${DOMAIN}_cert.pem $XMPP_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/xmpp.${DOMAIN}_key.pem $XMPP_KEY
install -o root -g root -m 644 $ARCHIVE_FOLDER/xmpp.${DOMAIN}_dsa_cert.pem $XMPP_DSA_CERT
install -o root -g ssl-cert -m 640 $ARCHIVE_FOLDER/xmpp.${DOMAIN}_dsa_key.pem $XMPP_DSA_KEY

keytool -storepasswd -new "$SYSTEM_KEYSTORE_PASSWORD" -storepass changeit -keystore $JAVA_CONFIG_FOLDER/security/cacerts
keytool -import -noprompt -file /usr/share/ca-certificates/`hostname -d`/CA.crt -storepass "$SYSTEM_KEYSTORE_PASSWORD" -keystore $JAVA_CONFIG_FOLDER/security/cacerts

keytool -storepasswd -new "$XMPP_KEYSTORE_PASSWORD" -storepass changeit -keystore $OPENFIRE_CONFIG_FOLDER/security/truststore
keytool -storepasswd -new "$XMPP_KEYSTORE_PASSWORD" -storepass changeit -keystore $OPENFIRE_CONFIG_FOLDER/security/keystore
keytool -importcert -noprompt -file /usr/share/ca-certificates/`hostname -d`/CA.crt -storepass "$XMPP_KEYSTORE_PASSWORD" -keystore $OPENFIRE_CONFIG_FOLDER/security/truststore -alias $DOMAIN

openssl pkcs12 -export -in $XMPP_CERT -inkey $XMPP_KEY -out $XMPP_PKCS12 -passout "pass:pass"
openssl pkcs12 -export -in $XMPP_DSA_CERT -inkey $XMPP_DSA_KEY -out $XMPP_DSA_PKCS12 -passout "pass:pass"
keytool -importkeystore -v -noprompt -deststorepass "$XMPP_KEYSTORE_PASSWORD" -destkeystore $OPENFIRE_CONFIG_FOLDER/security/keystore -srckeystore $XMPP_PKCS12 -srcstorepass "pass" -alias 1 -destalias ${FQDN_HOSTNAME}_1 -srcstoretype PKCS12 -destkeypass "$XMPP_KEYSTORE_PASSWORD"
keytool -importkeystore -v -noprompt -deststorepass "$XMPP_KEYSTORE_PASSWORD" -destkeystore $OPENFIRE_CONFIG_FOLDER/security/keystore -srckeystore $XMPP_PKCS12 -srcstorepass "pass" -alias 1 -destalias ${FQDN_HOSTNAME}_2 -srcstoretype PKCS12 -destkeypass "$XMPP_KEYSTORE_PASSWORD"

aptGetInstall postgresql-client

update-rc.d -f openfire remove
update-rc.d openfire defaults 61

install -o root -g root -m 755 $ARCHIVE_FOLDER/checkpgsql /etc/init.d
update-rc.d checkpgsql defaults 60
echo "pgsql.$DOMAIN:5432:openfire:openfire:$XMPP_POSTGRES_PASSWORD" > /root/.pgpass
chmod 0400 /root/.pgpass

/etc/init.d/checkpgsql startdebug
/etc/init.d/openfire start

exit 0
