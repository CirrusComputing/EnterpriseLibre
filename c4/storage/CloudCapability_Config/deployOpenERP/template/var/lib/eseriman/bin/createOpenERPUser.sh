#!/bin/bash
#
# createOpenERPUser.sh - v1.3
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com> 
#
# Copyright (c) 1996-2014 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.

export PGPASSWORD=[-DB_PASSWORD_OPENERP-]

USERNAME=$1
EMAIL_PREFIX=$2
FIRSTNAME=$3
LASTNAME=$4
CLOUD_DOMAIN=$5
PASSWORD=$6
TIMEZONE=$7
DOMAIN=`hostname -d`
PSQL_HOST=pgsql.$DOMAIN
PSQL_PORT=5432
TIMESTAMP=$(date +%s)

if [ $TIMEZONE == 'server' ]; then
    TIMEZONE=$(cat /etc/timezone)
fi

#Simulate a POST request to server with credentials. Auth_LDAP module automatically creates the new user with details in res_user, res_partner, res_groups_users_rel tables.
curl -H "" \
    -X POST \
    -H "Content-type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"call\",\"params\":{\"db\":\"openerp\",\"login\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"base_location\":\"http://openerp.$DOMAIN\",\"session_id\":\"\",\"context\":{}},\"id\":\"r9\"}" \
    "http://openerp.$DOMAIN:8069/web/session/authenticate"

#OpenERP user table starts from 0. So Super User will be 1.
CURRENT_USER_ID=`echo "SELECT MAX (id) FROM res_users;" | psql -Uopenerp -h$PSQL_HOST -p$PSQL_PORT | awk 'NR==3' | sed "s|^.* ||"`

if [ $CURRENT_USER_ID == "1" ]; then
    echo -e "\nAdding superuser"
    #Superuser is already added to database. Also admin privileges already in database (table res_groups_users_rel values (1,4),(1,6),(1,9))
else
    echo -e "\nAdding normal user"
    #Delete admin privileges that were copied during user creation.
    echo "DELETE FROM res_groups_users_rel WHERE uid = (SELECT id FROM res_users WHERE login='$USERNAME');" | psql -Uopenerp -h$PSQL_HOST -p$PSQL_PORT
fi

echo "UPDATE res_users SET password='$PASSWORD', signature=E'--\n$FIRSTNAME $LASTNAME' WHERE login='$USERNAME';" | psql -Uopenerp -h$PSQL_HOST -p$PSQL_PORT

echo "UPDATE res_partner SET name='$FIRSTNAME $LASTNAME', email='$EMAIL_PREFIX@$CLOUD_DOMAIN', tz='$TIMEZONE' WHERE id = (SELECT partner_id FROM res_users WHERE login='$USERNAME');" | psql -Uopenerp -h$PSQL_HOST -p$PSQL_PORT

exit 0
