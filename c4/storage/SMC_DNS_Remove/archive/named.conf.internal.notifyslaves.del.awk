#! /usr/bin/awk -f
#
# Remove Org from server
#
# Created by Karoly Molnar <kmolnar@eseri.com>
#
# Copyright (c) 1996-2010 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
BEGIN { CUSTOMER=0; EXIST=0 }
/^\/\/ CUSTOMER DNS SERVERS - BEGIN$/ { CUSTOMER=1 }
/^\/\/ CUSTOMER DNS SERVERS - END$/ && CUSTOMER { CUSTOMER=0 }
CUSTOMER    { if ( $0 !~ ORG_DNS_IP ) { print } }
!CUSTOMER   { print }
