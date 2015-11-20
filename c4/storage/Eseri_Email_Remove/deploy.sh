#!/bin/bash
#
# Eseri central Email configuration script (Delete Org) - v1.1
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Edited by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2013 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure Eseri Email"

# Check for proper number of parameters
if [ $# -ne "3" ]; then
    echo "Usage: $SCRIPT_NAME DOMAIN NETWORK EMAIL_DOMAIN"
    echo "Example: $SCRIPT_NAME acme3.eseri.net 10.63.0 acme3.eseri.info"
    exit 1
fi

# Check the format of the input parameters
eseriCheckParameter "Full domain name" $1
eseriCheckParameter "Network" $2
eseriCheckParameter "Email domain" $3

DOMAIN=$1
NETWORK=$2
EMAIL_DOMAIN=$3

# Variables
POSTFIX_CONFIG_FOLDER=/etc/postfix
POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
POSTFIX_RELAY_DOMAINS=$POSTFIX_CONFIG_FOLDER/relay_domains
POSTFIX_MYNETWORKS=$POSTFIX_CONFIG_FOLDER/mynetworks

lockfile -r-1 /tmp/tane.lock

# Creating backup
tar -C /etc -czf $RESULT_FOLDER/postfix.tar.gz postfix

# Remove the domain from the transport and realy domain files
sed -i -e "/^$DOMAIN smtp:$NETWORK\.31/d" -e "/^lists.$DOMAIN smtp:$NETWORK\.31/d" $POSTFIX_TRANSPORT
postmap $POSTFIX_TRANSPORT
sed -i -e "/^$DOMAIN OK/d" -e "/^lists.$DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
postmap $POSTFIX_RELAY_DOMAINS
sed -i -e "/^$NETWORK\.31/d" $POSTFIX_MYNETWORKS
postmap $POSTFIX_MYNETWORKS

# External email domain if set
if [ -n "$EMAIL_DOMAIN" ]; then
	sed -i -e "/^$EMAIL_DOMAIN smtp:$NETWORK\.31/d" $POSTFIX_TRANSPORT
	postmap $POSTFIX_TRANSPORT
	sed -i -e "/^$EMAIL_DOMAIN OK/d" $POSTFIX_RELAY_DOMAINS
	postmap $POSTFIX_RELAY_DOMAINS
fi

# Reload Postfix
/etc/init.d/postfix reload

rm -f /tmp/tane.lock

exit 0
