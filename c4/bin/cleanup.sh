#!/bin/bash
# 
# Cleanup script v6.9
#
# This script removes and cleans up an org.  
# It is called by per-org scripts like cleanA873.sh 
# which just sets variables such as VEID_BASE, and DOMAIN
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.

#################
# Normally we do not want the progress messages from the remote system. 
# We still see remote errors.
#DEBUG_SSH=" > /dev/null"
# To see all progress messages, mixed in with the errors, enable this:
DEBUG_SSH=
# To log it:
#DEBUG_SSH="  2>&1  > cleanup$ORG.log"

# DB_OPTION = DELETE , Demolishes the organization and deletes the record from the database.
# DB_OPTION = BACKUP , Demolishes the organization and sets its status in the database from ACTIVE to ARCHIVED for restore at a later point.
if [ $# -ne 1 ]; then
        echo -e "Usage: $0 <DB_OPTION>\n\n<DB_OPTION>:\nDELETE - Demolishes the organization and deletes the record from the database.\nBACKUP - Demolishes the organization and sets its status in the database from \"ACTIVE\" to \"ARCHIVED\" for restore at a later point.\n"
        exit 1
fi

if [[ "$DB_OPTION" == "DELETE" ]] ; then
    echo -e "\n"
    read -p "Are you sure you want to completely delete $DOMAIN? " -n 1
elif [[ "$DB_OPTION" == "BACKUP" ]] ; then
    echo -e "\n"
    read -p "Are you sure you want to backup/restore $DOMAIN? " -n 1
else
    echo -e "\nScript terminating. Please enter a valid option when you run the script again"
    exit 1
fi

# Ask for confirmation
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    echo -e "\nCanceling demolition of $DOMAIN"
    exit 1
fi

#check that we are c4
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

# start the progress bar on a new line
echo ' '
showProgress

echo -e "\n----- Starting demolition of $DOMAIN -----\n"

# Default Variables
BIN_FOLDER=~/bin
C4_FOLDER=$BIN_FOLDER/..
CACHE_FOLDER=$C4_FOLDER/cache/$ORG

lockfile -5 -r-1 $BIN_FOLDER/c4.lock
if [ $? -ne 0 ] ; then
	exit 1
fi

# Variables
SYSTEM_ANCHOR_DOMAIN=$(perl -M"common 'get_system_anchor_domain'" -we "print get_system_anchor_domain (undef);")
CLOUD_DOMAIN=$(perl -M"common 'get_domain_config_details'" -we "my %domain_config_details; get_domain_config_details(undef, '$DOMAIN', \%domain_config_details); print \$domain_config_details{'email_domain'};")
ALIAS_DOMAIN=$(perl -M"common 'get_domain_config_details'" -we "my %domain_config_details; get_domain_config_details(undef, '$DOMAIN', \%domain_config_details); print \$domain_config_details{'alias_domain'};")
DOMAIN_CONFIG_VERSION=$(perl -M"common 'get_domain_config_details'" -we "my %domain_config_details; get_domain_config_details(undef, '$DOMAIN', \%domain_config_details); print \$domain_config_details{'config_version'};")
[[ -z "$CLOUD_DOMAIN" ]] && CLOUD_DOMAIN=$DOMAIN
[[ -z "$ALIAS_DOMAIN" ]] && ALIAS_DOMAIN=$DOMAIN
[[ -z "$DOMAIN_CONFIG_VERSION" ]] && DOMAIN_CONFIG_VERSION='1.1'

# Remove Cache folder
[ -d $CACHE_FOLDER ] && rm -r $CACHE_FOLDER
showProgress

# Cleanup SMC Nagios
# Running sed command on SHORT_DOMAIN to replace . with _
SED_SHORT_DOMAIN=$(echo $SHORT_DOMAIN | sed "s|\.|\_|g")
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('nagios.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@nagios.$SYSTEM_ANCHOR_DOMAIN "rm -f /etc/nagios3/conf.d/ngraph/serviceext/$SED_SHORT_DOMAIN\_*; rm -f /etc/nagios3/clouds/$SHORT_DOMAIN\.cfg*; /etc/init.d/nagios3 reload"   $DEBUG_SSH 

perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('$HWHOST.$SYSTEM_ANCHOR_DOMAIN')"
for ID in 50 39 37 36 35 34 33 32 31 30 11 10 04 03 02 ; do
    showProgress
    VEID=$(expr $VEID_BASE + $ID)
    DEPLOY_HOST="root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN"
    ssh $DEPLOY_HOST "[ -d $VZ_BASE_PATH/root/$VEID ] && [ -f /etc/vz/conf/$VEID.conf ] && vzctl stop $VEID" 			$DEBUG_SSH 
    ssh $DEPLOY_HOST "[ -d $VZ_BASE_PATH/root/$VEID ] && [ -f /etc/vz/conf/$VEID.conf ] && rm  /etc/vz/conf/$VEID.conf" 	$DEBUG_SSH 
    ssh $DEPLOY_HOST "[ -d $VZ_BASE_PATH/root/$VEID ] && rm -r $VZ_BASE_PATH/root/$VEID $VZ_BASE_PATH/private/$VEID" 		$DEBUG_SSH 
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

# Cleanup SMC Proxy
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('smc-hermes.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@smc-hermes.$SYSTEM_ANCHOR_DOMAIN "rm -f /etc/apache2/sites-enabled/custom-$SHORT_DOMAIN-*; rm -f /etc/apache2/sites-available/custom-$SHORT_DOMAIN-*; /etc/init.d/apache2 reload"
showProgress

# Cleanup SMC Email
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('smc-hera.$SYSTEM_ANCHOR_DOMAIN')"
eseriDeploy root@smc-hera.$SYSTEM_ANCHOR_DOMAIN $C4_FOLDER/storage/SMC_Email_Remove $DOMAIN $CLOUD_DOMAIN $ALIAS_DOMAIN
showProgress

# Cleanup HWH network
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('$HWHOST.$SYSTEM_ANCHOR_DOMAIN')"
eseriDeploy root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN $C4_FOLDER/storage/SMC_Network_Remove $ORG $IP $BRIDGE
showProgress

# Cleanup HWH storage
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('$HWHOST.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN "umount /var/lib/vz-$ORG ; rmdir /var/lib/vz-$ORG ; lvremove -f /dev/mapper/mastervg-$ORG"   $DEBUG_SSH 
showProgress

# Cleanup FSTAB for clean boot
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('$HWHOST.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@$HWHOST.$SYSTEM_ANCHOR_DOMAIN "grep -wv \"/var/lib/vz-$ORG\" /etc/fstab > /etc/fstab.temp ; mv /etc/fstab.temp /etc/fstab"  $DEBUG_SSH 
showProgress

# Update the DB tally of free space 
$BIN_FOLDER/set_free_space.pl $HWHOST
showProgress

# In C5, remove known_hosts
    # ssh-keygen -R <hostname or IP address>
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('c5.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@c5.$SYSTEM_ANCHOR_DOMAIN \
    "/usr/bin/ssh-keygen -R chaos.$DOMAIN >/dev/null 2>&1 ; /usr/bin/ssh-keygen -R $NETWORK.50 >/dev/null 2>&1" $DEBUG_SSH 
showProgress

# In C5, cleanup /home/c5/bin/c5.sh
perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('c5.$SYSTEM_ANCHOR_DOMAIN')"
ssh root@c5.$SYSTEM_ANCHOR_DOMAIN "sed -i \"/ORGANIZATIONS_VO/s/ $SHORT_DOMAIN//g\" /home/c5/bin/c5.sh"   $DEBUG_SSH 
showProgress

# Order shouldn't matter here so pushed down.
# Check if you can ping to one of the containers before removing the route. This is because if a cloud fails to create, the next cloud that is successfully created might have the same network ip. If one tries to cleanup the failed cloud, then it would remove the network route that is actually assigned to the new cloud. Therefore, a quick ping check would show if the network is up or down. Since we remove all the containers before removing the route, the ping should fail. If it succeeds, then we know something is wrong.
# SMC_DNS_Remove also removes the network from the internal acls, so we should stop this from happening if the network is still in use.
if ping -c 1 $NETWORK.50 &> /dev/null; then
    echo "Error: Network $NETWORK is still in use (ie. Two clouds must be having the same network ip). Not removing the route or dns config."
    exit 1
else    
    # Cleanup SMC DNS
    perl -M"common 'acquire_ssh_fingerprint'" -we "acquire_ssh_fingerprint('smc-zeus.$SYSTEM_ANCHOR_DOMAIN')"
    eseriDeploy root@smc-zeus.$SYSTEM_ANCHOR_DOMAIN $C4_FOLDER/storage/SMC_DNS_Remove $DOMAIN $NETWORK
    if [ $DOMAIN_CONFIG_VERSION == '2.3' ] && [ $DOMAIN != $CLOUD_DOMAIN ]; then
	eseriDeploy root@smc-zeus.$SYSTEM_ANCHOR_DOMAIN $C4_FOLDER/storage/SMC_DNS_Remove $CLOUD_DOMAIN $NETWORK
    fi
    showProgress
fi

# Cleanup DB: Free the external IP and remove org from the Org table.
#    and move the calling script to the cleanup dir, renamed (it should be done here)
$BIN_FOLDER/cleanup_db.pl "$DB_OPTION" "$SHORT_DOMAIN" "$DOMAIN" "$NETWORK" "$(basename $0)"

rm -f $BIN_FOLDER/c4.lock
echo done
exit 0
