#!/bin/bash
#
# Nuxeo deploy script - v2.2
#
# Created by Gregory Wolgemuth <gwolgemuth@eseri.com>
# Modified by Colin Wass <cwass@eseri.com>
# Modified by Karoly Molnar <kmolnar@eseri.com>
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

# Mark start point in log file
echo "$(date) Deploy Nuxeo Server"

NUXEO_PASS=$(getPassword DB_PASSWORD_NUXEO)
LDAP_NUXEO_PASSWORD=$(getPassword LDAP_PASSWORD_NUXEO)
KEYSTORE_PASSWORD=$(getPassword NUXEO_KEYPASS)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# Add extra repositories
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/canonical.list
eseriReplaceValues /etc/apt/sources.list.d/canonical.list
apt-get update

# Install Java
echo "sun-java6-bin	shared/accepted-sun-dlj-v1-1	boolean	true" | debconf-set-selections
echo "sun-java6-jre	shared/accepted-sun-dlj-v1-1	boolean	true" | debconf-set-selections
aptGetInstall sun-java6-jre

# Import CA to java keystore
keytool -storepasswd -new "$KEYSTORE_PASSWORD" -storepass changeit -keystore /etc/java-6-sun/security/cacerts
keytool -import -noprompt -file /usr/share/ca-certificates/`hostname -d`/CA.crt -storepass "$KEYSTORE_PASSWORD" -keystore /etc/java-6-sun/security/cacerts

# Install unzip
aptGetInstall unzip

# Create the nuxeo user
adduser --system --home /var/lib/nuxeo --no-create-home --group --disabled-password --disabled-login nuxeo

# Install Nuxeo
cat $ARCHIVE_FOLDER/transient/nuxeo-dm-latest-stable-jboss.zip.tar.gz.aa $ARCHIVE_FOLDER/transient/nuxeo-dm-latest-stable-jboss.zip.tar.gz.ab | tar -C $ARCHIVE_FOLDER/transient/ -zxvf -
rm $ARCHIVE_FOLDER/transient/nuxeo-dm-latest-stable-jboss.zip.tar.gz.aa $ARCHIVE_FOLDER/transient/nuxeo-dm-latest-stable-jboss.zip.tar.gz.ab
unzip -d /var/lib $ARCHIVE_FOLDER/transient/nuxeo-dm-latest-stable-jboss.zip
mv /var/lib/nuxeo-dm-5.3.1-jboss /var/lib/nuxeo-dm-5.3.1
ln -s nuxeo-dm-5.3.1 /var/lib/nuxeo
chown -R nuxeo:nuxeo /var/lib/nuxeo-dm-5.3.1/
chown -R nuxeo:nuxeo /var/lib/nuxeo/
chmod -R 644 /var/lib/nuxeo-dm-5.3.1/
# Make all directories executable so that files can be found
find /var/lib/nuxeo/ -type d -exec chmod ug+x {} \;
# Make all the script files that run nuxeo executable so it can actually start
find /var/lib/nuxeo/bin/ -name "*.sh" -exec chmod ug+x {} \;

# Deploy jar files
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/lib/postgresql-8.4-701.jdbc4.jar /var/lib/nuxeo/server/default/lib/postgresql-8.4-701.jdbc4.jar
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/plugins/nuxeo-platform-login-mod_sso-5.3.1.jar /var/lib/nuxeo/server/default/deploy/nuxeo.ear/plugins/nuxeo-platform-login-mod_sso-5.3.1.jar

# Remove the PostgreSQL driver that came with the package
rm /var/lib/nuxeo/server/default/lib/postgresql-8.3-604.jdbc3.jar

# Install Nuxeo shell
unzip  -d /var/lib/nuxeo $ARCHIVE_FOLDER/transient/nuxeo-shell-5.3.1.zip
chown -R nuxeo:nuxeo /var/lib/nuxeo/nuxeo-shell-5.3.1

# Deploy init script
install -o root -g root -m 755 $TEMPLATE_FOLDER/etc/init.d/nuxeo /etc/init.d/nuxeo
TIMEZONE=`cat /etc/timezone`
sed -i -e "s|\[-TIMEZONE-\]|$TIMEZONE|" /etc/init.d/nuxeo
update-rc.d nuxeo defaults 90

# Nuxeo General configuration
install -o nuxeo -g nuxeo -m 644 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/nuxeo.properties /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/nuxeo.properties
IP=`ifconfig eth0 | grep -o "inet addr:[^ ]*" | grep -o "[[:digit:].]*"`
sed -i -e "s/\[-NUXEOSERVER_IP_ADDRESS-\]/$IP/" /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/nuxeo.properties
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/OSGI-INF/templates/web.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/OSGI-INF/templates/web.xml


# Nuxeo OpenOffice Configuration
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/ooo-config.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/ooo-config.xml

# Nuxeo Email Configuration
install -o nuxeo -g nuxeo -m 644 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/mail-service.xml /var/lib/nuxeo/server/default/deploy/mail-service.xml
eseriReplaceValues /var/lib/nuxeo/server/default/deploy/mail-service.xml
install -o nuxeo -g nuxeo -m 644 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/notification-config.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/notification-config.xml
eseriReplaceValues /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/notification-config.xml

# Nuxeo Authentication configuration
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/eseri-auth-config.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/eseri-auth-config.xml

install -o nuxeo -g nuxeo -m 640 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-users-directory-bundle.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-users-directory-bundle.xml
sed -i -e 's|\[-DOMAIN-\]|'$DOMAIN'|;s|\[-LDAP_BASE_DN-\]|'$LDAP_BASE'|;s|\[-LDAP_PASSWORD_NUXEO-\]|'$LDAP_NUXEO_PASSWORD'|' /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-users-directory-bundle.xml

install -o nuxeo -g nuxeo -m 644 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-groups-directory-bundle.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-groups-directory-bundle.xml
sed -i -e "s|\[-LDAP_BASE_DN-\]|$LDAP_BASE|" /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-ldap-groups-directory-bundle.xml

# Nuxeo PostgreSQL configuration
install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-repository-config.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/default-repository-config.xml

install -o nuxeo -g nuxeo -m 644 $ARCHIVE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/sql.properties /var/lib/nuxeo/server/default/deploy/nuxeo.ear/config/sql.properties

install -o nuxeo -g nuxeo -m 640 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/default-repository-ds.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/default-repository-ds.xml
sed -i -e 's|\[-DOMAIN-\]|'$DOMAIN'|;s|\[-DB_PASSWORD_NUXEO-\]|'$NUXEO_PASS'|' /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/default-repository-ds.xml

install -o nuxeo -g nuxeo -m 640 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/unified-nuxeo-ds.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/unified-nuxeo-ds.xml
sed -i -e 's|\[-DOMAIN-\]|'$DOMAIN'|;s|\[-DB_PASSWORD_NUXEO-\]|'$NUXEO_PASS'|' /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/unified-nuxeo-ds.xml

install -o nuxeo -g nuxeo -m 640 $TEMPLATE_FOLDER/var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/nxtags-ds.xml /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/nxtags-ds.xml
sed -i -e 's|\[-DOMAIN-\]|'$DOMAIN'|;s|\[-DB_PASSWORD_NUXEO-\]|'$NUXEO_PASS'|' /var/lib/nuxeo/server/default/deploy/nuxeo.ear/datasources/nxtags-ds.xml

# Install components to convert documents
aptGetInstall imagemagick poppler-utils openoffice.org openoffice.org-headless ufraw ghostscript

# Start nuxeo
/etc/init.d/nuxeo start

exit 0
