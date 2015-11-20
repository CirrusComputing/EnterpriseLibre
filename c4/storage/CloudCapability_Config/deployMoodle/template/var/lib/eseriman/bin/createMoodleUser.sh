#!/bin/bash
#
# createMoodleUser.sh - v1.2
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

export PGPASSWORD=[-DB_PASSWORD_MOODLE-]

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
CLOUD_DOMAIN=$5
TIMEZONE=$6
DOMAIN=`hostname -d`
PSQL_HOST=pgsql.$DOMAIN
PSQL_PORT=5432
TIMESTAMP=$(date +%s)

if [ $TIMEZONE == 'server' ] || [ $TIMEZONE == $(cat /etc/timezone) ]; then
    # Use Server's timezone
    OFFSET=99
else
    DATE=$(TZ="$TIMEZONE" date +%s -d "$(date +'%F %R:%S')")
    DATE_UTC=$(TZ="UTC" date +%s -d "$(date +'%F %R:%S')")
    OFFSET=$(awk 'BEGIN{printf "%.1f", ('$DATE_UTC'-'$DATE') /'3600'}')
fi

#Moodle database starts from 1. So Super User will be 2.
NEXT_USER_ID=`echo "SELECT nextval('mdl_user_id_seq');" | psql -Umoodle -h$PSQL_HOST -p$PSQL_PORT | awk 'NR==3' | sed "s|^.* ||"`

if [ $NEXT_USER_ID == "2" ]; then
        echo "Adding superuser"
	#No special configuration here, since moodle db template already has in table mdl_config, the siteadmins value as 2
else
        echo "Adding normal user"
fi

echo "INSERT INTO mdl_user VALUES ($NEXT_USER_ID,'ldap',1,0,0,0,1,'$USERNAME','not cached','','$FIRSTNAME','$LASTNAME','$EMAIL_PREFIX@$CLOUD_DOMAIN',0,'','','','','','','','','','','','','en','gregorian','','$OFFSET',$TIMESTAMP,$TIMESTAMP,0,$TIMESTAMP,'','',0,'','',1,1,0,1,1,0,0,$TIMESTAMP,0,'','','','','');" | psql -Umoodle -h$PSQL_HOST -p$PSQL_PORT

exit 0
