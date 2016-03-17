#!/bin/bash
#
# Eseri template creation for Lucid - v1.9
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

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Create VPS Template"

TEMPLATE_NAME=ubuntu-10.04-i386-eseri-1.9
UBUNTU_VERSION=lucid
ARCHIVE_URL="http://lucid-mirror.wan.virtualorgs.net/ubuntu/"
VEID=777777
TEMPLATE_PRIVATE_DIR=/var/lib/vz/private/$VEID
TEMPLATE_ROOT_DIR=/var/lib/vz/root/$VEID

# Save the template name in the result folder
echo "$TEMPLATE_NAME" >$RESULT_FOLDER/Eseri_VPS_Template_Name.txt

# Check whether the template exist or not
if [ -f /vz/template/cache/$TEMPLATE_NAME.tar.gz ]; then
	echo "Template already exists. Exiting"
	exit 0
fi

#Check to see if there's a script to retrieve the template from another machine
if [ -x /vz/template/cache/getTemplate.sh ] ; then
	# Run the script
	/vz/template/cache/getTemplate.sh $TEMPLATE_NAME.tar.gz
	if [ $? -eq 0 ] ; then
		if [ -f /vz/template/cache/$TEMPLATE_NAME.tar.gz ] ; then
			echo "Template retrieved from remote server. Exiting"
			exit 0
		else
			echo "Template retrieval script failed. Exiting"
			exit 1
		fi
	else
		echo "Template retrieval script failed. Exiting"
		exit 1
	fi
fi
		
# Debootstrap is required
which debootstrap
[ $? -ne 0 ] && aptGetInstall debootstrap
if [ ! -f /usr/share/debootstrap/scripts/$UBUNTU_VERSION ]; then
	echo "Debootstrap doesn't know about the version that is being deployed: $UBUNTU_VERSION"
	exit 1
fi

# Clean up before deploy
vzctl stop $VEID
vzctl destroy $VEID
rm -r /vz/private/$VEID
rm /etc/vz/conf/$VEID.conf
rm /etc/vz/conf/$VEID.conf.destroyed

# Start deploying
mkdir ${UBUNTU_VERSION}-chroot
debootstrap --arch=i386 ${UBUNTU_VERSION} ${UBUNTU_VERSION}-chroot ${ARCHIVE_URL}
mv ${UBUNTU_VERSION}-chroot $TEMPLATE_PRIVATE_DIR

vzctl set $VEID --applyconfig vps.basic --save
vzctl set $VEID --netif_add eth0 --save 
HOST_NAMESERVER=$(awk '$1 ~ /^nameserver/ { print $2 }' /etc/resolv.conf | head -n1)
HOST_NETWORK=$(echo "$HOST_NAMESERVER" | awk '{split($0,a,"."); print a[1] "." a[2] "." a[3]}')
cat >>/etc/vz/conf/$VEID.conf <<EOF
OSTEMPLATE=$TEMPLATE_NAME

CONFIG_CUSTOMIZED="yes"
BRIDGEDEV_eth0="brServ"
VETH_IP_ADDRESS_eth0="$HOST_NETWORK.250/24"
VE_DEFAULT_GATEWAY_eth0="$HOST_NETWORK.1"
NAMESERVER="$HOST_NAMESERVER"
EOF

[ -f $TEMPLATE_PRIVATE_DIR/etc/mtab ] && rm $TEMPLATE_PRIVATE_DIR/etc/mtab
[ -f $TEMPLATE_PRIVATE_DIR/etc/mtab ] || ln -s /proc/mounts $TEMPLATE_PRIVATE_DIR/etc/mtab
echo "localhost" > $TEMPLATE_PRIVATE_DIR/etc/hostname
echo "127.0.0.1 localhost.localdomain localhost" > $TEMPLATE_PRIVATE_DIR/etc/hosts

cat >$TEMPLATE_PRIVATE_DIR/etc/apt/sources.list <<EOF
deb ${ARCHIVE_URL} ${UBUNTU_VERSION} main restricted universe multiverse
deb ${ARCHIVE_URL} ${UBUNTU_VERSION}-updates main restricted universe multiverse
deb ${ARCHIVE_URL} ${UBUNTU_VERSION}-security main restricted universe multiverse
EOF

