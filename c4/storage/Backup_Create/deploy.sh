#!/bin/bash
#
# Backup deploy script - v2.2
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include cirrus functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy Cloud Backup Server"

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SHORTNAME=$(getParameter shortname)
DUPLY_TARGET_URL=$(getParameter backup_target_url)
CONTAINER_LIST=$(getParameter container_list)

DB_PASSWORD_MYSQL=$(getPassword DB_PASSWORD_MYSQL)
GPG_PASSWORD_BACKUP=$(getPassword GPG_PASSWORD_BACKUP)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

PROFILE=profile1
DUPLY_EXECUTABLE=/usr/bin/duply
BACKUP_HOME_FOLDER=/var/lib/backup
BACKUP_SRC_FOLDER=$BACKUP_HOME_FOLDER/files
BACKUP_DUPLY_FOLDER=$BACKUP_HOME_FOLDER/.duply/
DUPLY_LOG_FOLDER=/var/log/duply

# Install the lastest stable package of duplicity that was compiled for trusty.
dpkg -i $ARCHIVE_FOLDER/packages/duplicity/duplicity_0.6.26-1_i386.deb
# Install dependencies by fixing missing packages required by duplicity
aptGetInstall -f
# Install duply
aptGetInstall duply
# Install packages for different schemes
aptGetInstall python-lockfile ncftp python-paramiko python-cloudfiles python-boto rsync tahoe-lafs
# Install procmail that consists of the lockfile binary used in run_backup.sh
aptGetInstall procmail
# Copy over the latest duply executable
install -o root -g root -m 755 $ARCHIVE_FOLDER/files/$DUPLY_EXECUTABLE $DUPLY_EXECUTABLE

# Install sshfs for mounting of home and hera mail folders
aptGetInstall sshfs

# Change login shell for user backup because it is by default set to /usr/sbin/nologin.
chsh -s /bin/bash backup

# Change backup users home folder
install -o backup -g backup -m 755 -d $BACKUP_HOME_FOLDER
usermod --home $BACKUP_HOME_FOLDER backup

#Creating backup ssh key
su - -c "mkdir -p $BACKUP_HOME_FOLDER/.ssh; cd $BACKUP_HOME_FOLDER/.ssh; ssh-keygen -f id_rsa -N '' -t rsa -q" backup

# Copy this key to Result folder so that we can add it to the backup server.
cat $BACKUP_HOME_FOLDER/.ssh/id_rsa.pub >> $RESULT_FOLDER/backup.public_id_rsa.key

# Configure GNUPG for duply backup singing
cat >$BACKUP_HOME_FOLDER/gnupgkey <<EOF 
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $SHORTNAME Backup
Name-Email: backup@$DOMAIN
Expire-Date: 0
Passphrase: $GPG_PASSWORD_BACKUP
%pubring gnupgkey.pub
%secring gnupgkey.sec
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF

# Generate GPG key.
su - -c "gpg --batch --gen-key $BACKUP_HOME_FOLDER/gnupgkey" backup

# List GPG key.
su - -c "gpg --no-default-keyring --secret-keyring $BACKUP_HOME_FOLDER/gnupgkey.sec --keyring $BACKUP_HOME_FOLDER/gnupgkey.pub --list-secret-keys" backup

# Import the GPG keys.
su - -c "gpg --allow-secret-key-import --import gnupgkey.sec" backup
su - -c "gpg --import gnupgkey.pub" backup

# Remove the key backup files
rm -f $BACKUP_HOME_FOLDER/gnupgkey $BACKUP_HOME_FOLDER/gnupgkey.sec $BACKUP_HOME_FOLDER/gnupgkey.pub

# Get id of imported GPG key.
GPG_KEY_BACKUP_PUBLIC=$(su - -c "gpg --list-secret-keys" backup | awk 'NR==3 {print $2}' | cut -d'/' -f2)
GPG_KEY_BACKUP_PRIVATE=$(su - -c "gpg --list-secret-keys" backup | awk 'NR==5 {print $2}' | cut -d'/' -f2)

