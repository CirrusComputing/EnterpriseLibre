#!/bin/bash
#
# createRedmineUser.sh - v1.2
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com> 
#
# Copyright (c) 1996-2013 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

export PGPASSWORD=[-DB_PASSWORD_REDMINE-]
TIMEZONE=$(cat /etc/timezone)

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
EMAIL_DOMAIN=$5
DOMAIN=`hostname -d`
PSQL_HOST=pgsql.$DOMAIN
PSQL_PORT=5432

#Redmine database nextval starts from 2, so 3 would be the superuser
NEXT_USER_ID=`echo "SELECT nextval('users_id_seq');" | psql -Uredmine -h$PSQL_HOST -p$PSQL_PORT | awk 'NR==3' | sed "s|^.* ||"`
if [ $NEXT_USER_ID == "3" ]; then
        echo "Adding superuser"
        ADMIN='t'
else
        echo "Adding normal user"
        ADMIN='f'
fi

echo "INSERT INTO users VALUES ($NEXT_USER_ID, '$USERNAME','','$FIRSTNAME','$LASTNAME','$EMAIL_PREFIX@$EMAIL_DOMAIN','$ADMIN',1,timeofday()::timestamp,'en', 1,timeofday()::timestamp,timeofday()::timestamp,'User','','only_my_events','');" | psql -Uredmine -h$PSQL_HOST -p$PSQL_PORT
echo "INSERT INTO user_preferences VALUES (nextval('user_preferences_id_seq'), $NEXT_USER_ID, E'--- {}\n\n','f','$TIMEZONE');" | psql -Uredmine -h$PSQL_HOST -p$PSQL_PORT
