#!/bin/bash
#
# SMC central DNS configuration script (after org DNS) - v1.8
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
# TODO: RFC1918 file modifications

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure SMC DNS"

DOMAIN=$(getParameter domain)

# Creating backup
tar -C /etc -czf $RESULT_FOLDER/bind9.tar.gz bind

# Reload Bind
/etc/init.d/bind9 reload

# Wait till the DNS servers talk to each other
TIME=0
TIMEOUT=2000
while true; do
	host zeus.$DOMAIN
	[ $? -eq 0 ] && break
	echo "Time: $TIME sec(s)"
	sleep 1
	TIME=$(expr $TIME + 1)
	[ $TIME -ge $TIMEOUT ] && exit 1
done

exit 0
