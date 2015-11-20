#!/bin/bash
#
# createPHPScheduleItUser.sh - v1.1
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

MYSQL_PASSWORD=[-DB_PASSWORD_PHPSCHEDULEIT-]
ORGNAME=[-ORGNAME-]
TIMEZONE=$(cat /etc/timezone)

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
EMAIL_DOMAIN=$5
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306

#Add user
echo "INSERT INTO users (fname, lname, username, email, organization, timezone, language, date_created, status_id) VALUES ('$FIRSTNAME', '$LASTNAME', '$USERNAME', '$EMAIL_PREFIX@$EMAIL_DOMAIN', '$ORGNAME', '$TIMEZONE', 'en_us', now(), 1);" | mysql -uphpscheduleit -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT phpscheduleit

#Check if this was the first user that was entered
COUNT=`echo "SELECT COUNT(user_id) FROM users;" | mysql -uphpscheduleit -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT phpscheduleit | tail -n 1`
USER_ID=`echo "SELECT user_id FROM users WHERE username = '$USERNAME';" | mysql -uphpscheduleit -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT phpscheduleit | tail -n 1`
if [ $COUNT == "1" ]; then
        echo "Adding superuser"
        echo "INSERT INTO user_groups VALUES ($USER_ID, 1);" | mysql -uphpscheduleit -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT phpscheduleit
else
        echo "Adding normal user"
fi

exit 0
