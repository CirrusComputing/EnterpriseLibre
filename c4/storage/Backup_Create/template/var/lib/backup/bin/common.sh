#!/bin/bash
#
# Common Script v1.1 - Common functions 
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

DOMAIN=$(hostname -d)
BACKUP_HOME_FOLDER=/var/lib/backup
BACKUP_CACHE_FOLDER=$BACKUP_HOME_FOLDER/.cache/duplicity
BACKUP_SRC_FOLDER=$BACKUP_HOME_FOLDER/files
MOUNT_CONTAINERS=("chaos" "hera")
MOUNT_SRC_FOLDERS=("/home" "/var/spool/vmail")
MOUNT_DST_FOLDERS=("$BACKUP_SRC_FOLDER/chaos" "$BACKUP_SRC_FOLDER/hera")
ERROR_EMAIL='sysadmin@lists.cirruscomputing.com'

acquire_ssh_fingerprint()
{
    FULL_HOSTNAME=$1
    # Clearing SSH known hosts for target host.
    ssh-keygen -R $FULL_HOSTNAME &>/dev/null
    ssh-keygen -R $(host $FULL_HOSTNAME |  grep 'has address' | awk '{print $4}') &>/dev/null
    
    # Acquiring SSH fingerprint for target host.
    ssh-keyscan -t rsa -H $FULL_HOSTNAME >> $BACKUP_HOME_FOLDER/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa -H $(host $FULL_HOSTNAME | grep 'has address' | awk '{print $4}') >> $BACKUP_HOME_FOLDER/.ssh/known_hosts 2>/dev/null
}

mount_folders()
{
    for (( i=0; i<${#MOUNT_CONTAINERS[@]}; i++ )); do
	MOUNT_CONTAINER=${MOUNT_CONTAINERS[$i]}
	MOUNT_SRC_FOLDER=${MOUNT_SRC_FOLDERS[$i]}
	MOUNT_DST_FOLDER=${MOUNT_DST_FOLDERS[$i]}
	FULL_HOSTNAME=$MOUNT_CONTAINER.$DOMAIN
	mkdir -p $MOUNT_DST_FOLDER
	acquire_ssh_fingerprint $FULL_HOSTNAME
	sshfs root@$FULL_HOSTNAME:$MOUNT_SRC_FOLDER $MOUNT_DST_FOLDER 2>/dev/null
    done
}

send_email()
{
    echo -e "$1" | /usr/sbin/sendmail -t
}
