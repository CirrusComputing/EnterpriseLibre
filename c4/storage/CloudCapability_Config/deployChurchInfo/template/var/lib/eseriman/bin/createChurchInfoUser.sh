#!/bin/bash
#
# createChurchInfoUser.sh - v1.1
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

DB_PASSWORD_CHURCHINFO=[-DB_PASSWORD_CHURCHINFO-]

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
CLOUD_DOMAIN=$5
PASSWORD=$6
DOMAIN=`hostname -d`
MYSQL_HOST=mysql.$DOMAIN
MYSQL_PORT=3306
TIMESTAMP=$(date +"%F %R:%S")

#ChurchInfo database starts from 0.
NEXT_USER_ID=`echo "SELECT COALESCE(MAX(per_ID) + 1, 1) FROM person_per;" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo | awk 'NR==2' | sed "s|^.* ||"`
echo "INSERT INTO person_per VALUES ($NEXT_USER_ID,'','$FIRSTNAME','','$LASTNAME','','','','','','','','','','','$EMAIL_PREFIX@$CLOUD_DOMAIN','',0,0,NULL,NULL,0,0,0,0,0,'$TIMESTAMP','$TIMESTAMP',0,0,NULL,0);" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo

if [ $NEXT_USER_ID == "1" ]; then
        echo "Adding superuser"
	echo "INSERT INTO user_usr VALUES ($NEXT_USER_ID,'$PASSWORD',0,'$TIMESTAMP',0,0,1,1,1,1,1,1,0,1,1,NULL,NULL,10,'Style.css',0,0,'0000-00-00',10,0,'$USERNAME',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0);" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo
	echo "INSERT INTO userconfig_ucfg VALUES ($NEXT_USER_ID,0,'bEmailMailto','1','boolean','User permission to send email via mailto: links','TRUE',''),($NEXT_USER_ID,1,'sMailtoDelimiter',',','text','user permission to send email via mailto: links','TRUE',''),($NEXT_USER_ID,2,'bSendPHPMail','1','boolean','User permission to send email using PHPMailer','TRUE',''),($NEXT_USER_ID,3,'sFromEmailAddress','$EMAIL_PREFIX@$CLOUD_DOMAIN','text','Reply email address for PHPMailer','TRUE',''),($NEXT_USER_ID,4,'sFromName','$FIRSTNAME $LASTNAME','text','Name that appears in From field','TRUE',''),($NEXT_USER_ID,5,'bCreateDirectory','1','boolean','User permission to create directories','TRUE',''),($NEXT_USER_ID,6,'bExportCSV','1','boolean','User permission to export CSV files','TRUE',''),($NEXT_USER_ID,7,'bUSAddressVerification','1','boolean','User permission to use IST Address Verification','TRUE',''),($NEXT_USER_ID,10,'bAddEvent','','boolean','Allow user to add new event','FALSE','SECURITY'),($NEXT_USER_ID,11,'bSeePrivacyData','','boolean','Allow user to see member privacy data, e.g. Birth Year, Age.','FALSE','SECURITY');" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo
else
        echo "Adding normal user"
	echo "INSERT INTO user_usr VALUES ($NEXT_USER_ID,'$PASSWORD',0,'$TIMESTAMP',0,0,1,1,1,0,0,0,0,1,0,NULL,NULL,10,'Style.css',0,0,'0000-00-00',10,0,'$USERNAME',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0);" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo
	echo "INSERT INTO userconfig_ucfg VALUES ($NEXT_USER_ID,0,'bEmailMailto','1','boolean','User permission to send email via mailto: links','TRUE',''),($NEXT_USER_ID,1,'sMailtoDelimiter',',','text','Delimiter to separate emails in mailto: links','TRUE',''),($NEXT_USER_ID,2,'bSendPHPMail','','boolean','User permission to send email using PHPMailer','FALSE',''),($NEXT_USER_ID,3,'sFromEmailAddress','$EMAIL_PREFIX@$CLOUD_DOMAIN','text','Reply email address: PHPMailer','FALSE',''),($NEXT_USER_ID,4,'sFromName','$FIRSTNAME $LASTNAME','text','Name that appears in From field: PHPMailer','FALSE',''),($NEXT_USER_ID,5,'bCreateDirectory','','boolean','User permission to create directories','FALSE','SECURITY'),($NEXT_USER_ID,6,'bExportCSV','','boolean','User permission to export CSV files','FALSE','SECURITY'),($NEXT_USER_ID,7,'bUSAddressVerification','','boolean','User permission to use IST Address Verification','FALSE',''),($NEXT_USER_ID,10,'bAddEvent','','boolean','Allow user to add new event','FALSE','SECURITY'),($NEXT_USER_ID,11,'bSeePrivacyData','','boolean','Allow user to see member privacy data, e.g. Birth Year, Age.','FALSE','SECURITY');" | mysql -uchurchinfo -p$DB_PASSWORD_CHURCHINFO -h$MYSQL_HOST -P$MYSQL_PORT churchinfo
fi

exit 0
