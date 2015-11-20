#!/bin/bash
#
# Generate new NX license keys and distribute them - v1.2
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

C5_HOME_FOLDER=/home/c5
C5_BIN_FOLDER=$C5_HOME_FOLDER/bin
SCRIPT_NAME=${0##*/}

DATE_TIME=$(date '+%F-%H-%M')

SYSTEM_ANCHOR_DOMAIN=$(hostname -d)

ORGANIZATIONS_VO='system_manager_cloud'

ORG_SERVERS_VO='zeus hermes apollo athena aphrodite hades hera poseidon cronus erato metis gaia trident chaos'

acquire_ssh_fingerprint()
{
    FULL_HOSTNAME=$1
    # Clearing SSH Fingerprint for target host
    ssh-keygen -R $FULL_HOSTNAME &>/dev/null
    ssh-keygen -R $(host $FULL_HOSTNAME |  grep 'has address' | awk '{print $4}') &>/dev/null
    # Acquiring SSH Fingerprint for target host
    ssh-keyscan -t rsa -H $FULL_HOSTNAME >> /root/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa -H $(host $FULL_HOSTNAME | grep 'has address' | awk '{print $4}') >> /root/.ssh/known_hosts 2>/dev/null
}

# Install NX
dpkg -i $C5_BIN_FOLDER/NX/* >/dev/null

# Distribute license keys
for ORG in $ORGANIZATIONS_VO ; do
    if [[ $ORG == 'system_manager_cloud' ]]; then
	HOST=chaos.$SYSTEM_ANCHOR_DOMAIN
    else
	HOST=chaos.$ORG.$SYSTEM_ANCHOR_DOMAIN
    fi
	echo $HOST
	acquire_ssh_fingerprint "$HOST"
	scp -i $C5_HOME_FOLDER/.ssh/id_rsa /usr/NX/etc/server.lic root@$HOST:/usr/NX/etc/
	scp -i $C5_HOME_FOLDER/.ssh/id_rsa /usr/NX/etc/node.lic root@$HOST:/usr/NX/etc/
done

# Cleanup
apt-get -q -y purge nxserver nxnode nxclient >/dev/null 2>&1
rm -r /usr/NX/ >/dev/null

exit 0
