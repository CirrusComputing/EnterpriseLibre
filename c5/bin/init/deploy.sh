#!/bin/bash
#
# C5 Init Deploy Script - v1.0
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

C5_HOME_FOLDER=/home/c4
C5_BIN_FOLDER=$C5_HOME_FOLDER/bin
CRON_WEEKLY_CONFIG_FOLDER=/etc/cron.weekly
SUDOERS_CONFIG_FOLDER=/etc/sudoers.d

ln -s $C5_BIN_DIR/init/$CRON_WEEKLY_CONFIG_FOLDER/c5 $CRON_WEEKLY_CONFIG_FOLDER/c5
ln -s $C5_BIN_DIR/init/$SUDOERS_CONFIG_FOLDER/c5 $SUDOERS_CONFIG_FOLDER/c5

exit 0
