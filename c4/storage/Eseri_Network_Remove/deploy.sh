#!/bin/bash
#
# Network cleanup script v1.0
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Remove the network (and IP, if applicable), bridge and routes from HWH"

# Check for proper number of parameters
if [ $# -ne "3" ]; then
    echo "Usage: $SCRIPT_NAME SHORTNAME WAN_IP BRIDGE"
    echo "Example: $SCRIPT_NAME a1079 1.2.3.4 br1079"
    exit 1
fi

SHORTNAME=$1
WAN_IP=$2
BRIDGE=$3

chmod +x $ARCHIVE_FOLDER/cirrus_del_*
$ARCHIVE_FOLDER/cirrus_del_cloud "$SHORTNAME" "$WAN_IP" "$BRIDGE" "$ARCHIVE_FOLDER" "$TEMPLATE_FOLDER"
