#!/bin/bash
#
# createDrupalUser.sh - v1.3
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com> 
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

DB_PASSWORD_DRUPAL=[-DB_PASSWORD_DRUPAL-]

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
CLOUD_DOMAIN=$5
TIMEZONE=$6
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306
TIMESTAMP=$(date +%s)

if [ $TIMEZONE == 'server' ]; then
    TIMEZONE=$(cat /etc/timezone)
fi

#Drupal database starts from 0, but 1 can't be used since the superuser would have to manually log in (SSO works for everyone except user 1). So start from 2.
NEXT_USER_ID=`echo "SELECT MAX(uid) + 1 FROM drupal_users;" | mysql -udrupal -p$DB_PASSWORD_DRUPAL -h$MYSQL_HOST -P$MYSQL_PORT drupal | awk 'NR==2' | sed "s|^.* ||"`
if [ $NEXT_USER_ID == "1" ]; then
	NEXT_USER_ID=2
        echo "Adding superuser"
	echo "INSERT INTO drupal_users_roles VALUES ($NEXT_USER_ID, 3);" | mysql -udrupal -p$DB_PASSWORD_DRUPAL -h$MYSQL_HOST -P$MYSQL_PORT drupal
else
        echo "Adding normal user"
fi

echo "INSERT INTO drupal_users VALUES ($NEXT_USER_ID, '$USERNAME','','$EMAIL_PREFIX@$CLOUD_DOMAIN','','',NULL,$TIMESTAMP,0,0,1,'$TIMEZONE','',0,'$EMAIL_PREFIX@$CLOUD_DOMAIN','');" | mysql -udrupal -p$DB_PASSWORD_DRUPAL -h$MYSQL_HOST -P$MYSQL_PORT drupal

exit 0
