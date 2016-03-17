#!/bin/bash
#
# createVtigerIMAPPassword.sh - v1.1 
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

DB_PASSWORD_VTIGER=[-DB_PASSWORD_VTIGER-]

USERNAME=$1
EMAIL_PREFIX=$2
PASSWORD=$3
FIRSTNAME=$4
LASTNAME=$5
EMAIL_DOMAIN=$6
IMAP_SERVER=$7
MAIL_LOGIN=$8
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306

NEXT_ID=`echo "SELECT COALESCE(MAX(account_id) + 1,1) FROM vtiger_mail_accounts;" | mysql -uvtiger -p$DB_PASSWORD_VTIGER -h$MYSQL_HOST -P$MYSQL_PORT vtiger | awk 'NR==2' | sed "s|^.* ||"`

echo "INSERT INTO vtiger_mail_accounts (account_id, user_id, display_name, mail_id, account_name, mail_protocol, mail_username, mail_password, mail_servername, box_refresh, mails_per_page, ssltype, sslmeth, int_mailer, status, set_default) VALUES ( $NEXT_ID, (SELECT id FROM vtiger_users WHERE user_name = '$USERNAME'), '$FIRSTNAME $LASTNAME', '$EMAIL_PREFIX@$EMAIL_DOMAIN', NULL, 'IMAP4', '$MAIL_LOGIN', '$PASSWORD', '$IMAP_SERVER', 60000, 0, 'ssl', 'novalidate-cert', NULL, 1, 0);" | mysql -uvtiger -p$DB_PASSWORD_VTIGER -h$MYSQL_HOST -P$MYSQL_PORT vtiger

if [ $NEXT_ID == "1" ]; then
    echo "Adding superuser"
else
    echo "Adding normal user"
fi

exit 0
