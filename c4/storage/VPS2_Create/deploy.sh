#!/bin/bash
#
# VPS Creation script - Phase Two - v3.4
#  Creating all remaining servers
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

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy all remaining VPS"

# parameters set in c4q_omega.pl

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
SHORT_DOMAIN=$(getParameter short_domain)
VEID_BASE=$(getParameter veid_base)
VPS_CONFIG_TEMPLATE=$(getParameter vps_config_template)
VZ_BASE_PATH=$(getParameter vz_base_path)
FULL_DOMAIN=$(getParameter domain)
NETWORK=$(getParameter network)
BRIDGE=$(getParameter bridge)
TIMEZONE=$(getParameter timezone)
VPS_LIST=$(getParameter vps2_list)

# Template files
KRB5_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}/etc/krb5.conf
KRB5_CONFIG=/etc/krb5.conf
LDAP_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}/etc/ldap/ldap.conf
LDAP_CONFIG=/etc/ldap/ldap.conf

# Network Parameters
eseriGetDNSInternal $FULL_DOMAIN dummy.$FULL_DOMAIN

# Create a VPS server
CreateVPS() {
	local VEID_INDEX=$1
	local VEID=$(expr $VEID_BASE + $VEID_INDEX)

	# Two VPS's use a new template. 
	if [ $VEID_INDEX -eq 4 ]; then
	    VPS_TEMPLATE_NAME="ubuntu-14.04-i386-eseri-1.4"
	elif [ $VEID_INDEX -eq 39 ]; then
	    VPS_TEMPLATE_NAME="ubuntu-12.04-i386-eseri-1.1"
	else
	    VPS_TEMPLATE_NAME="ubuntu-10.04-i386-eseri-1.9"
	fi

	# Create VPS
	vzctl create $VEID --ostemplate $VPS_TEMPLATE_NAME --config $VPS_CONFIG_TEMPLATE --root $VZ_BASE_PATH/root/$VEID --private $VZ_BASE_PATH/private/$VEID

	# Confiugre VPS in background
	ConfigureVPS $VEID_INDEX >$RESULT_FOLDER/vps$INDEX.log 2>&1 &

	# Wait a minute for the server to finish the upgrade process and then create the next server.
	# This is going to decrease the load on the hardware host
	sleep 30
}

# Configure a VPS server
ConfigureVPS() {
	local VEID_INDEX=$1
	local VEID=$(expr $VEID_BASE + $VEID_INDEX)

	# Customize VPS config
	install -o root -g root -m 644 $TEMPLATE_FOLDER/transient/$VEID_INDEX.conf /etc/vz/conf/$VEID.conf

	eseriReplaceValues /etc/vz/conf/$VEID.conf

	vzctl set $VEID --netif_add eth0 --save

	if [ $VEID_INDEX -eq 4 ] ; then
		vzctl set $VEID --devnodes fuse:rw --save
	fi       

	# Deploy SSH keys
	SSH_FOLDER=$VZ_BASE_PATH/private/$VEID/root/.ssh
	install -o root -g root -m 700 -d $SSH_FOLDER	
	install -o root -g root -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys $SSH_FOLDER/authorized_keys

	# Deploy extra SSH Keys on Apollo and Hades
	if [ $VEID_INDEX -eq 4 -o $VEID_INDEX -eq 30 ]; then
		echo `cat $ARCHIVE_FOLDER/root/ssh/authorized_keys.c3` >> $SSH_FOLDER/authorized_keys
	fi

	# Deploy extra SSH Keys on Chaos
        if [ $VEID_INDEX -eq 50 ]; then
                echo `cat $ARCHIVE_FOLDER/root/ssh/authorized_keys.c5` >> $SSH_FOLDER/authorized_keys
        fi

	# Start the server
	vzctl start $VEID

	if [ $VEID_INDEX -eq 4 ]; then
            INIT_FOLDER=$VZ_BASE_PATH/private/$VEID/etc/init.d
            install -o root -g root -m 755 $ARCHIVE_FOLDER/files/etc/init.d/cirrusopen_container_config $INIT_FOLDER/cirrusopen_container_config
            vzctl exec $VEID "update-rc.d cirrusopen_container_config defaults"
            vzctl exec $VEID "/etc/init.d/cirrusopen_container_config"
        fi

	# Wait for the sshd to start, once that's running we should have network
	TIME=0
	TIMEOUT=20
	while true; do
		vzctl exec $VEID "/usr/bin/wget -O - -q -t 1 http://lucid-mirror.wan.virtualorgs.net/"
		[ $? -eq 0 ] && break
		sleep 1
		TIME=$(expr $TIME + 1)
		[ $TIME -ge $TIMEOUT ] && exit 1
	done

	# Upgrade the system
	vzctl exec $VEID "apt-get -q update"
	vzctl exec $VEID "apt-get -q -y dist-upgrade"
	vzctl exec $VEID "apt-get -q -y autoremove --purge"


	# Reconfigure SSMTP 
	echo "$FQDN_HOSTNAME" >/etc/mailname
	sed -i -e "s|^root=.*|root=sysadmin@$SYSTEM_ANCHOR_DOMAIN|g" -e "s|^mailhub=.*|mailhub=smtp.$DOMAIN|g" -e "s|^hostname=.*|hostname=$FQDN_HOSTNAME|g" /etc/ssmtp/ssmtp.conf
	echo "root:$SHORT_DOMAIN.$SHORT_NAME@$SYSTEM_ANCHOR_DOMAIN:smtp.$DOMAIN" >>/etc/ssmtp/revaliases

	# Reconfigure Timezone
	rm /etc/localtime
	ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
	dpkg-reconfigure -f noninteractive tzdata

	# Deploy CA root certificate
	mkdir $VZ_BASE_PATH/root/$VEID/usr/share/ca-certificates/$FULL_DOMAIN
	install -o root -g root -m 644 $ARCHIVE_FOLDER/CA.crt $VZ_BASE_PATH/root/$VEID/usr/share/ca-certificates/$FULL_DOMAIN/CA.crt
	vzctl exec $VEID 'echo "`hostname -d`/CA.crt" >> /etc/ca-certificates.conf'
	vzctl exec $VEID 'update-ca-certificates'

	# Install Kerberos Client
	install -o root -g root -m 644 $KRB5_TEMPLATE_CONFIG $VZ_BASE_PATH/root/$VEID/$KRB5_CONFIG
	eseriReplaceValues $VZ_BASE_PATH/root/$VEID/$KRB5_CONFIG
	vzctl exec $VEID 'apt-get -q -y install krb5-user'

	# Install the LDAP Client
	vzctl exec $VEID 'apt-get -q -y install ldap-utils libsasl2-modules-gssapi-mit'
	install -o root -g root -m 644 $LDAP_TEMPLATE_CONFIG $VZ_BASE_PATH/root/$VEID/$LDAP_CONFIG
	eseriReplaceValues $VZ_BASE_PATH/root/$VEID/$LDAP_CONFIG
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
