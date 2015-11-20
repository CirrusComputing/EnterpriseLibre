#! /usr/bin/awk -f
#
# Change DNS serial number v1.0
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#
/\; serial number \(YYYYMMDD##\)/ {
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
{ print }
