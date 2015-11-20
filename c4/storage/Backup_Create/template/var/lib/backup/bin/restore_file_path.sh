#!/bin/bash
#
# Restore File Path Script v1.0 - This script restore a path from a backup profile.
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

if [ $# -ne 5 ]; then
        echo "Usage: $0 <USERNAME> <PROFILE_ID> <TIME> <SOURCE> <DESTINATION>"
	echo "<USERNAME> - superuser"
	echo "<PROFILE_ID> - 1"
	echo "<TIME> - Mon May 11 11:01:07 2015"
	echo "<SOURCE> - chaos/superuser/Documents/EseriUsage.log"
	echo "<DESTINATION> - Restore/2015-05-11T21:18:32/EseriUsage.log"
        exit 1
fi

# Include common functions
. ~/bin/common.sh

USERNAME=$1
PROFILE_ID=$2
TIME=$3
SOURCE=$4
DESTINATION=$5

DUPLY_PROFILE_FOLDER=/tmp/.duply/profile$PROFILE_ID
# Get's Restore/ from DESTINATION
RESTORE_BASE_FOLDER=$(echo "$DESTINATION" | awk -F'/' '{print $1}')
# Get's Restore/2015-05-11T21:18:32/ from DESTINATION
RESTORE_FOLDER=$(echo "$DESTINATION" | sed 's|\(.*\)/.*|\1|')

mkdir -p $DUPLY_PROFILE_FOLDER
lockfile -300 -r-1 $DUPLY_PROFILE_FOLDER/lock
if [ $? -ne 0 ] ; then
        exit 1
fi

echo -e "\n$USERNAME\n$PROFILE_ID\n$TIME\n$SOURCE\n$DESTINATION\n"

DOMAIN=$(hostname -d)
NOW=$(date +%FT%T)
EPOCH_TIME=$(date -d "$TIME" +%s)

mount_folders
ssh root@chaos.$DOMAIN "mkdir -p /home/$USERNAME/$RESTORE_FOLDER"
duply profile$PROFILE_ID fetch "$SOURCE" "$BACKUP_SRC_FOLDER/chaos/$USERNAME/$DESTINATION/" "$EPOCH_TIME"
ssh root@chaos.$DOMAIN "chown -R $USERNAME:$USERNAME /home/$USERNAME/$RESTORE_BASE_FOLDER"

rm -f $DUPLY_PROFILE_FOLDER/lock

exit 0
