#!/bin/bash
#
# Nagios deploy script - v1.3
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

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SHORT_DOMAIN=$(getParameter short_domain)
LONGNAME=$(getParameter longname)
NETWORK=$(getParameter network)
HWH_NAME=$(getParameter hardware_hostname)
WAN_IP=$(getParameter wan_ip)
VPS_LIST=$(getParameter vps_list)
CONTAINER_LIST=$(getParameter container_list)

chmod +x $ARCHIVE_FOLDER/create_nagios_config.pl
$ARCHIVE_FOLDER/create_nagios_config.pl --vps_list "$VPS_LIST" --container_list "$CONTAINER_LIST" --system_anchor_domain "$SYSTEM_ANCHOR_DOMAIN" --short_domain "$SHORT_DOMAIN" --longname "$LONGNAME" --network "$NETWORK" --hardware_hostname "$HWH_NAME" --wan_ip "$WAN_IP"

/etc/init.d/nagios3 reload
