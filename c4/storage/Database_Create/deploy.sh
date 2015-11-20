#!/bin/bash
#
# Database deploy script - v2.0
#
# Created by Gregory Wolgemuth <gwolgemuth@eseri.com>
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

. ${0%/*}/archive/eseriCommon

echo "$(date) - Deploy Database"

cd ${0%/*}
ORGNAME=$(getParameter short_domain)
PGPASS=$(getPassword DB_PASSWORD_POSTGRES)
MYPASS=$(getPassword DB_PASSWORD_MYSQL)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

NET0=$NETWORK.0

# Set system parameters required by PostgreSQL
echo "kernel.shmmax=402653184" >/etc/sysctl.d/60-shmmax.conf
service procps start

#Do the postgres dance
aptGetInstall postgresql

sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" -e 's/^shared_buffers = 28MB/shared_buffers = 256MB/' -e 's/^#max_prepared_transactions = 0/max_prepared_transactions = 64/' /etc/postgresql/8.4/main/postgresql.conf

cat >>/etc/postgresql/8.4/main/pg_hba.conf <<EOF
host	template1	nagios	$NETWORK.30/32	trust
host	all		nagios	0.0.0.0/0	reject
host	all		all	$NET0/24	md5
EOF
su - -c "psql -c \"CREATE ROLE pgadmin PASSWORD '$PGPASS' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;\"" postgres

/etc/init.d/postgresql-8.4 restart

#Now do the MySQL dance
echo "mysql-server-5.1 mysql-server/root_password password $MYPASS" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYPASS" | debconf-set-selections
aptGetInstall mysql-server
cp /etc/mysql/my.cnf ./
cat ./my.cnf | sed -e 's/127.0.0.1/0.0.0.0/' > /etc/mysql/my.cnf
rm ./my.cnf

# Alter MySQL upstart script
dpkg-divert --add --rename --divert /etc/init-disabled/mysql.conf /etc/init/mysql.conf
install -o root -g root -m 644 $ARCHIVE_FOLDER/mysql.conf /etc/init/mysql.conf

/etc/init.d/mysql restart

cd /root/
echo "[client]" > /root/.my.cnf
echo "password=$MYPASS" >> /root/.my.cnf
echo "GRANT ALL ON *.* TO 'root'@'poseidon.$DOMAIN' IDENTIFIED BY '$MYPASS' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql -uroot -Dmysql
#Do timesheet.php work while we have the connection we need
#First make the user and DB
hasCapability Timesheet
if [ $? -eq 0 ] ; then
	echo "Timesheet"
	TIMESHEETPASS=$(getPassword DB_PASSWORD_TIMESHEET)
	TIMESHEET_LDAPPASS=$(getPassword LDAP_PASSWORD_TIMESHEET)
	cat $TEMPLATE_FOLDER/transient/timesheet-ng-1.5.2_create.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-DB_PASSWORD_TIMESHEET-\]|$TIMESHEETPASS|" | mysql -uroot -Dmysql
	#Now make all the tables and stuff
	cat $ARCHIVE_FOLDER/timesheet-ng-1.5.2.sql | mysql -uroot -Dtimesheet -v 
	#Now place necessary LDAP settings etc in there
	cat $TEMPLATE_FOLDER/transient/timesheet-ng-1.5.2_ldap.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-LDAP_BASE_DN-\]|$LDAP_BASE|g;s|\[-LDAP_PASSWORD_TIMESHEET-\]|$TIMESHEET_LDAPPASS|;s|\[-TIMEZONE-\]|$TIMEZONE|" | mysql -uroot -Dtimesheet
fi

#Now do OrangeHRM's database
hasCapability OrangeHRM
if [ $? -eq 0 ] ; then
	echo "OrangeHRM"
	ORANGEPASS=$(getPassword DB_PASSWORD_ORANGEHRM)
	ORANGEHRM_ADMIN_PASSWORD=$(getPassword ORANGEHRM_ADMIN_PASSWORD)
	echo "CREATE DATABASE orangehrm;" | mysql -uroot -Dmysql
	echo "use mysql; CREATE USER 'orangehrm'@'poseidon.$DOMAIN' IDENTIFIED BY '$ORANGEPASS';" | mysql -uroot -Dmysql
	echo "use mysql; GRANT ALL ON orangehrm.* TO 'orangehrm'@'poseidon.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -Dorangehrm
	cat $TEMPLATE_FOLDER/transient/orangehrm.sql | sed -e "s/\[-ORANGEHRM_ADMIN_PASSWORD-\]/$ORANGEHRM_ADMIN_PASSWORD/" | mysql -uroot -Dorangehrm
fi

#And do VTiger's database as well
hasCapability Vtiger
if [ $? -eq 0 ] ; then
	echo "Vtiger"
	VTIGERPASS=$(getPassword DB_PASSWORD_VTIGER)
	echo "CREATE DATABASE vtiger CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -Dmysql
	echo "CREATE USER 'vtiger'@'poseidon.$DOMAIN' IDENTIFIED BY '$VTIGERPASS';" | mysql -uroot -Dvtiger
	echo "GRANT ALL ON vtiger.* TO 'vtiger'@'poseidon.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -Dvtiger
	cat $TEMPLATE_FOLDER/transient/vtiger54.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|" | mysql -uroot -Dvtiger
fi

#PHPScheduleIt
hasCapability PHPScheduleIt
if [ $? -eq 0 ] ; then
        echo "PHPScheduleIt"
        PHPSCHEDULEITPASS=$(getPassword DB_PASSWORD_PHPSCHEDULEIT)
        echo "CREATE DATABASE phpscheduleit CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -Dmysql
        echo "CREATE USER 'phpscheduleit'@'trident.$DOMAIN' IDENTIFIED BY '$PHPSCHEDULEITPASS';" | mysql -uroot -Dphpscheduleit
        echo "GRANT ALL ON phpscheduleit.* TO 'phpscheduleit'@'trident.$DOMAIN'; FLUSH PRIVILEGES;" | mysql -uroot -Dphpscheduleit
        cat $TEMPLATE_FOLDER/transient/phpscheduleit.sql.template | mysql -uroot -Dphpscheduleit
fi

#Monitoring
echo "CREATE USER 'nagios'@'hades.$DOMAIN';" | mysql -uroot -Dmysql

rm /root/.my.cnf
/etc/init.d/mysql restart
history -c

#Now do installations of databases and so-forth as necessary for other packages
#Start with Nuxeo

hasCapability Nuxeo
if [ $? -eq 0 ] ; then
	echo "Nuxeo"
	NUXEOPASS=$(getPassword DB_PASSWORD_NUXEO5)
	su - -c "psql -c \"CREATE ROLE nuxeo PASSWORD '$NUXEOPASS' INHERIT LOGIN;\"" postgres
	su - -c "createdb nuxeo -O nuxeo" postgres
	mv $ARCHIVE_FOLDER/nuxeopg83.sql /var/lib/postgresql
	chmod a+rx /var/lib/postgresql/nuxeopg83.sql
	su - -c "psql -d nuxeo -f nuxeopg83.sql" postgres
	rm /var/lib/postgresql/nuxeopg83.sql
fi
hasCapability Wiki
if [ $? -eq 0 ] ; then
	echo "Wiki"
	WIKIPASS=$(getPassword DB_PASSWORD_MEDIAWIKI)
	su - -c "psql -c \"CREATE ROLE wikiuser PASSWORD '$WIKIPASS' INHERIT LOGIN;\"" postgres
	su - -c "createdb wikidb -O wikiuser" postgres
	echo "*:*:*:*:$WIKIPASS" > /root/.pgpass
	chmod 0600 /root/.pgpass
	psql -U wikiuser -h localhost -d wikidb < $ARCHIVE_FOLDER/wiki.sql
	rm /root/.pgpass
	su - -c "psql -c \"ALTER ROLE wikiuser SET SEARCH_PATH = mediawiki, public\"" postgres
	su - -c "psql -c \"ALTER ROLE wikiuser SET CLIENT_MIN_MESSAGES = 'error';\"" postgres
        su - -c "psql -c \"ALTER ROLE wikiuser SET DATESTYLE = 'ISO, YMD';\"" postgres
        su - -c "psql -c \"ALTER ROLE wikiuser SET TIMEZONE = 'GMT';\"" postgres	
fi
hasCapability Trac
if [ $? -eq 0 ] ; then
	echo "Trac"
	TRAC_PASSWORD=$(getPassword DB_PASSWORD_TRAC)
	su - -c "psql -c \"CREATE ROLE trac PASSWORD '$TRAC_PASSWORD' INHERIT LOGIN;\"" postgres
	su - -c "createdb trac -O trac" postgres
fi
hasCapability Smartphone
if [ $? -eq 0 ] ; then
	echo "Smartphone"
	FUNAMBOLPASS=$(getPassword DB_PASSWORD_FUNAMBOL)
	su - -c "psql -c \"CREATE ROLE funambol PASSWORD '$FUNAMBOLPASS' INHERIT LOGIN;\"" postgres
	su - -c "createdb funambol -O funambol" postgres
	echo "*:*:*:*:$FUNAMBOLPASS" > /root/.pgpass
	chmod 0600 /root/.pgpass
	cat $TEMPLATE_FOLDER/transient/funambol.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|g;s|\[-ORG-\]|$DOMAINNAME|g" > /var/lib/postgresql/funambol.sql
	psql -U funambol -h localhost -d funambol < /var/lib/postgresql/funambol.sql
	rm /var/lib/postgresql/funambol.sql
	rm /root/.pgpass
fi
hasCapability Email
if [ $? -eq 0 ] ; then
	echo "Email"
	DSPAMPASS=$(getPassword DB_PASSWORD_DSPAM)
	su - -c "psql -c \"CREATE ROLE dspam PASSWORD '$DSPAMPASS' INHERIT LOGIN;\"" postgres
	su - -c "createdb dspam -O dspam" postgres
	echo "*:*:*:*:$DSPAMPASS" > /root/.pgpass
	chmod 0600 /root/.pgpass
	psql -U dspam -h localhost -d dspam < $ARCHIVE_FOLDER/dspam.sql
	rm /root/.pgpass
fi
hasCapability SOGo
if [ $? -eq 0 ] ; then
	echo "SOGo"
	DB_PASSWORD_SOGO=$(getPassword DB_PASSWORD_SOGO)
	SOGO_PASSWORD_FREEBUSY=$(getPassword SOGO_PASSWORD_FREEBUSY)
	su - -c "psql -c \"CREATE ROLE sogo PASSWORD '$DB_PASSWORD_SOGO' INHERIT LOGIN;\"" postgres
	su - -c "createdb sogo -O sogo" postgres
	MD5_SOGO_PASSWORD_FREEBUSY=$(echo -n "$SOGO_PASSWORD_FREEBUSY" | md5sum | awk '{print $1}')
	cat $TEMPLATE_FOLDER/transient/sogo.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|g;s|\[-SOGO_PASSWORD_FREEBUSY-\]|$MD5_SOGO_PASSWORD_FREEBUSY|g" > /var/lib/postgresql/sogo.sql
	chmod a+rx /var/lib/postgresql/sogo.sql
	su -l -c "psql -d sogo -f sogo.sql" postgres
	rm /var/lib/postgresql/sogo.sql
fi

hasCapability InstantMessaging
if [ $? -eq 0 ] ; then
	echo "InstantMessaging"
	OPENFIREPASS=$(getPassword DB_PASSWORD_OPENFIRE)
	OPENFIRE_LDAPPASS=$(getPassword LDAP_PASSWORD_OPENFIRE)
	OPENFIRE_KEYPASS=$(getPassword OPENFIRE_KEYPASS)
	#Next up is Openfire (XMPP)
	su - -c "psql -c \"CREATE ROLE openfire PASSWORD '$OPENFIREPASS' INHERIT LOGIN;\"" postgres
	su - -c "createdb openfire -O openfire" postgres
	echo "*:*:*:*:$OPENFIREPASS" > /root/.pgpass
	chmod 0600 /root/.pgpass
	psql -U openfire -h localhost -d openfire < $ARCHIVE_FOLDER/openfire_postgresql.sql
	cat $TEMPLATE_FOLDER/transient/ofproperty.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-LDAP_BASE_DN-\]|$LDAP_BASE|;s|\[-LDAP_PASSWORD_OPENFIRE-\]|$OPENFIRE_LDAPPASS|;s|\[-OPENFIRE_KEYPASS-\]|$OPENFIRE_KEYPASS|;s|\[-REALM-\]|$REALM|" > /var/lib/postgresql/ofproperty.sql
	psql -U openfire -h localhost -d openfire < /var/lib/postgresql/ofproperty.sql
	psql -U openfire -h localhost -d openfire < $ARCHIVE_FOLDER/ofgroupprop.sql
	rm /var/lib/postgresql/ofproperty.sql
	rm /root/.pgpass
fi

hasCapability SQLLedger
if [ $? -eq 0 ] ; then
	echo "SQLLedger"
	DB_PASSWORD_SQL_LEDGER=$(getPassword DB_PASSWORD_SQL_LEDGER)
	sudo -u postgres psql -c "CREATE ROLE \"sql-ledger\" PASSWORD '$DB_PASSWORD_SQL_LEDGER' INHERIT LOGIN;"
	su -l -c "createdb sql-ledger -O sql-ledger" postgres
fi

hasCapability Redmine
if [ $? -eq 0 ] ; then
	echo "Redmine"
	REDMINEPASS=$(getPassword DB_PASSWORD_REDMINE)
	REDMINE_LDAPPASS=$(getPassword LDAP_PASSWORD_REDMINE)
	sudo -u postgres psql -c "CREATE ROLE \"redmine\" PASSWORD '$REDMINEPASS' INHERIT LOGIN;"
	su -l -c "createdb redmine -O redmine" postgres
	cat $TEMPLATE_FOLDER/transient/redmine.sql.template | sed -e "s|\[-DOMAIN-\]|$DOMAIN|;s|\[-LDAP_BASE_DN-\]|$LDAP_BASE|g;s|\[-LDAP_PASSWORD_REDMINE-\]|$REDMINE_LDAPPASS|" > /var/lib/postgresql/redmine.sql
	chmod a+rx /var/lib/postgresql/redmine.sql
	su -l -c "psql -d redmine -f redmine.sql" postgres
	rm /var/lib/postgresql/redmine.sql	
fi

#Monitoring
echo "Monitoring"
su -l -c 'createuser -SDRlI nagios' postgres
cat >>/etc/nagios/nrpe_local.cfg <<EOF
command[check_pgsql]=/usr/lib/nagios/plugins/check_pgsql -l nagios -H hades.$DOMAIN
command[check_mysql]=/usr/lib/nagios/plugins/check_mysql -u nagios -H hades.$DOMAIN
EOF

exit 0
