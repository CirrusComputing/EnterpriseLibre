#!/bin/bash
#
# VPS Creation script - Phase One - v3.4
#  DNS and Firewall server
#
# Created by Karoly Molnar <kmolnar@eseri.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy VPS for DNS and FW"

VEID_BASE=$(getParameter veid_base)
VPS_CONFIG_TEMPLATE=$(getParameter vps_config_template)
VZ_BASE_PATH=$(getParameter vz_base_path)
DOMAIN=$(getParameter domain)
NETWORK=$(getParameter network)
BRIDGE=$(getParameter bridge)
WAN_IP=$(getParameter wan_ip)
WAN_NETMASK=$(getParameter wan_netmask)
TIMEZONE=$(getParameter timezone)
VPS_LIST=$(getParameter vps1_list)

# Create a VPS server
CreateVPS() {
    local VEID_INDEX=$1
    local VEID=$(expr $VEID_BASE + $VEID_INDEX)

    # Hermes uses the 12.04 template. 
    if [ $VEID_INDEX -eq 3 ]; then
	VPS_TEMPLATE_NAME="ubuntu-12.04-i386-eseri-1.2"
    else
	VPS_TEMPLATE_NAME="ubuntu-10.04-i386-eseri-2.0"
    fi

    # Create VPS
    vzctl create $VEID --ostemplate $VPS_TEMPLATE_NAME --config $VPS_CONFIG_TEMPLATE --root $VZ_BASE_PATH/root/$VEID --private $VZ_BASE_PATH/private/$VEID

    # Confiugre VPS in background
    ConfigureVPS $VEID_INDEX >$RESULT_FOLDER/vps$INDEX.log 2>&1 &

    # Wait a minute for the server to finish the upgrade process and then create the next server.
    # This is going to decrease the load on the hardware host
    #sleep 30
}

# Configure a VPS server
ConfigureVPS() {
    local VEID_INDEX=$1
    local VEID=$(expr $VEID_BASE + $VEID_INDEX)
    
    # Customize VPS config
    install -o root -g root -m 644 $TEMPLATE_FOLDER/transient/$VEID_INDEX.conf /etc/vz/conf/$VEID.conf
    eseriReplaceValues /etc/vz/conf/$VEID.conf
    vzctl set $VEID --netif_add eth0 --save
    
    # Enable iptables at hermes
    if [ $VEID_INDEX -eq 3 ]; then
	vzctl set $VEID --iptables "iptable_nat iptable_filter iptable_mangle ip_conntrack ipt_conntrack ipt_REDIRECT ipt_REJECT ipt_multiport ipt_helper ipt_LOG ipt_state" --save
    fi
    
    #Turn off ability to screw up the damn hardware clock
    if [ $VEID_INDEX -eq 2 ]; then
	vzctl set $VEID --capability sys_time:off --save
    fi
    
    # Deploy SSH keys
    SSH_FOLDER=$VZ_BASE_PATH/private/$VEID/root/.ssh
    install -o root -g root -m 700 -d $SSH_FOLDER
    install -o root -g root -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys $SSH_FOLDER/authorized_keys
    
    # Start the server
    vzctl start $VEID

    if [ $VEID_INDEX -eq 3 ]; then
	INIT_FOLDER=$VZ_BASE_PATH/private/$VEID/etc/init.d
	install -o root -g root -m 755 $TEMPLATE_FOLDER/etc/init.d/enterpriselibre_add_route $INIT_FOLDER/enterpriselibre_add_route
	eseriReplaceValues $INIT_FOLDER/enterpriselibre_add_route
	vzctl exec $VEID "update-rc.d enterpriselibre_add_route defaults"
	vzctl exec $VEID "/etc/init.d/enterpriselibre_add_route"

	# Since IP of storage server is external, Zeus will not be able to ping it since shorewall that does the masquerading at Hermes is not yet installed. So at hermes, manually add rule
	vzctl exec $VEID "iptables -t nat -A POSTROUTING -o venet0 -j SNAT -s $NETWORK.0/24 --to $WAN_IP"
	vzctl exec $VEID "echo 1 > /proc/sys/net/ipv4/ip_forward"	
    fi

    # Get the IP of storage server
    STORAGE_IP=$(host lucid-mirror.wan.virtualorgs.net | awk '/^.*has address [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print $4}')
    echo "Storage IP is $STORAGE_IP"
    # Wait for the network to become alive
    TIME=0
    TIMEOUT=20
    while true; do
	vzctl exec $VEID "/usr/bin/wget -O - -q -t 1 http://$STORAGE_IP/"
	[ $? -eq 0 ] && break
	sleep 1
	TIME=$(expr $TIME + 1)
	echo "Waited $TIME"
	[ $TIME -ge $TIMEOUT ] && exit 1
    done
}

# Create all remaining VPS
for INDEX in $VPS_LIST ; do
    CreateVPS $INDEX
done

# Wait for all background process to finish
wait

# Merge logs and remove temporary files
for INDEX in $VPS_LIST ; do
    cat $RESULT_FOLDER/vps$INDEX.log
    rm $RESULT_FOLDER/vps$INDEX.log
done

# Since the earlier exit just exits out of the function and not the script.
if grep 'Waited 20' $RESULT_FOLDER/log.txt >/dev/null; then
    exit 1
fi

exit 0
