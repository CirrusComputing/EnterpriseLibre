#!/bin/bash
#
# C3 Daemons Deploy Script - v1.1
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

C3_HOME_FOLDER=/home/c3
C3_BIN_FOLDER=$C3_HOME_FOLDER/bin
INIT_CONFIG_FOLDER=/etc/init.d
LOGROTATE_CONFIG_FOLDER=/etc/logrotate.d
INIT_CONFIG_FILES=(c3X c3server c3sysman)
LOGROTATE_CONFIG_FILES=(c3 c3sysman)

for (( i=0; i<${#INIT_CONFIG_FILES[@]}; i++ )); do
    INIT_CONFIG_FILE=${INIT_CONFIG_FILES[$i]}
    ln -s $C3_BIN_FOLDER/init/$INIT_CONFIG_FOLDER/$INIT_CONFIG_FILE $INIT_CONFIG_FOLDER/$INIT_CONFIG_FILE
    update-rc.d $INIT_CONFIG_FILE defaults
    $INIT_CONFIG_FOLDER/$INIT_CONFIG_FILE start
done

for (( i=0; i<${#LOGROTATE_CONFIG_FILES[@]}; i++ )); do
    LOGROTATE_CONFIG_FILE=${LOGROTATE_CONFIG_FILES[$i]}
    ln -s $C3_BIN_FOLDER/init/$LOGROTATE_CONFIG_FOLDER/$LOGROTATE_CONFIG_FILE $LOGROTATE_CONFIG_FOLDER/$LOGROTATE_CONFIG_FILE
done

exit 0
