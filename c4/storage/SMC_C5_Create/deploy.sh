#!/bin/bash
#
# C5 deploy script - v2.1
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

# Include cirrus functions
. ${0%/*}/archive/eseriCommon

SHORT_DOMAIN=$(getParameter short_domain)
DOMAIN=$(getParameter domain)

# Add to list of clouds in C5
sed -i -e "s/ORGANIZATIONS_VO='\(.*\)'/ORGANIZATIONS_VO='\1 $SHORT_DOMAIN'/" /home/c5/bin/c5.sh

# Update the known hosts list for root
ssh-keyscan -H -t rsa chaos.$DOMAIN 2>/dev/null >> /root/.ssh/known_hosts

# Now run c5.sh
su - -c 'sudo /home/c5/bin/c5.sh' c5
