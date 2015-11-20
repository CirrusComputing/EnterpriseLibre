#!/bin/bash
#
# changeVtigerIMAPPassword.sh - v1.1
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

DB_PASSWORD_VTIGER=[-DB_PASSWORD_VTIGER-]

USERNAME=$1
EMAIL_PREFIX=$2
PASSWORD=$3
EMAIL_DOMAIN=$4
IMAP_SERVER=$5
MAIL_LOGIN=$6
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306

echo "UPDATE vtiger_mail_accounts SET mail_password='$PASSWORD' WHERE mail_servername='$IMAP_SERVER' AND mail_username='$MAIL_LOGIN';" | mysql -uvtiger -p$DB_PASSWORD_VTIGER -h$MYSQL_HOST -P$MYSQL_PORT vtiger

exit 0
