#!/bin/bash
#
# Funambol deploy script - v1.2
#
# Created by Gregory Wolgemuth <woogie@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
# 
# Copyright (c) 1996-2015 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

. ${0%/*}/archive/eseriCommon

DB_PASSWORD_FUNAMBOL=$(getPassword DB_PASSWORD_FUNAMBOL)
FUNAMBOL_ADMIN_PASSWORD=$(getPassword FUNAMBOL_ADMIN_PASSWORD)
DB_PASSWORD_SOGO=$(getPassword DB_PASSWORD_SOGO)

ESERIMAN_HOME=/var/lib/eseriman
eseriGetDNS
eseriGetNetwork
aptGetInstall expect postgresql-client
# apt-get install -y expect-dev
#( cd /usr/share/doc/expect-dev/examples/ && gunzip autoexpect.gz && chmod a+x autoexpect )

#Now make the Eseriman user so we can let C3 populate the user database with correct info
adduser --gecos "Eseriman" --disabled-password eseriman --home $ESERIMAN_HOME
chmod 750 $ESERIMAN_HOME
install -o root -g root -m 755 -d $ESERIMAN_HOME/bin
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin ${ARCHIVE_FOLDER}$ESERIMAN_HOME/bin/addFunambolUser.sh
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin ${ARCHIVE_FOLDER}$ESERIMAN_HOME/bin/changeFunambolUserPassword.sh
install -o root -g root -m 644 -t $ESERIMAN_HOME/bin ${ARCHIVE_FOLDER}$ESERIMAN_HOME/bin/Encryption2.class
install -o eseriman -g eseriman -m 700 -d $ESERIMAN_HOME/.ssh
install -o eseriman -g eseriman -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys.c3 $ESERIMAN_HOME/.ssh/authorized_keys

#Now add the pgpass with the password for the Funambol database
#psql is funny in that it wants the .pgpass to be in /root when you're running something with sudo and the sticky bit
#mysql worked the opposite way
echo "pgsql.$DOMAIN:*:funambol:funambol:$DB_PASSWORD_FUNAMBOL" > /root/.pgpass
chown root:root /root/.pgpass
chmod 0400 /root/.pgpass

# Deploy sudoers file
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/etc/sudoers.d/eseriman

# Deploy Funambol
cat $ARCHIVE_FOLDER/transient/funambol-8.7.0.bin.tar.gz.aa $ARCHIVE_FOLDER/transient/funambol-8.7.0.bin.tar.gz.ab | tar -C $ARCHIVE_FOLDER/transient/ -zxvf -
rm $ARCHIVE_FOLDER/transient/funambol-8.7.0.bin.tar.gz.aa $ARCHIVE_FOLDER/transient/funambol-8.7.0.bin.tar.gz.ab
chmod a+x $ARCHIVE_FOLDER/transient/funambol-8.7.0.bin
cd $ARCHIVE_FOLDER/transient && ./first_install.exp
chown -R root:root /opt/Funambol
install -o root -g root -m 644 -t /opt/Funambol/tools/jre-1.6.0/jre/lib/ext $ARCHIVE_FOLDER/opt/Funambol/tools/tomcat/lib/postgresql-8.4-702.jdbc3.jar
install -o root -g root -m 644 -t /opt/Funambol/tools/tomcat/lib $ARCHIVE_FOLDER/opt/Funambol/tools/tomcat/lib/postgresql-8.4-702.jdbc3.jar
install -o root -g root -m 644 -t /opt/Funambol/tools/tomcat/lib $ARCHIVE_FOLDER/opt/Funambol/tools/tomcat/lib/json_simple.jar
install -o root -g root -m 644 -t /opt/Funambol/ds-server/modules $ARCHIVE_FOLDER/opt/Funambol/ds-server/modules/funambol-sogo-1.0.8.s4j

# Run the installer
install -o root -g root -m 644 -t /opt/Funambol/ds-server $TEMPLATE_FOLDER/opt/Funambol/ds-server/install.properties
eseriReplaceValues /opt/Funambol/ds-server/install.properties
sed -i -e "s|\[-DB_PASSWORD_FUNAMBOL-\]|$DB_PASSWORD_FUNAMBOL|" /opt/Funambol/ds-server/install.properties
cp $ARCHIVE_FOLDER/transient/second_install.exp /opt/Funambol/bin/
cd /opt/Funambol/bin/ && ./second_install.exp
rm second_install.exp

# Deploy SOGo sources
install -o root -g root -m 644 -d /opt/Funambol/config/sogo/sogo/sogo
install -o root -g root -m 644 -t /opt/Funambol/config/sogo/sogo/sogo $TEMPLATE_FOLDER/opt/Funambol/config/sogo/sogo/sogo/event.xml
eseriReplaceValues /opt/Funambol/config/sogo/sogo/sogo/event.xml
sed -i -e "s|\[-DB_PASSWORD_SOGO-\]|$DB_PASSWORD_SOGO|" /opt/Funambol/config/sogo/sogo/sogo/event.xml
install -o root -g root -m 644 -t /opt/Funambol/config/sogo/sogo/sogo $TEMPLATE_FOLDER/opt/Funambol/config/sogo/sogo/sogo/card.xml
eseriReplaceValues /opt/Funambol/config/sogo/sogo/sogo/card.xml
sed -i -e "s|\[-DB_PASSWORD_SOGO-\]|$DB_PASSWORD_SOGO|" /opt/Funambol/config/sogo/sogo/sogo/card.xml
install -o root -g root -m 644 -t /opt/Funambol/config/sogo/sogo/sogo $TEMPLATE_FOLDER/opt/Funambol/config/sogo/sogo/sogo/task.xml
eseriReplaceValues /opt/Funambol/config/sogo/sogo/sogo/task.xml
sed -i -e "s|\[-DB_PASSWORD_SOGO-\]|$DB_PASSWORD_SOGO|" /opt/Funambol/config/sogo/sogo/sogo/task.xml

# Deploy init script
install -o root -g root -m 755 -t /etc/init.d $ARCHIVE_FOLDER/etc/init.d/funambol
update-rc.d funambol defaults 90

# Change the admin password
cat $TEMPLATE_FOLDER/transient/change_admin.exp.template | sed -e "s|\[-FUNAMBOL_ADMIN_PASSWORD-\]|$FUNAMBOL_ADMIN_PASSWORD|" > /opt/Funambol/bin/change_admin.exp
chmod u+x /opt/Funambol/bin/change_admin.exp
./change_admin.exp
rm change_admin.exp

# And start the fireworks ...
/etc/init.d/funambol start
exit 0
