#!/bin/bash
#
# Network deploy script v1.6
#
# Created by Gregory Wolgemuth <woogie@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

SHORTNAME=$(getParameter shortname)
WAN_IP=$(getParameter wan_ip)
WAN_NETMASK=$(getParameter wan_netmask)
NETWORK=$(getParameter network)

chmod +x $ARCHIVE_FOLDER/enterpriselibre_add_*
$ARCHIVE_FOLDER/enterpriselibre_add_cloud "$SHORTNAME" "$WAN_IP" "$WAN_NETMASK" "$NETWORK.0" "$ARCHIVE_FOLDER" "$TEMPLATE_FOLDER"
