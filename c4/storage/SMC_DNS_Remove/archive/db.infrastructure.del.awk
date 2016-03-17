#! /usr/bin/awk -f
#
# Remove Org from server v1.1
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
BEGIN { CUSTOMER=0; EXIST=0; ORG_INCLUDE= "$INCLUDE \"/etc/bind/zones/external/orgs/db." DOMAIN "\"" }
/\; serial number \(YYMMDDHH##\)/ {
  olddate=substr($1,1,8);
  oldserial=substr($1,9,2);
  newdate=strftime("%Y%m%d");
  if (olddate==newdate) {
    newserial=sprintf("%02u",oldserial+1)
    }
  else {
    newserial="01"
  };
  sub( olddate oldserial,newdate newserial, $0 );
  }
/^; CUSTOMER MX - BEGIN$/ { CUSTOMER=1 }
/^; CUSTOMER MX - END$/ && CUSTOMER { CUSTOMER=0 }
CUSTOMER    { if ( $0 != ORG_INCLUDE ) { print } }
!CUSTOMER   { print }
