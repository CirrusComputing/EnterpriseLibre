#!/bin/bash
#
# Amanda Pre-Backup Script v1.6 - This script create database dumps, 
# copies keytabs, and also application data, which are required 
# for a full organization restore.
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

NOW=$(date +"%Y%m%d")
DOMAIN=$(hostname -d)
MYSQL_PASSWORD=[-MYSQLPW-]
ORG_VO='zeus hermes athena aphrodite hades hera poseidon cronus erato gaia trident plutus chaos'
ERROR_EMAIL='sysadmin@[-SYSTEM_ANCHOR_DOMAIN-]'
ERROR_MSG=""
DUMP_DIR=/tmp/dumps

COMMAND_zeus_1="ssh root@zeus.$DOMAIN '[ -d \"/etc/bind\" ] && tar czf - /etc/bind || exit 0' > $DUMP_DIR/zeusBackupBind.tar.gz 2>/dev/null"

COMMAND_hermes_1="ssh root@hermes.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $DUMP_DIR/hermesBackupApache.tar.gz 2>/dev/null"
COMMAND_hermes_2="ssh root@hermes.$DOMAIN '[ -d \"/etc/shorewall\" ] && tar czf - /etc/shorewall || exit 0' > $DUMP_DIR/hermesBackupShorewall.tar.gz 2>/dev/null"

COMMAND_athena_1="ssh root@athena.$DOMAIN 'kdb5_util dump | gzip -c' > $DUMP_DIR/athenaKrbDump-$NOW.gz"
COMMAND_athena_2="if [ -z \$(gzip -cd $DUMP_DIR/athenaKrbDump-$NOW.gz | head -c1) ]; then false; fi"
COMMAND_athena_3="ssh root@athena.$DOMAIN '/usr/sbin/slapcat | gzip -c' > $DUMP_DIR/athenaLdapDump-$NOW.ldif.gz"
COMMAND_athena_5="if [ -z \$(gzip -cd $DUMP_DIR/athenaLdapDump-$NOW.ldif.gz | head -c1) ]; then false; fi"

COMMAND_aphrodite_1="ssh root@aphrodite.$DOMAIN '/usr/sbin/slapcat | gzip -c' > $DUMP_DIR/aphroditeLdapDump-$NOW.ldif.gz"
COMMAND_aphrodite_2="if [ -z \$(gzip -cd $DUMP_DIR/aphroditeLdapDump-$NOW.ldif.gz | head -c1) ]; then false; fi"

COMMAND_hades_1="ssh root@hades.$DOMAIN 'su - -c \"pg_dumpall -c -U postgres | gzip -c\" postgres' > $DUMP_DIR/hadesPgsqlDump-$NOW.sql.gz"
COMMAND_hades_2="if [ -z \$(gzip -cd $DUMP_DIR/hadesPgsqlDump-$NOW.sql.gz | head -c1) ]; then false; fi"
COMMAND_hades_3="ssh root@hades.$DOMAIN \"mysqldump --user=root --password=$MYSQL_PASSWORD -A | gzip -c\" > $DUMP_DIR/hadesMysqlDump-$NOW.sql.gz"
COMMAND_hades_4="if [ -z \$(gzip -cd $DUMP_DIR/hadesMysqlDump-$NOW.sql.gz | head -c1) ]; then false; fi"

COMMAND_hera_1="ssh root@hera.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $DUMP_DIR/heraBackupApache.tar.gz 2>/dev/null"
COMMAND_hera_2="ssh root@hera.$DOMAIN '[ -d \"/var/lib/mailman\" ] && tar czf - /var/lib/mailman || exit 0' > $DUMP_DIR/backupMailingLists.tar.gz 2>/dev/null"
COMMAND_hera_3="ssh root@hera.$DOMAIN '[ -f \"/etc/davmail.properties\" ] && tar czf - /etc/davmail.properties || exit 0' > $DUMP_DIR/heraBackupDavmail.tar.gz 2>/dev/null"
COMMAND_hera_4="ssh root@hera.$DOMAIN '[ -d \"/var/spool/dspam\" ] && tar czf - /var/spool/dspam || exit 0' > $DUMP_DIR/heraBackupDspam.tar.gz 2>/dev/null"

