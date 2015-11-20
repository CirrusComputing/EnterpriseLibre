#!/bin/bash
#
# Eseri central Database configuration script - v1.0
#
# Created by Karoly Molnar <kmolnar@eseri.com>
#
# Copyright (c) 1996-2010 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure Eseri Database"

# Check for proper number of parameters
if [ $# -ne "2" ]; then
    echo "Usage: $SCRIPT_NAME DOMAIN NETWORK"
    echo "Example: $SCRIPT_NAME acme3.eseri.net 10.63.0"
    exit 1
fi

# Check the format of the input parameters
eseriCheckParameter "Domain" $1
eseriCheckParameter "Network" $2

DOMAIN=$1
NETWORK=$2

# Variables
PGSQL_CONFIG_FOLDER=/etc/postgresql/8.3/main
PGSQL_PG_HBA_CONF=$PGSQL_CONFIG_FOLDER/pg_hba.conf
ORG_ACCMGMT_IP="${NETWORK}.20"

# Archive files
PGSQL_PG_HBA_CONF_ADD_AWK=$ARCHIVE_FOLDER/pg_hba.conf.del.awk

# Allow the Org's Account Management server to connect to the database
awk -f $PGSQL_PG_HBA_CONF_ADD_AWK -v ORG_ACCMGMT_IP="${ORG_ACCMGMT_IP}/32;" $PGSQL_PG_HBA_CONF >$PGSQL_PG_HBA_CONF.tmp
mv $PGSQL_PG_HBA_CONF.tmp $PGSQL_PG_HBA_CONF

# Reload PostgreSQL
/etc/init.d/postgresql-8.3 reload

exit 0
