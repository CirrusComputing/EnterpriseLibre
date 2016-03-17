#!/bin/bash
#
# SMC central mail configuration script - v1.0
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Configure SMC Database"

DOMAIN=$(getParameter domain)

# Variables
POSTFIX_CONFIG_FOLDER=/etc/postfix
POSTFIX_TRANSPORT=$POSTFIX_CONFIG_FOLDER/transport
POSTFIX_RELAY_DOMAINS=$POSTFIX_CONFIG_FOLDER/relay_domains
POSTFIX_RELAY_HOSTS=$POSTFIX_CONFIG_FOLDER/relay_hosts

# Configure Transport
echo "$DOMAIN smtp:smtp.$DOMAIN" >> $POSTFIX_TRANSPORT
echo "lists.$DOMAIN smtp:smtp.$DOMAIN" >> $POSTFIX_TRANSPORT
# Configure Relay Domains
echo "$DOMAIN OK" >> $POSTFIX_RELAY_DOMAINS
echo "lists.$DOMAIN OK" >> $POSTFIX_RELAY_DOMAINS
# Configure Relay Hosts
echo "@$DOMAIN smtp.$DOMAIN" >> $POSTFIX_RELAY_HOSTS
echo "@lists.$DOMAIN smtp.$DOMAIN" >> $POSTFIX_RELAY_HOSTS

postmap $POSTFIX_TRANSPORT $POSTFIX_RELAY_DOMAINS $POSTFIX_RELAY_HOSTS
# Reload Postfix
init_process '/etc/init.d/postfix' 'reload'

exit 0
