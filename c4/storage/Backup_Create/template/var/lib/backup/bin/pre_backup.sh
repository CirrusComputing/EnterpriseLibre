#!/bin/bash
#
# Pre-Backup Script v1.4 - This script mounts the various folder 
# from other containers and prepares the backup.
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

# Include common functions
. ~/bin/common.sh

DB_PASSWORD_MYSQL=[-DB_PASSWORD_MYSQL-]
CONTAINER_LIST="[-CONTAINER_LIST-]"
BACKUP_SERVER=$(sed -n "s/^TARGET='\(.*\)'/\1/p" ${0%/*}/conf | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")
BACKUP_SCHEME=$(sed -n "s/^TARGET='\(.*\)'/\1/p" ${0%/*}/conf | awk -F: '{print $1}')
BACKUP_PROFILE=$(echo "${0%/*}" | tr '/' ' ' | awk '{print $NF}')
ERROR_MSG=""
CLOUD_DATA_BACKUP_FOLDER=$BACKUP_SRC_FOLDER/system
DUPLY_TMP_FOLDER=/tmp/.duply

COMMAND_zeus_1="ssh root@zeus.$DOMAIN '[ -d \"/etc/bind\" ] && tar czf - /etc/bind || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/zeusBackupBind.tar.gz 2>/dev/null"

COMMAND_hermes_1="ssh root@hermes.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/hermesBackupApache.tar.gz 2>/dev/null"
COMMAND_hermes_2="ssh root@hermes.$DOMAIN '[ -d \"/etc/shorewall\" ] && tar czf - /etc/shorewall || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/hermesBackupShorewall.tar.gz 2>/dev/null"

COMMAND_apollo_1="ssh root@apollo.$DOMAIN '[ -d \"$BACKUP_HOME_FOLDER\" ] && tar czf - $BACKUP_HOME_FOLDER/bin $BACKUP_HOME_FOLDER/.gnupg/ $BACKUP_HOME_FOLDER/.duply || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/apolloBackupDuplicity.tar.gz 2>/dev/null"

COMMAND_athena_1="ssh root@athena.$DOMAIN 'kdb5_util dump | gzip -c' > $CLOUD_DATA_BACKUP_FOLDER/athenaKrbDump.gz"
COMMAND_athena_2="if [ -z \$(gzip -cd $CLOUD_DATA_BACKUP_FOLDER/athenaKrbDump.gz | head -c1) ]; then false; fi"
COMMAND_athena_3="ssh root@athena.$DOMAIN '/usr/sbin/slapcat | gzip -c' > $CLOUD_DATA_BACKUP_FOLDER/athenaLdapDump.ldif.gz"
COMMAND_athena_5="if [ -z \$(gzip -cd $CLOUD_DATA_BACKUP_FOLDER/athenaLdapDump.ldif.gz | head -c1) ]; then false; fi"

COMMAND_aphrodite_1="ssh root@aphrodite.$DOMAIN '/usr/sbin/slapcat | gzip -c' > $CLOUD_DATA_BACKUP_FOLDER/aphroditeLdapDump.ldif.gz"
COMMAND_aphrodite_2="if [ -z \$(gzip -cd $CLOUD_DATA_BACKUP_FOLDER/aphroditeLdapDump.ldif.gz | head -c1) ]; then false; fi"

COMMAND_hades_1="ssh root@hades.$DOMAIN 'su - -c \"pg_dumpall -c -U postgres | gzip -c\" postgres' > $CLOUD_DATA_BACKUP_FOLDER/hadesPgsqlDump.sql.gz"
COMMAND_hades_2="if [ -z \$(gzip -cd $CLOUD_DATA_BACKUP_FOLDER/hadesPgsqlDump.sql.gz | head -c1) ]; then false; fi"
COMMAND_hades_3="ssh root@hades.$DOMAIN \"mysqldump --user=root --password=$DB_PASSWORD_MYSQL -A | gzip -c\" > $CLOUD_DATA_BACKUP_FOLDER/hadesMysqlDump.sql.gz"
COMMAND_hades_4="if [ -z \$(gzip -cd $CLOUD_DATA_BACKUP_FOLDER/hadesMysqlDump.sql.gz | head -c1) ]; then false; fi"

# Don't check if file generated using command below is empty, because if there are no hardlinks, it will be empty.
COMMAND_hera_1="ssh root@hera.$DOMAIN 'find /var/spool/vmail -type f -links +1 -printf \"%i %h/%f\n\" | sort | gzip -c' > $CLOUD_DATA_BACKUP_FOLDER/heraHardlinkDump.txt.gz"
COMMAND_hera_2="ssh root@hera.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/heraBackupApache.tar.gz 2>/dev/null"
COMMAND_hera_3="ssh root@hera.$DOMAIN '[ -d \"/var/lib/mailman\" ] && tar czf - /var/lib/mailman || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupMailingLists.tar.gz 2>/dev/null"
COMMAND_hera_4="ssh root@hera.$DOMAIN '[ -f \"/etc/davmail.properties\" ] && tar czf - /etc/davmail.properties || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/heraBackupDavmail.tar.gz 2>/dev/null"
COMMAND_hera_5="ssh root@hera.$DOMAIN '[ -d \"/var/spool/dspam\" ] && tar czf - /var/spool/dspam || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/heraBackupDspam.tar.gz 2>/dev/null"

COMMAND_poseidon_1="ssh root@poseidon.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/poseidonBackupApache.tar.gz 2>/dev/null"
COMMAND_poseidon_2="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/vtigercrm\" ] && tar czf - /var/lib/vtigercrm || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupVtiger.tar.gz 2>/dev/null"
COMMAND_poseidon_3="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/mediawiki\" ] && tar czf - /var/lib/mediawiki || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupWiki.tar.gz 2>/dev/null"
COMMAND_poseidon_4="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/trac\" ] && tar czf - /var/lib/trac || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupTrac.tar.gz 2>/dev/null"
COMMAND_poseidon_5="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/timesheet\" ] && tar czf - /var/lib/timesheet || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupTimesheet.tar.gz 2>/dev/null"
COMMAND_poseidon_6="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/orangehrm\" ] && tar czf - /var/lib/orangehrm || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupOrangeHRM.tar.gz 2>/dev/null"
COMMAND_poseidon_7="ssh root@poseidon.$DOMAIN '[ -d \"/var/lib/sql-ledger\" ] && tar czf - /var/lib/sql-ledger || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupSQLLedger.tar.gz 2>/dev/null"

COMMAND_cronus_1="ssh root@cronus.$DOMAIN '[ -d \"/var/lib/nuxeo/server\" ] && tar czf - /var/lib/nuxeo/server || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupNuxeo.tar.gz 2>/dev/null"

COMMAND_gaia_1="ssh root@gaia.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/gaiaBackupApache.tar.gz 2>/dev/null"

COMMAND_trident_1="ssh root@trident.$DOMAIN '[ -d \"/etc/apache2\" ] && tar czf - /etc/apache2 || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/tridentBackupApache.tar.gz 2>/dev/null"
COMMAND_trident_2="ssh root@trident.$DOMAIN '[ -d \"/usr/share/redmine\" ] && tar czf - /usr/share/redmine || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupRedmine.tar.gz 2>/dev/null"
COMMAND_trident_3="ssh root@trident.$DOMAIN '[ -d \"/var/lib/phpscheduleit\" ] && tar czf - /var/lib/phpscheduleit || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupPHPScheduleIt.tar.gz 2>/dev/null"
COMMAND_trident_4="ssh root@trident.$DOMAIN '[ -d \"/var/lib/drupal\" ] && tar czf - /var/lib/drupal || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupDrupal.tar.gz 2>/dev/null"
COMMAND_trident_5="ssh root@trident.$DOMAIN '[ -d \"/var/lib/moodle\" ] && tar czf - /var/lib/moodle /var/lib/moodledata || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupMoodle.tar.gz 2>/dev/null"
COMMAND_trident_6="ssh root@trident.$DOMAIN '[ -d \"/usr/lib/pymodules/python2.7/openerp\" ] && tar czf - /usr/lib/pymodules/python2.7 /var/lib/openerp || exit 0' > $CLOUD_DATA_BACKUP_FOLDER/backupOpenERP.tar.gz 2>/dev/null"

# Don't check if file generated using command below is empty, because if there are no hardlinks, it will be empty.
COMMAND_chaos_1="ssh root@chaos.$DOMAIN 'find /home -type f -links +1 -printf \"%i %h/%f\n\" | sort | gzip -c' > $CLOUD_DATA_BACKUP_FOLDER/chaosHardlinkDump.txt.gz"

cloud_data_backup()
{
    for CONTAINER in $CONTAINER_LIST ; do
	FULL_HOSTNAME=$CONTAINER.$DOMAIN
	# Check if host exists.
	host $FULL_HOSTNAME > /dev/null
	[ $? -ne 0 ] && continue
	
	acquire_ssh_fingerprint $FULL_HOSTNAME

	i=0
	while(true); do
	    i=`expr $i + 1`
	    COMMAND=COMMAND_${CONTAINER}_${i}
	    # Check is COMMAND variable exists.
	    if [[ -z "${!COMMAND}" ]]; then
		break
	    fi

	    # If exists then execute it.
	    eval "${!COMMAND}"
	    
            # Check return code.
	    if [ $((`echo ${PIPESTATUS[@]} | sed 's| | + |'`)) -ne 0 ]; then
		ERROR_MSG+="Pre-backup script failed on $FULL_HOSTNAME with command below -\n${!COMMAND}\n\n"
	    fi
	done
    done

    # Remove 0 byte files (generated if file/folder does not exist and you try to do a tar)
    find $CLOUD_DATA_BACKUP_FOLDER -size 0 -exec rm {} \;

    # If any error was encountered, then send mail.
    [[ -n "$ERROR_MSG" ]] && send_email "To: $ERROR_EMAIL\nSubject:Pre-Backup Script Error for $BACKUP_PROFILE on $DOMAIN\n\n$ERROR_MSG"
}

# Main
# Wait 2 mins between attempts to acquire lock.
lockfile -120 -r-1 $DUPLY_TMP_FOLDER/pre.lock
if [ $? -ne 0 ]; then
    send_email "To: $ERROR_EMAIL\nSubject: Pre-Backup Script Error for $BACKUP_PROFILE on $DOMAIN\n\nFailed to acquire lock."
    exit 1
fi

mount_folders

rm -rf $CLOUD_DATA_BACKUP_FOLDER
mkdir -p $CLOUD_DATA_BACKUP_FOLDER

cloud_data_backup

if [ $BACKUP_SCHEME == 'ssh' -o $BACKUP_SCHEME == 'sftp' -o $BACKUP_SCHEME == 'scp' -o $BACKUP_SCHEME == 'rsync' ]; then
    # Add ssh-key for backup server to known_hosts file
    acquire_ssh_fingerprint $BACKUP_SERVER
fi

rm -f $DUPLY_TMP_FOLDER/pre.lock