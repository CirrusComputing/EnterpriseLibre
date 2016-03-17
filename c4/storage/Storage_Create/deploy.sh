#!/bin/bash
#
# Storage deploy script - v1.3
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
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

SHORTNAME=$(getParameter shortname)
CLOUD_VOLUME_SIZE=$(getParameter volume_size)

chmod +x $ARCHIVE_FOLDER/enterpriselibre_create_lvolume
$ARCHIVE_FOLDER/enterpriselibre_create_lvolume "$SHORTNAME" "$CLOUD_VOLUME_SIZE"