# Remove unneccessary service config
rm $TEMPLATE_PRIVATE_DIR/etc/rc2.d/S99ondemand
rm $TEMPLATE_PRIVATE_DIR/etc/rc3.d/S99ondemand
rm $TEMPLATE_PRIVATE_DIR/etc/rc4.d/S99ondemand
rm $TEMPLATE_PRIVATE_DIR/etc/rc5.d/S99ondemand

cat >> $TEMPLATE_PRIVATE_DIR/etc/apt/apt.conf.d/99NoRecommends <<EOF
APT::Install-Recommends "0";
EOF

install -o root -g root -m 644 $ARCHIVE_FOLDER/etc/fstab $TEMPLATE_PRIVATE_DIR/etc/fstab

# Disable unnecessary upstart config
mkdir -p $TEMPLATE_PRIVATE_DIR/etc/init-disabled

DISABLED_UPSTART_JOBS="control-alt-delete hwclock-save hwclock mountall  mountall-net mountall-reboot  mountall-shell mounted-dev mounted-tmp mounted-varrun network-interface-security network-interface networking plymouth-log plymouth-splash plymouth-stop plymouth rc-sysinit rc rcS tty1 tty2 tty3 tty4 tty5 tty6 udev-finish udev udevmonitor udevtrigger upstart-udev-bridge ureadahead-other ureadahead"

for UPSTART_JOB in $DISABLED_UPSTART_JOBS ; do
	mv -t $TEMPLATE_PRIVATE_DIR/etc/init-disabled $TEMPLATE_PRIVATE_DIR/etc/init/$UPSTART_JOB.conf
done

# Deploy new upstart jobs
NEW_UPSTART_JOBS="mountall networking rc-sysinit rc"

for UPSTART_JOB in $NEW_UPSTART_JOBS ; do
	install -o root -g root -m 644 $ARCHIVE_FOLDER/etc/init/$UBUNTU_VERSION/$UPSTART_JOB.conf $TEMPLATE_PRIVATE_DIR/etc/init/_$UPSTART_JOB.conf
done

vzctl start $VEID

# Divert unnecessary upstart jobs so later upgrades will not put them back
for UPSTART_JOB in $DISABLED_UPSTART_JOBS ; do
	mv -t $TEMPLATE_ROOT_DIR/etc/init $TEMPLATE_ROOT_DIR/etc/init-disabled/$UPSTART_JOB.conf
	vzctl exec $VEID "dpkg-divert --add --rename --divert /etc/init-disabled/$UPSTART_JOB.conf /etc/init/$UPSTART_JOB.conf"
done

vzctl exec $VEID 'apt-get -y purge console-setup console-terminus dhcp3-client dhcp3-common dmsetup eject kbd laptop-detect ntpdate tasksel tasksel-data ubuntu-minimal xkb-data'

vzctl exec $VEID 'cd /dev && /sbin/MAKEDEV ptyp'

vzctl exec $VEID 'apt-get update && apt-get -y -q install ssh'
sed 's/^oom/#oom/' -i $TEMPLATE_ROOT_DIR/etc/init/ssh.conf
vzctl exec $VEID 'start ssh'

install -o root -g root -m 440 $ARCHIVE_FOLDER/etc/sudoers.d/apt-dater $TEMPLATE_ROOT_DIR/etc/sudoers.d/apt-dater
install -o root -g root -m 440 $ARCHIVE_FOLDER/etc/sudoers.d/nagios $TEMPLATE_ROOT_DIR/etc/sudoers.d/nagios

# Replace rsyslog with syslog-ng that works better in an OpenVZ environment
vzctl exec $VEID 'apt-get -y -q install syslog-ng'
vzctl exec $VEID 'dpkg --purge rsyslog'

vzctl exec $VEID 'chmod 700 /root'

vzctl exec $VEID 'usermod -L root'

vzctl exec $VEID 'apt-get -y -q install wget'

vzctl exec $VEID 'apt-get -y -q install language-pack-en-base'

cat >>$TEMPLATE_ROOT_DIR/etc/default/locale <<EOF
LANG="en_CA.UTF-8"
LANGUAGE="en_CA.UTF-8"
LC_ALL="C"
EOF

vzctl exec $VEID 'apt-get -y -q dist-upgrade'

