#!/bin/bash
# 
# Cleanup Cloud Move Phase v1.7
#
# This script removes and cleans up a cloud created by cloud_move init/commit.  
# It is called by per-org scripts created by cloud_move like cleanCloudMoveA8.sh
# which just set variables such as 
#   VEID_BASE, DOMAIN, IP, HWH HOST, PHASE
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
#################
# Normally we do not want the progress messages from the remote system. 
# We still see remote errors.
DEBUG_SSH=" > /dev/null"
# To see all progress messages, mixed in with the errors, enable this:
#DEBUG_SSH=
# To log it:
#DEBUG_SSH="  2>&1  > cleanup$ORG.log"


# Check that we are c4
username=`id -nu` 
if [ "$username" != "c4" ]
then
    echo -e "please run this as user c4"
    exit 1
fi

showProgress()
{
    echo -n '+'
}

# Start the progress bar on a new line
echo ' '
showProgress

# Default Variables
BIN_FOLDER=~/bin
C4_FOLDER=$BIN_FOLDER/..
CACHE_FOLDER=$C4_FOLDER/cache/$ORG

# Since the init cleanup is when the sysadmin executes the script and needs to have the lock.
# For commit phase, it is run directly from cloud_move.pl, so it already has the lock.
if [[ "$PHASE" == "init" ]]; then
    lockfile -5 -r-1 $BIN_FOLDER/c4.lock
    if [ $? -ne 0 ] ; then
	exit 1
    fi
fi

# Variables
SYSTEM_ANCHOR_DOMAIN=$(perl -M"common 'get_system_anchor_domain'" -we "print get_system_anchor_domain (undef);")

for ID in 50 39 37 36 35 34 33 32 31 30 11 10 04 03 02 ; do
    showProgress
    VEID=$(expr $VEID_BASE + $ID)
    DEPLOY_HOST="root@$HWHOST"
    ssh $DEPLOY_HOST "[ -f /etc/vz/conf/$VEID.conf ] && vzctl stop $VEID --fast"                                       $DEBUG_SSH 
    ssh $DEPLOY_HOST "[ -f /etc/vz/conf/$VEID.conf ] && rm  /etc/vz/conf/$VEID.conf"                                   $DEBUG_SSH 
    ssh $DEPLOY_HOST "[ -d $VZ_BASE_PATH/root/$VEID ] && rm -r $VZ_BASE_PATH/root/$VEID $VZ_BASE_PATH/private/$VEID"   $DEBUG_SSH
    ssh-keygen -R ${NETWORK}.$(echo $ID | awk '{print $1 + 0}')  >/dev/null 2>&1
done

eseriDeploy()
{
	SSH_HOST=$1
	shift
	TASK_FOLDER=$1
	shift
	ssh $SSH_HOST "mkdir -p /root/deploy$ORG/result"                  $DEBUG_SSH 
	scp -q $TASK_FOLDER/deploy.sh $SSH_HOST:/root/deploy$ORG/deploy.sh
	scp -q -r $TASK_FOLDER/archive $SSH_HOST:/root/deploy$ORG/        
	scp -q -r $TASK_FOLDER/template $SSH_HOST:/root/deploy$ORG/       
	ssh $SSH_HOST "/root/deploy$ORG/deploy.sh $@"                     $DEBUG_SSH 
	ssh $SSH_HOST "rm -r /root/deploy$ORG"                            $DEBUG_SSH 
}


# Cleanup HWH network
eseriDeploy root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN $C4_FOLDER/storage/SMC_Network_Remove $ORG $IP $BRIDGE
showProgress

# Cleanup HWH storage
ssh root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN "umount /var/lib/vz-$ORG ; rmdir /var/lib/vz-$ORG ; lvremove -f /dev/mapper/mastervg-$ORG"   $DEBUG_SSH 
showProgress

# Cleanup FSTAB for clean boot
ssh root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN "grep -wv \"/var/lib/vz-$ORG\" /etc/fstab > /etc/fstab.temp ; mv /etc/fstab.temp /etc/fstab"  $DEBUG_SSH 
showProgress

# Update the DB tally of free space 
$BIN_FOLDER/set_free_space.pl $HWHOST
showProgress

# Cleanup DB: Free the external IP .
$BIN_FOLDER/cleanup_db_ip.pl  "$IP"

if [[ "$PHASE" == "init" ]]; then
    rm -f $BIN_FOLDER/c4.lock
fi

# Remove executable permissions and rename file
chmod -x $BIN_FOLDER/cleanup/$(basename $0)
mv $BIN_FOLDER/cleanup/$(basename $0) $BIN_FOLDER/cleanup/$(basename $0)_wasRun-$PHASE

echo done
exit 0
