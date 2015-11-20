#!/bin/bash
#
# Backup Config deploy script - v1.1
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
echo "$(date) - Configure Cloud Backup"

OPTION=$(getParameter option)
PROFILE=$(getParameter profile)
FREQUENCY_NUMBER=$(getParameter frequency_number)
FREQUENCY_DURATION=$(getParameter frequency_duration)
TIME=$(getParameter time)
TARGET_URL=$(getParameter target_url)
ENABLED=$(getParameter enabled)
SNAPSHOT=$(getParameter snapshot)

# Get the system parameters
eseriGetDNS
eseriGetNetwork

DEFAULT_PROFILE=profile1
BACKUP_HOME_FOLDER=/var/lib/backup
BACKUP_DUPLY_FOLDER=$BACKUP_HOME_FOLDER/.duply/

FREQUENCY_MINUTE=$(echo $TIME | tr ':' ' ' | awk '{print $2}')
FREQUENCY_HOUR=$(echo $TIME | tr ':' ' ' | awk '{print $1}')
CRONTIME="$FREQUENCY_MINUTE $FREQUENCY_HOUR * * *"

if [ $OPTION == 'add' ]; then
    su - -c "duply $PROFILE create" backup
    install -o backup -g backup -m 644 $BACKUP_DUPLY_FOLDER/$DEFAULT_PROFILE/conf $BACKUP_DUPLY_FOLDER/$PROFILE/conf
    install -o backup -g backup -m 644 $BACKUP_DUPLY_FOLDER/$DEFAULT_PROFILE/exclude $BACKUP_DUPLY_FOLDER/$PROFILE/exclude
    
    ln -s $BACKUP_HOME_FOLDER/bin/pre_backup.sh $BACKUP_DUPLY_FOLDER/$PROFILE/pre

    sed -i "s|TARGET='.*'|TARGET='$TARGET_URL'|g" $BACKUP_DUPLY_FOLDER/$PROFILE/conf
fi

if [ $OPTION == 'add' -o $OPTION == 'edit' ]; then    
    if [ $FREQUENCY_DURATION == 'hour(s)' ]; then
	CRONTIME="$FREQUENCY_MINUTE */$FREQUENCY_NUMBER * * *"
    elif [ $FREQUENCY_DURATION == 'days(s)' ]; then
	CRONTIME="$FREQUENCY_MINUTE $FREQUENCY_HOUR */$FREQUENCY_NUMBER * * *"
    elif [ $FREQUENCY_DURATION == 'week(s)' ]; then
	CRONTIME="$FREQUENCY_MINUTE $FREQUENCY_HOUR */$(($FREQUENCY_NUMBER*7)) * *"
    elif [ $FREQUENCY_DURATION == 'month(s)' ]; then
	CRONTIME="$FREQUENCY_MINUTE $FREQUENCY_HOUR * */$FREQUENCY_NUMBER *"
    fi
        
    crontab -u backup -l > /tmp/backup_crontab
    sed -i "\|$BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE|d" /tmp/backup_crontab
    
    # If enabled, then put in crontab
    if [ $ENABLED == 't' ]; then
	echo "$CRONTIME $BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE" >> /tmp/backup_crontab
    fi
    
    # Change the backup user's crontab
    cat /tmp/backup_crontab | crontab -u backup -
    rm /tmp/backup_crontab
    
    if [ $SNAPSHOT == 't' ]; then
	su - -c "$BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE &" backup
    fi
elif [ $OPTION == 'delete' ]; then
    crontab -u backup -l > /tmp/backup_crontab
    sed -i '\|$BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE|d' /tmp/backup_crontab

    # Change the backup user's crontab
    cat /tmp/backup_crontab | crontab -u backup -
    rm /tmp/backup_crontab
elif [ $OPTION == 'snapshot' ]; then
    su - -c "$BACKUP_HOME_FOLDER/bin/run_backup.sh $PROFILE &" backup
fi
    
exit 0
