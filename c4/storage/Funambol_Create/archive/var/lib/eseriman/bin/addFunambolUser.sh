#!/bin/bash
#
# Eseriman script to be called from C3 to create a new user in the Funambol database - v1.0
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

#We need to know the username, full name and their password
USERNAME=$1
FIRSTNAME=$2
LASTNAME=$3
PASSWORD=$4
ORGNAME=`hostname -d`
#IMAP="imap.$ORGNAME"
#SMTP="smtp.$ORGNAME"
IMAP="imap"
SMTP="smtp"
MAIL_ACCOUNT="$USERNAME@$ORGNAME"

NEW_PASSWORD=`/opt/Funambol/tools/jre-1.6.0/jre/bin/java -cp /opt/Funambol/admin/funamboladmin/modules/ext/server-framework-8.7.0.jar:/opt/Funambol/admin/funamboladmin/modules/ext/log4j-1.2.14.jar:/opt/Funambol/admin/funamboladmin/modules/ext/core-framework-8.7.0.jar:/var/lib/eseriman/bin Encryption2 "$PASSWORD" 2>/dev/null`

#First, create the user
echo "INSERT INTO fnbl_user ( username, password, email, first_name, last_name ) VALUES ( '$USERNAME', '$NEW_PASSWORD', '$MAIL_ACCOUNT', '$FIRSTNAME', '$LASTNAME');" | psql -U funambol -h pgsql.$ORGNAME -d funambol

#Set their role to user
echo "INSERT INTO fnbl_user_role ( username, role ) VALUES ( '$USERNAME', 'sync_user' );" | psql -U funambol -h pgsql.$ORGNAME -d funambol
#Next, create their mail account
NEXTID=`echo "SELECT MAX(account_id) + 1 FROM fnbl_email_account;" | psql -U funambol -h pgsql.$ORGNAME -d funambol | head -n 3 | tail -n 1`
[[ $NEXTID -eq "" ]] && NEXTID="0"
echo "INSERT INTO fnbl_email_account (account_id, username, ms_login, ms_password, ms_address, ms_mailboxname, push, soft_delete, max_num_email, max_imap_email, mailserver_id, server_public, server_type, description, protocol, out_server, out_port, out_auth, in_server, in_port, sslin, sslout, inbox_name, inbox_active, outbox_name, outbox_active, sent_name, sent_active, drafts_name, drafts_active, trash_name, trash_active, out_login, out_password) VALUES ( $NEXTID, '$USERNAME', '$USERNAME', '$NEW_PASSWORD', '$MAIL_ACCOUNT', '', 'y', 'n', 100, 20, 100, 'y', 'Other', (SELECT description FROM fnbl_email_mailserver WHERE mailserver_id = '100'), 'imap', '$SMTP', 10026, 'n', '$IMAP', 993, 'y', 'n', 'Inbox', 'y', 'Outbox', 'y', 'Sent', 'y', 'Drafts', 'y', 'Trash', 'y', '', 'PkwqnxYZfBE=');" | psql -U funambol -h pgsql.$ORGNAME -d funambol

#Now, set their email account to be 'active'
echo "INSERT INTO fnbl_email_enable_account (account_id, username) VALUES ( $NEXTID, '$USERNAME' );" | psql -U funambol -h pgsql.$ORGNAME -d funambol

#Finally, register them for push email? I guess, I dunno what exactly this record does but it's needed
TIME_SINCE_EPOCH=`date +%s`
TIME_SINCE_EPOCH="${TIME_SINCE_EPOCH}000"
echo "INSERT INTO fnbl_email_push_registry (id, period, active, last_update, status, task_bean_file) VALUES ( $NEXTID, 300000, 'Y', $TIME_SINCE_EPOCH, 'N', 'com/funambol/email/inboxlistener/task/InboxListenerTask.xml');" | psql -U funambol -h pgsql.$ORGNAME -d funambol
