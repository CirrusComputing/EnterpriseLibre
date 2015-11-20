#!/bin/bash
#
# Tesseract-OCR deploy script - v1.0
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
echo "$(date) Deploy TesseractOCR"

# Get the system parameters
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

#################
##### CHAOS #####
#################
if [ $SHORT_NAME == 'chaos' ]; then
    # Add extra repository and import key for it.
    install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/notesalexp-lucid.list
    eseriReplaceValues /etc/apt/sources.list.d/notesalexp-lucid.list
    wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/alex-p.key | apt-key add -
    apt-get update
    aptGetInstall tesseract-ocr
fi

exit 0
