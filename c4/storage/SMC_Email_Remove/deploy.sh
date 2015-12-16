#!/bin/bash
#
# SMC central Email configuration script (Delete Org) - v1.2
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Edited by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure SMC Email"

# Check for proper number of parameters
if [ $# -ne "3" ]; then
    echo "Usage: $SCRIPT_NAME DOMAIN CLOUD_DOMAIN ALIAS_DOMAIN"
    echo "Example: $SCRIPT_NAME domainneverused.net yourdomain.com domainneverused.net"
    exit 1
fi

# Check the format of the input parameters
eseriCheckParameter "Full domain name" $1
eseriCheckParameter "Cloud domain" $2
eseriCheckParameter "Alias domain" $2

DOMAIN=$1
CLOUD_DOMAIN=$2
ALIAS_DOMAIN=$3

# Variables
POSTFIX_CONFIG_FOLDER=/etc/postfix
POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
POSTFIX_RELAY_DOMAINS=$POSTFIX_CONFIG_FOLDER/relay_domains
POSTFIX_RELAY_HOSTS=$POSTFIX_CONFIG_FOLDER/relay_hosts

# Configure Transport
sed -i "/^$DOMAIN smtp:smtp.$DOMAIN/d" $POSTFIX_TRANSPORT
sed -i "/^lists.$DOMAIN smtp:smtp.$DOMAIN/d" $POSTFIX_TRANSPORT
sed -i "/^$CLOUD_DOMAIN smtp:smtp.$ALIAS_DOMAIN/d" $POSTFIX_TRANSPORT
sed -i "/^lists.$CLOUD_DOMAIN smtp:smtp.$ALIAS_DOMAIN/d" $POSTFIX_TRANSPORT
# Configure Relay Domains
sed -i "/^$DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
sed -i "/^lists.$DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
sed -i "/^$CLOUD_DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
sed -i "/^lists.$CLOUD_DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
# Configure Relay Hosts
sed -i "/^@$DOMAIN smtp.$DOMAIN/d" $POSTFIX_RELAY_HOSTS
sed -i "/^@lists.$DOMAIN smtp.$DOMAIN/d" $POSTFIX_RELAY_HOSTS
sed -i "/^@$CLOUD_DOMAIN smtp.$ALIAS_DOMAIN/d" $POSTFIX_RELAY_HOSTS
sed -i "/^@lists.$CLOUD_DOMAIN smtp.$ALIAS_DOMAIN/d" $POSTFIX_RELAY_HOSTS

postmap $POSTFIX_TRANSPORT $POSTFIX_RELAY_DOMAINS $POSTFIX_RELAY_HOSTS
# Reload Postfix
init_process '/etc/init.d/postfix' 'reload'

exit 0
