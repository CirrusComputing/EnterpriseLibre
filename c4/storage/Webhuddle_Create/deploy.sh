#!/bin/bash
#
# Webhuddle deploy script - v1.0
#
# Created by Karoly Molnar <kmolnar@eseri.com>
#
# Copyright (c) 1996-2010 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
# TODO: keystore generation
# TODO: changing the pages based on the info provided by Bill

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy Webhuddle Server"

LDAP_WEBHUDDLE_PW=$(getPassword LDAP_PASSWORD_WEBHUDDLE)
WEBHUDDLE_KEYSTORE_PW=$(getPassword WEBHUDDLE_KEYSTORE)

# Variables
SYSTEM_INIT_D_FOLDER=/etc/init.d
WEBHUDDLE_FOLDER=/var/lib/webhuddle
WEBHUDDLE_EAR_FOLDER=$WEBHUDDLE_FOLDER/server/default/deploy/webhuddle-app.ear

# Template files

# Archive files

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# Add Canonical repository
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/canonical.list
eseriReplaceValues /etc/apt/sources.list.d/canonical.list
apt-get update

# Install Java
echo "sun-java6-bin     shared/accepted-sun-dlj-v1-1    boolean true" | debconf-set-selections
echo "sun-java6-jre     shared/accepted-sun-dlj-v1-1    boolean true" | debconf-set-selections
aptGetInstall sun-java6-bin sun-java6-jre sun-java6-jdk

# Install JBOSS
tar xzf $ARCHIVE_FOLDER/jboss-3.2.8.SP1.tar.gz -C /var/lib/
mv /var/lib/jboss-3.2.8.SP1 $WEBHUDDLE_FOLDER

# Install Webhuddle
tar xzf $ARCHIVE_FOLDER/webhuddle-app.ear.tar.gz -C $WEBHUDDLE_FOLDER/server/default/deploy/
chown root:root -R $WEBHUDDLE_FOLDER

# Deploy and modify configuration files
install -o root -g root -m 755 $ARCHIVE_FOLDER/webhuddle $SYSTEM_INIT_D_FOLDER/
update-rc.d webhuddle defaults 90

install -o root -g root -m 644 $ARCHIVE_FOLDER/web.xml $WEBHUDDLE_FOLDER/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/web.xml

install -o root -g root -m 644 $TEMPLATE_FOLDER/var/lib/webhuddle/bin/webhuddle.properties $WEBHUDDLE_FOLDER/bin/webhuddle.properties
eseriReplaceValues $WEBHUDDLE_FOLDER/bin/webhuddle.properties

install -o root -g root -m 644 $TEMPLATE_FOLDER/var/lib/webhuddle/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/applicationContext-acegi-security-ldap.xml $WEBHUDDLE_FOLDER/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/applicationContext-acegi-security-ldap.xml
sed -i -e "s/\[-LDAP_PASSWORD_WEBHUDDLE-\]/$LDAP_WEBHUDDLE_PW/g" $WEBHUDDLE_FOLDER/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/applicationContext-acegi-security-ldap.xml
eseriReplaceValues $WEBHUDDLE_FOLDER/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/applicationContext-acegi-security-ldap.xml

install -o root -g root -m 644 $TEMPLATE_FOLDER/var/lib/webhuddle/server/default/deploy/jbossweb-tomcat50.sar/server.xml $WEBHUDDLE_FOLDER/server/default/deploy/jbossweb-tomcat50.sar/server.xml
sed -i -e "s/\[-WEBHUDDLE_KEYPASS-\]/$WEBHUDDLE_KEYSTORE_PW/g" $WEBHUDDLE_FOLDER/server/default/deploy/jbossweb-tomcat50.sar/server.xml
eseriReplaceValues $WEBHUDDLE_FOLDER/server/default/deploy/jbossweb-tomcat50.sar/server.xml

# Import CA root cert to java keystore
keytool -importcert -noprompt -file /usr/share/ca-certificates/$DOMAIN/CA.crt -keystore /etc/java-6-sun/security/cacerts -storepass changeit

# Deploy keystore
openssl pkcs12 -export -in $ARCHIVE_FOLDER/webmeeting.${DOMAIN}_cert.pem -inkey $ARCHIVE_FOLDER/webmeeting.${DOMAIN}_key.pem -out $ARCHIVE_FOLDER/webhuddle.rsa.pkcs12 -passout "pass:pass"
keytool -importkeystore -v -noprompt -deststorepass "$WEBHUDDLE_KEYSTORE_PW" -destkeystore $WEBHUDDLE_FOLDER/server/default/conf/webhuddle.jks -srckeystore $ARCHIVE_FOLDER/webhuddle.rsa.pkcs12 -srcstorepass "pass" -alias 1 -destalias tomcat -srcstoretype PKCS12 -destkeypass "$WEBHUDDLE_KEYSTORE_PW"

# Install OpenOffice
aptGetInstall  openoffice.org openoffice.org-headless psmisc

# Deploy init script
install -o root -g root -m 755 $ARCHIVE_FOLDER/openoffice $SYSTEM_INIT_D_FOLDER/
update-rc.d openoffice defaults 90

#Patch Webhuddle for page content
aptGetInstall patch

patch -u /var/lib/webhuddle/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/home.jsp < $ARCHIVE_FOLDER/home.jsp.patch
patch -u /var/lib/webhuddle/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/classes/about.properties < $ARCHIVE_FOLDER/about.properties.patch
patch -u /var/lib/webhuddle/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/classes/home.properties < $ARCHIVE_FOLDER/home.properties.patch
patch -u /var/lib/webhuddle/server/default/deploy/webhuddle-app.ear/webhuddle-web.war/WEB-INF/classes/simple.properties < $ARCHIVE_FOLDER/simple.properties.patch

# Start servers
/etc/init.d/webhuddle start
/etc/init.d/openoffice start

exit 0
