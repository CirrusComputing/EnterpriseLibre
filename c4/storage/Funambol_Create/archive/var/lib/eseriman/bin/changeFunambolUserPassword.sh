#!/bin/bash
#
# Eseriman script to be called from C3 to change the password on an existing accoun5 - v1.0
#
# Created by Gregory Wolgemuth <woogie@eseri.com>
#
# Copyright (c) 1996-2010 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

#We need to know the username, and their password
USERNAME=$1
PASSWORD=$2
ORGNAME=`hostname -d`
MAIL_ACCOUNT="$USERNAME@$ORGNAME"

NEW_PASSWORD=`/opt/Funambol/tools/jre-1.6.0/jre/bin/java -cp /opt/Funambol/admin/funamboladmin/modules/ext/server-framework-8.7.0.jar:/opt/Funambol/admin/funamboladmin/modules/ext/log4j-1.2.14.jar:/opt/Funambol/admin/funamboladmin/modules/ext/core-framework-8.7.0.jar:/var/lib/eseriman/bin Encryption2 "$PASSWORD" 2>/dev/null`

echo "UPDATE fnbl_user SET password='$NEW_PASSWORD' WHERE email='$MAIL_ACCOUNT';" | psql -U funambol -h pgsql.$ORGNAME -d funambol
echo "UPDATE fnbl_email_account SET ms_password='$NEW_PASSWORD' WHERE ms_address='$MAIL_ACCOUNT';" | psql -U funambol -h pgsql.$ORGNAME -d funambol