vzctl exec $VEID 'apt-get -y -q install quota iptables vim debconf-utils cron logrotate ca-certificates ssl-cert'

sed -i 's/^"syntax on/syntax on/' $TEMPLATE_ROOT_DIR/etc/vim/vimrc

cp $ARCHIVE_FOLDER/transient/ssmtp.seed $TEMPLATE_ROOT_DIR/root/ssmtp.seed
vzctl exec $VEID 'debconf-set-selections /root/ssmtp.seed'
rm $TEMPLATE_ROOT_DIR/root/ssmtp.seed

vzctl exec $VEID 'apt-get -y -q install ssmtp'

vzctl exec $VEID 'adduser --home /var/lib/apt-dater --disabled-password --gecos "Remote upgrade agent" apt-dater'
SSH_APTDATER_FOLDER=$TEMPLATE_ROOT_DIR/var/lib/apt-dater/.ssh
install -o apt-dater -g apt-dater -m 700 -d $SSH_APTDATER_FOLDER
vzctl exec $VEID 'apt-get -y -q install apt-dater-host imvirt'
vzctl exec $VEID 'sed -i -e "s/^\$CLEANUP=0;$/\$CLEANUP=1;/g" /etc/apt-dater-host.conf'

vzctl exec $VEID 'apt-get -y -q install nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-extra nagios-plugins-standard libmath-calc-units-perl libnagios-plugin-perl'
vzctl exec $VEID 'sed -i "s/^allowed_hosts=.*$/allowed_hosts=10.101.1.4/g" /etc/nagios/nrpe.cfg'
vzctl exec $VEID 'mkdir -p /usr/local/lib/nagios/plugins/'

install -o root -g root -m 755 $ARCHIVE_FOLDER/usr/local/lib/nagios/plugins/check_openvz $TEMPLATE_ROOT_DIR/usr/local/lib/nagios/plugins/check_openvz
install -o root -g root -m 755 $ARCHIVE_FOLDER/usr/local/sbin/vz_beancounters $TEMPLATE_ROOT_DIR/usr/local/sbin/vz_beancounters
install -o root -g root -m 755 $ARCHIVE_FOLDER/usr/local/sbin/vz_reset_beancounters $TEMPLATE_ROOT_DIR/usr/local/sbin/vz_reset_beancounters

install -o root -g root -m 644 $ARCHIVE_FOLDER/etc/nagios/nrpe_local.cfg $TEMPLATE_ROOT_DIR/etc/nagios/nrpe_local.cfg

install -o root -g root -m 644 $ARCHIVE_FOLDER/etc/apt/apt.conf.d/10periodic $TEMPLATE_ROOT_DIR/etc/apt/apt.conf.d/10periodic

vzctl exec $VEID 'rm -f /etc/ssh/ssh_host_*'
install -o root -g root -m 755 $ARCHIVE_FOLDER/etc/rc2.d/S15ssh_gen_host_keys $TEMPLATE_ROOT_DIR/etc/rc2.d/S15ssh_gen_host_keys

vzctl exec $VEID 'sed -i "s/^PermitRootLogin.*$/PermitRootLogin without-password/g" /etc/ssh/sshd_config'

vzctl exec $VEID '> /etc/resolv.conf'

vzctl exec $VEID 'apt-get clean'

vzctl exec $VEID '> /etc/resolv.conf \
> /var/log/messages \
> /var/log/auth.log \
> /var/log/kern.log \
> /var/log/bootstrap.log \
> /var/log/dpkg.log \
> /var/log/syslog \
> /var/log/daemon.log \
> /var/log/apt/term.log \
rm -f /var/log/*.0 /var/log/*.gz'

vzctl stop $VEID

# Final adjustment for the new upstart jobs
for UPSTART_JOB in $NEW_UPSTART_JOBS ; do
	mv $TEMPLATE_PRIVATE_DIR/etc/init/_$UPSTART_JOB.conf $TEMPLATE_PRIVATE_DIR/etc/init/$UPSTART_JOB.conf
done

# Create template
tar -C /vz/private/$VEID --numeric-owner -czf /vz/template/cache/$TEMPLATE_NAME.tar.gz .
vzctl destroy $VEID
rm /etc/vz/conf/$VEID.conf.destroyed

exit 0
