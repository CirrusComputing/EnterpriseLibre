#!/bin/bash
#
# Backup Script v1.6 - This script backs up the duply profile.
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

PROFILE=$1

# Include common functions.
. ~/bin/common.sh

DUPLY_TMP_FOLDER=/tmp/.duply/$PROFILE

# Create a lock at desktop container right at the start as an indication to the cloud manager that backup process has been initiated, so that duplicate 'snapshot' requests from user are blocked.
acquire_ssh_fingerprint chaos.$DOMAIN
ssh root@chaos.$DOMAIN "mkdir -p $DUPLY_TMP_FOLDER"
ssh root@chaos.$DOMAIN "touch $DUPLY_TMP_FOLDER/lock"

mkdir -p $DUPLY_TMP_FOLDER

# Wait 15 mins between attempts to acquire lock.
lockfile -900 -r-1 $DUPLY_TMP_FOLDER/lock
if [ $? -ne 0 ]; then
    send_email "To: $ERROR_EMAIL\nSubject: Run-Backup Script Error for $PROFILE on $DOMAIN\n\nFailed to acquire lock."
    exit 1
fi

# Fail-proof.
# If script acquired lock, then we check if duply is running for the profile. Check for about 15 mins before exiting script.
TIME=0
TIMEOUT=900
while true; do
    ps -aef | grep "/usr/bin/duply $PROFILE" | grep -v grep >/dev/null
    [ $? -eq 1 ] && break
    sleep 30
    TIME=$(expr $TIME + 30)
    if [ $TIME -ge $TIMEOUT ]; then 
	send_email "To: $ERROR_EMAIL\nSubject: Run-Backup Script Error for $PROFILE on $DOMAIN\n\nAcquired lock, but duply is currently running. Something's up!"
	exit 1
    fi
done

# Remove lockfile created by duplicity if exists. We do this because on a cloud reboot (while backup is running), the lockfile is not removed since the container is abruptly restarted.
rm -f $BACKUP_CACHE_FOLDER/duply_$PROFILE/lockfile.lock

duply $PROFILE backup >> /var/log/duply/$PROFILE.log 2>&1
duply $PROFILE purge --force >> /var/log/duply/$PROFILE.log 2>&1

duply $PROFILE status | ssh root@chaos.$DOMAIN "cat > $DUPLY_TMP_FOLDER/summary"
duply $PROFILE list | ssh root@chaos.$DOMAIN "cat > $DUPLY_TMP_FOLDER/path_list"
ssh root@chaos.$DOMAIN "rm -f $DUPLY_TMP_FOLDER/lock"

rm -f $DUPLY_TMP_FOLDER/lock

exit 0