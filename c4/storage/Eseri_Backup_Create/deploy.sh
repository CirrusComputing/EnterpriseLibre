#!/bin/bash
#
# Eseri Backup deploy script - v1.0
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
echo "$(date) - Configure Eseri Backup Server"

SHORT_DOMAIN=$(getParameter short_domain)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

BACKUP_USER=backup-$SHORT_DOMAIN
BACKUP_HOME_FOLDER=/var/lib/backup/duplicity/$BACKUP_USER

# Add user.
adduser $BACKUP_USER --ingroup sftpaccess --home $BACKUP_HOME_FOLDER --shell /bin/bash --disabled-password --gecos ''

# Create .ssh directory.
su - -c "mkdir -p $BACKUP_HOME_FOLDER/.ssh" $BACKUP_USER; 

# Install the regular authorized_keys file.
install -o $BACKUP_USER -g sftpaccess -m 500 $ARCHIVE_FOLDER/root/ssh/authorized_keys $BACKUP_HOME_FOLDER/.ssh/authorized_keys

# Copy the cloud backup key into authorized keys file.
cat $ARCHIVE_FOLDER/backup.public_id_rsa.key >> $BACKUP_HOME_FOLDER/.ssh/authorized_keys

# Create www directory for all the uploads.
su - -c "mkdir -p $BACKUP_HOME_FOLDER/www" $BACKUP_USER

# Change ownership of the users home folder to root (required for sftp access)
chown root:root $BACKUP_HOME_FOLDER

# Change shell for user so that SSH access is disabled
chsh -s /usr/sbin/nologin $BACKUP_USER

exit 0
