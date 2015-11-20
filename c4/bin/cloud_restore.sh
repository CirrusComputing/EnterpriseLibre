#!/bin/bash
#
# OrgRestore v1.3 - This script does the full restore of an organization. NOTE - Run this script only after amrecover is done (ie, chaos - /tmp/dumps & /home | hera - /var)
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2013 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

if [ $# -ne 1 ]; then
        echo "Usage: $0 <MYSQL_PASSWORD>"
        exit 1
fi

RESTORE_DUMP_FOLDER=/tmp/chaos/dumps
DEST_RESTORE_DUMP_FOLDER=/root/restore
DOMAIN=`hostname -d`
MYSQL_PASSWORD=$1
ORG_SERVERS_VO='athena aphrodite hades hera poseidon cronus erato gaia trident chaos'

for ORG in $ORG_SERVERS_VO ; do
	HOST=$ORG.$DOMAIN
	echo $HOST
	ssh root@$HOST "rm -rf $DEST_RESTORE_DUMP_FOLDER; mkdir -p $DEST_RESTORE_DUMP_FOLDER; exit"
	scp $RESTORE_DUMP_FOLDER/$ORG* root@$HOST:$DEST_RESTORE_DUMP_FOLDER
done

#Copy the new NX Public Key into the authorized_keys2 file for all the users.
NX_KEY=$(cat /usr/NX/etc/keys/node.localhost.id_dsa.pub)
for dir1 in /home/*; do
	ssh root@chaos.$DOMAIN "echo 'no-port-forwarding,no-agent-forwarding,command=\"/usr/NX/bin/nxnode\" $NX_KEY' > $dir1/.ssh/authorized_keys2"
done

#Restoring Kerboros on Athena
ssh root@athena.$DOMAIN "/etc/init.d/krb5-kdc stop; /etc/init.d/krb5-admin-server stop; kdb5_util load -d /var/lib/krb5kdc/principal $DEST_RESTORE_DUMP_FOLDER/athenaKrbDump*; /etc/init.d/krb5-kdc start; /etc/init.d/krb5-admin-server start; exit"

#Restoring Ldap on Athena
ssh root@athena.$DOMAIN "/etc/init.d/slapd stop; cd /var/lib/ldap/; rm -rf *; /usr/sbin/slapadd -l $DEST_RESTORE_DUMP_FOLDER/athenaLdapDump*; chown -R openldap:openldap /var/lib/ldap; /etc/init.d/slapd start; exit"

#Restoring Ldap on Aphrodite
ssh root@aphrodite.$DOMAIN "/etc/init.d/slapd stop; cd /var/lib/ldap/; rm -rf *; /usr/sbin/slapadd -l $DEST_RESTORE_DUMP_FOLDER/aphroditeLdapDump*; chown -R openldap:openldap /var/lib/ldap; /etc/init.d/slapd start; exit"

#Restoring Postgres and Mysql Databases
ssh root@hades.$DOMAIN "/etc/init.d/postgresql-8.4 restart; cp $DEST_RESTORE_DUMP_FOLDER/hadesPgDump* /tmp; chown postgres:postgres /tmp/hadesPgDump*; cd /tmp; su -c 'psql -f /tmp/hadesPgDump* postgres' postgres; /etc/init.d/postgresql-8.4 restart; rm /tmp/hadesPgDump*; service mysql restart; mysql --verbose --user=root --password=$MYSQL_PASSWORD -A < $DEST_RESTORE_DUMP_FOLDER/hadesMysqlDump*; service mysql restart; exit"

#Restoring Vtiger backup
scp $RESTORE_DUMP_FOLDER/files/poseidon/vtigerBackup* root@poseidon.$DOMAIN:/root
ssh root@poseidon.$DOMAIN "tar -C . -zxvf vtigerBackup*; mv /var/lib/vtigercrm /var/lib/vtigercrm.bak; mv /root/vtigercrm /var/lib; chown -R www-data:www-data /var/lib/vtigercrm; /etc/init.d/apache2 restart"

#Restoring Nuxeo backup
scp $RESTORE_DUMP_FOLDER/files/cronus/nuxeoBackup* root@cronus.$DOMAIN:/root
ssh root@cronus.$DOMAIN "tar -C . -zxvf nuxeoBackup*; cp -rp server/ /var/lib/nuxeo/"

#Restoring Redmine backup
scp $RESTORE_DUMP_FOLDER/files/trident/redmineBackup* root@trident.$DOMAIN:/root
ssh root@trident.$DOMAIN "tar -C . -zxvf redmineBackup*; mv /usr/share/redmine /usr/share/redmine.bak; mv /root/redmine /usr/share; /etc/init.d/apache2 restart"

#Copying the keytabs over.
scp $RESTORE_DUMP_FOLDER/keytabs/athena.kadmin.keytab root@athena.$DOMAIN:/etc/krb5kdc/kadm5.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/aphrodite.host.keytab root@aphrodite.$DOMAIN:/etc/krb5.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/aphrodite.slapd.keytab root@aphrodite.$DOMAIN:/etc/ldap/aphrodite.slapd.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/hera.host.keytab root@hera.$DOMAIN:/etc/krb5.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/hera.dovecot.keytab root@hera.$DOMAIN:/etc/dovecot/hera.dovecot.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/poseidon.apache2.keytab root@poseidon.$DOMAIN:/etc/apache2/apache2.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/erato.openfire.keytab root@erato.$DOMAIN:/etc/openfire/xmpp.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/gaia.apache2.keytab root@gaia.$DOMAIN:/etc/apache2/apache2.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/trident.apache2.keytab root@trident.$DOMAIN:/etc/apache2/apache2.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/chaos.host.keytab root@chaos.$DOMAIN:/etc/krb5.keytab
scp $RESTORE_DUMP_FOLDER/keytabs/chaos.eseriman_admin.keytab root@chaos.$DOMAIN:/var/lib/eseriman/keytabs/eseriman-admin.keytab

#Setting appropriate ownership

ssh root@athena.$DOMAIN "chown root:root /etc/krb5kdc/kadm5.keytab; exit"
ssh root@aphrodite.$DOMAIN "chown root:root /etc/krb5.keytab; chown root:openldap /etc/ldap/aphrodite.slapd.keytab; exit"
ssh root@hera.$DOMAIN "chown root:root /etc/krb5.keytab; chown root:dovecot /etc/dovecot/hera.dovecot.keytab; exit"
ssh root@poseidon.$DOMAIN "chown www-data:root /etc/apache2/apache2.keytab; exit"
ssh root@erato.$DOMAIN "chown openfire:openfire /etc/openfire/xmpp.keytab; exit"
ssh root@gaia.$DOMAIN "chown www-data:root /etc/apache2/apache2.keytab; exit"
ssh root@trident.$DOMAIN "chown www-data:root /etc/apache2/apache2.keytab; exit"
ssh root@chaos.$DOMAIN "chown root:root /etc/krb5.keytab; exit"
ssh root@chaos.$DOMAIN "chown eseriman:eseriman /var/lib/eseriman/keytabs/eseriman-admin.keytab; exit"

#Restart all the containers - Mandatory
for ORG in $ORG_SERVERS_VO ; do
	HOST=$ORG.$DOMAIN
	echo $HOST
	ssh root@$HOST "/etc/init.d/reboot stop; exit"
done