# Install bin directory
install -o backup -g backup -m 755 -d $BACKUP_HOME_FOLDER/bin/
install -o backup -g backup -m 755 $TEMPLATE_FOLDER/$BACKUP_HOME_FOLDER/bin/common.sh $BACKUP_HOME_FOLDER/bin/common.sh
install -o backup -g backup -m 755 $TEMPLATE_FOLDER/$BACKUP_HOME_FOLDER/bin/run_backup.sh $BACKUP_HOME_FOLDER/bin/run_backup.sh
install -o backup -g backup -m 755 $TEMPLATE_FOLDER/$BACKUP_HOME_FOLDER/bin/pre_backup.sh $BACKUP_HOME_FOLDER/bin/pre_backup.sh
install -o backup -g backup -m 755 $TEMPLATE_FOLDER/$BACKUP_HOME_FOLDER/bin/restore_file_path.sh $BACKUP_HOME_FOLDER/bin/restore_file_path.sh
install -o backup -g backup -m 755 $TEMPLATE_FOLDER/$BACKUP_HOME_FOLDER/bin/hardlinks.sh $BACKUP_HOME_FOLDER/bin/hardlinks.sh
sed -i -e "s|\[-DB_PASSWORD_MYSQL-\]|$DB_PASSWORD_MYSQL|g" -e "s|\[-CONTAINER_LIST-\]|$CONTAINER_LIST|g" $BACKUP_HOME_FOLDER/bin/pre_backup.sh

# Configure duply
su - -c "duply $PROFILE create" backup
install -o backup -g backup -m 644 $TEMPLATE_FOLDER/transient/duply-conf $BACKUP_DUPLY_FOLDER/$PROFILE/conf
install -o backup -g backup -m 644 $TEMPLATE_FOLDER/transient/duply-exclude $BACKUP_DUPLY_FOLDER/$PROFILE/exclude
eseriReplaceValues $BACKUP_DUPLY_FOLDER/$PROFILE/exclude
ln -s $BACKUP_HOME_FOLDER/bin/pre_backup.sh $BACKUP_DUPLY_FOLDER/$PROFILE/pre
sed -i -e "s|\[-GPG_KEY_BACKUP_PUBLIC-\]|$GPG_KEY_BACKUP_PUBLIC|g" -e "s|\[-GPG_KEY_BACKUP_PRIVATE-\]|$GPG_KEY_BACKUP_PRIVATE|g" -e "s|\[-GPG_PASSWORD_BACKUP-\]|$GPG_PASSWORD_BACKUP|g" -e "s|\[-DUPLY_TARGET_URL-\]|$DUPLY_TARGET_URL|g" -e "s|\[-BACKUP_SRC_FOLDER-\]|$BACKUP_SRC_FOLDER|g" $BACKUP_DUPLY_FOLDER/$PROFILE/conf

#Change the backup user's crontab
echo "0 22 * * * $BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE" | crontab -u backup -

# Set up log directory for Duply profiles
install -o backup -g backup -m 755 -d $DUPLY_LOG_FOLDER

# Set up logrotate for Duply profiles
install -o root -g root -m 644 $ARCHIVE_FOLDER/files/etc/logrotate.d/duply /etc/logrotate.d/duply
logrotate /etc/logrotate.conf

# Configure Nagios NRPE.

# Install script to check if file exists. 
install -o root -g root -m 755 $ARCHIVE_FOLDER/files/usr/local/lib/nagios/plugins/check_file /usr/local/lib/nagios/plugins/check_file

# We check for /dev/fuse since that is the module required for sshfs to work. If the module isn't loaded then the backup configuration will not backup user files at chaos and hera.
cat >>/etc/nagios/nrpe_local.cfg <<EOF
command[check_file]=/usr/local/lib/nagios/plugins/check_file -e /dev/fuse
EOF

# Ignore checking the mounted disks - otherwise it sends sysadmin an email saying access to disk denied.
sed -i '/^command\[check_disk\]/s|\(.*\)|\1 -X fuse.sshfs|' /etc/nagios/nrpe_local.cfg

# Restart Nagios NRPE.
init_process '/etc/init.d/nagios-nrpe-server' 'restart'

exit 0
