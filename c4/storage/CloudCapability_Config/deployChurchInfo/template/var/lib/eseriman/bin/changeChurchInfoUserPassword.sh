#!/bin/bash
#
# changeChurchInfoUserPassword.sh - v1.0
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com> 
#
# Copyright (c) 1996-2013 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

DB_PASSWORD_CHURCHINFO=[-DB_PASSWORD_CHURCHINFO-]

USERNAME=$1
PASSWORD=$2
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306

echo "UPDATE user_usr SET usr_Password = '$PASSWORD' WHERE usr_UserName = '$USERNAME';" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo

exit 0
