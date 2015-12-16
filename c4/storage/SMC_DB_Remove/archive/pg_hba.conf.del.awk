#! /usr/bin/awk -f
#
# Remove IP from pg_hba.conf
#
# Created by Karoly Molnar <kmolnar@eseri.com>
#
# Copyright (c) 1996-2010 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
BEGIN { CUSTOMER=0; EXIST=0 }
/^# CUSTOMER - BEGIN$/ { CUSTOMER=1 }
/^# CUSTOMER - END$/ && CUSTOMER { CUSTOMER=0 }
CUSTOMER    { if ( $4 !~ ORG_ACCMGMT_IP ) { print } }
!CUSTOMER   { print }