COMMAND_poseidon_1="ssh root@poseidon.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $DUMP_DIR/poseidonBackupApache.tar.gz 2>/dev/null"
COMMAND_poseidon_2="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/vtigercrm\" ] && tar czf - /var/lib/vtigercrm || exit 0' > $DUMP_DIR/backupVtiger.tar.gz 2>/dev/null"
COMMAND_poseidon_3="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/mediawiki\" ] && tar czf - /var/lib/mediawiki || exit 0' > $DUMP_DIR/backupWiki.tar.gz 2>/dev/null"
COMMAND_poseidon_4="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/trac\" ] && tar czf - /var/lib/trac || exit 0' > $DUMP_DIR/backupTrac.tar.gz 2>/dev/null"
COMMAND_poseidon_5="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/timesheet\" ] && tar czf - /var/lib/timesheet || exit 0' > $DUMP_DIR/backupTimesheet.tar.gz 2>/dev/null"
COMMAND_poseidon_6="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/orangehrm\" ] && tar czf - /var/lib/orangehrm || exit 0' > $DUMP_DIR/backupOrangeHRM.tar.gz 2>/dev/null"
COMMAND_poseidon_7="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/sql-ledger\" ] && tar czf - /var/lib/sql-ledger || exit 0' > $DUMP_DIR/backupSQLLedger.tar.gz 2>/dev/null"

COMMAND_cronus_1="ssh root@cronus.$DOMAIN '[ -d \"/var/lib/nuxeo/server\" ] && tar czf - /var/lib/nuxeo/server || exit 0' > $DUMP_DIR/backupNuxeo.tar.gz 2>/dev/null"

COMMAND_gaia_1="ssh root@gaia.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $DUMP_DIR/gaiaBackupApache.tar.gz 2>/dev/null"

COMMAND_trident_1="ssh root@trident.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $DUMP_DIR/tridentBackupApache.tar.gz 2>/dev/null"
COMMAND_trident_2="ssh root@trident.$DOMAIN '[ -d \"/usr/share/redmine\" ] && tar czf - /usr/share/redmine || exit 0' > $DUMP_DIR/backupRedmine.tar.gz 2>/dev/null"
COMMAND_trident_3="ssh root@trident.$DOMAIN '[ -d \"/var/lib/phpscheduleit\" ] && tar czf - /var/lib/phpscheduleit || exit 0' > $DUMP_DIR/backupPHPScheduleIt.tar.gz 2>/dev/null"
COMMAND_trident_4="ssh root@trident.$DOMAIN '[ -d \"/var/lib/drupal\" ] && tar czf - /var/lib/drupal || exit 0' > $DUMP_DIR/backupDrupal.tar.gz 2>/dev/null"
COMMAND_trident_5="ssh root@trident.$DOMAIN '[ -d \"/var/lib/moodle\" ] && tar czf - /var/lib/moodle /var/lib/moodledata || exit 0' > $DUMP_DIR/backupMoodle.tar.gz 2>/dev/null"
COMMAND_trident_6="ssh root@trident.$DOMAIN '[ -d \"/usr/lib/pymodules/python2.7/openerp\" ] && tar czf - /usr/lib/pymodules/python2.7 /var/lib/openerp || exit 0' > $DUMP_DIR/backupOpenERP.tar.gz 2>/dev/null"

rm -rf $DUMP_DIR
mkdir -p $DUMP_DIR

for ORG in $ORG_VO ; do
	FULL_HOSTNAME=$ORG.$DOMAIN
	# Check if host exists.
	host $FULL_HOSTNAME > /dev/null
	[ $? -ne 0 ] && continue
	
	# Clearing SSH known hosts for target host.
	ssh-keygen -R $FULL_HOSTNAME 2>/dev/null
	ssh-keygen -R $(host $FULL_HOSTNAME |  grep 'has address' | awk '{print $4}') 2>/dev/null

	# Acquiring SSH fingerprint for target host.
	ssh-keyscan -t rsa -H $FULL_HOSTNAME >> /var/lib/amanda/.ssh/known_hosts 2>/dev/null
	ssh-keyscan -t rsa -H $(host $FULL_HOSTNAME | grep 'has address' | awk '{print $4}') >> /var/lib/amanda/.ssh/known_hosts 2>/dev/null

	i=0
	while(true); do
	    i=`expr $i + 1`
	    COMMAND=COMMAND_${ORG}_${i}
	    # Check is COMMAND variable exists.
	    if [[ -z "${!COMMAND}" ]]; then
		break
	    fi

	    # If exists then execute it.
	    eval "${!COMMAND}"
	    
            # Check return code.
	    if [ $((`echo ${PIPESTATUS[@]} | sed 's| | + |'`)) -ne 0 ]; then
		ERROR_MSG+="Amanda pre-dump script failed on $FULL_HOSTNAME with command below -\n${!COMMAND}\n\n"
	    fi
	done
done

# Remove 0 byte files (generated if file/folder does not exist and you try to do a tar)
find $DUMP_DIR -size 0 -exec rm {} \;

# If any error was encountered, then send mail.
if [[ -n "$ERROR_MSG" ]]; then
    MSG="To: $ERROR_EMAIL\nSubject:Amanda Pre-Dump Error on $DOMAIN\n\n$ERROR_MSG"
    ssh root@poseidon.$DOMAIN "echo -e \"$MSG\" | sendmail -t"
fi

exit 0
