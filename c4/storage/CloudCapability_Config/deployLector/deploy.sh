#!/bin/bash
#
# Lector Deploy script - v1.1
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

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy Lector"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    LECTOR_VERSION=0.3.0-1_i386
    dpkg -i $ARCHIVE_FOLDER/lector/lector_$LECTOR_VERSION.deb
    # Install extra packages that lector requires.
    aptGetInstall python-qt4 python-enchant
    ln -s /usr/bin/lector.pyw /usr/bin/lector
    deploy_start_menu_items 'null' 'lector'
fi

exit 0
