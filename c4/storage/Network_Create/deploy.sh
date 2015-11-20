#!/bin/bash
#
# Network deploy script v1.4
#
# Created by Gregory Wolgemuth <woogie@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
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

SHORTNAME=$(getParameter shortname)
WAN_IP=$(getParameter wan_ip)
NETMASK=$(getParameter wan_netmask)
NETWORK=$(getParameter network)

chmod +x $ARCHIVE_FOLDER/cirrus_add_*
$ARCHIVE_FOLDER/cirrus_add_cloud "$SHORTNAME" "$WAN_IP" "$NETMASK" "$NETWORK.0" "$ARCHIVE_FOLDER" "$TEMPLATE_FOLDER"
