#!/bin/bash
#
# Firewall Port Config Deploy Script - v1.0
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

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Get the system parameters.
eseriGetDNS >/dev/null
eseriGetNetwork >/dev/null

# Mark start point in log file.
echo "Firewall Port Config"

USERNAME=$(getParameter username)
PORT=$(getParameter port)

##################
##### HERMES #####
##################
if [ $SHORT_NAME == 'hermes' ]; then
    WAN_IP=$(ifconfig venet0:0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
    SHOREWALL_CONFIG_FOLDER=/etc/shorewall
    SHOREWALL_RULES_FILE=$SHOREWALL_CONFIG_FOLDER/rules
    
    # Remove previous Syncthing rule for user
    sed -i "/^DNAT.*net.*loc:$NETWORK.50.*tcp.*-.*$WAN_IP.*# Syncthing - $USERNAME/d" $SHOREWALL_RULES_FILE

    # Find the line number where Syncthing rules start
    LINE=$(grep -n '^# Syncthing rules -.*FirewallPortConfig' $SHOREWALL_RULES_FILE | cut -f1 -d:)

    # Compile the rule string to insert
    RULE="DNAT\t\t\tnet\t\t\tloc:$NETWORK.50\ttcp\t$PORT\t-\t$WAN_IP\t\t# Syncthing - $USERNAME"

    # Insert the rule at line+2 ie. the start of the rules for Syncthing
    sed -i "$(($LINE + 2))i$RULE" $SHOREWALL_RULES_FILE

    # Restart shorewall process
    init_process '/etc/init.d/shorewall' 'restart'

fi

exit 0
