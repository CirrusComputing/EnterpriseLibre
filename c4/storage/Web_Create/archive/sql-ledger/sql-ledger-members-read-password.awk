#! /usr/bin/awk -f
#
# Print root password
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
#
# Copyright (c) 1996-2010 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
BEGIN { SECTION=0 }
/^\[root login\]$/ { SECTION=1 }
/^password=/ && SECTION { print; SECTION=0 }
