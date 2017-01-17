# Cirrus Kickstart for installing physical servers
# Nov 2012 Rick Leir
#
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL

# Firewall configuration
firewall --disabled

# Install OS instead of upgrade
install
# Use USB installation media
# harddrive --partition=sda --dir=/tmp
# url --url http://$server/cobbler/ks_mirror/Centos6-x86_64/
url --url=$tree

# set up any repos that are associated with the given cobbler profile, for use during install time
$yum_repo_stanza

# Root password
rootpw --iscrypted $1$SgJpL724$KuhiXylYjo6xweMNLKZDN1
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --disabled
# Installation logging level
logging --level=info

# Reboot after installation
reboot --eject

# System timezone
timezone --isUtc America/Toronto
# Network information
network  --bootproto=static --device=eth1 --gateway=10.100.2.1 --ip=10.100.2.3 --nameserver=10.100.2.12 --netmask=255.255.255.0 --onboot=on
#network  --bootproto=static --device=eth0 --gateway=192.168.3.2 --ip=192.168.3.111 --nameserver=192.168.3.82 --netmask=255.255.255.0 --onboot=on

# System bootloader configuration
bootloader --location=mbr

# we want grub to write to sdb
#bootloader --driveorder=sdb,sda --location=mbr


# Clear the Master Boot Record
zerombr
# Partition clearing information
# NO: the %pre disk label will be clobbered
#clearpart --all --initlabel 

# Disk partitioning information
part /        --fstype="ext4" --size=20000
part /dev/shm --fstype="ext4" --size=48000
part /boot    --fstype="ext4" --size=485 --asprimary 
part /home    --fstype="ext4" --size=1   --grow

%packages
rubygems  
@base
@client-mgmt-tools
@console-internet
@debugging
@hardware-monitoring
ruby
ruby-libs
puppet  
facter  
ruby-shadow 
mcollective 
mcollective-client 
mcollective-common 
rubygem-stomp
ntpdate
emacs-nox
%end

%pre
$SNIPPET('log_ks_pre')
$kickstart_start
$SNIPPET('pre_anamon')

/usr/sbin/parted -s /dev/sda mklabel gpt

# set initial time
# /usr/sbin/ntpdate -b pool.ntp.org
# or maybe ntpd -gqx
%end

%post --nochroot
# Copy netinfo, which has our FQDN from DHCP, into the chroot
test -f /tmp/netinfo && cp /tmp/netinfo /mnt/sysimage/tmp/
##
## Workflow:  Turn on puppet for next boot, set hosts and resolv.conf, then
## figure out the hostname.  Write a new /etc/sysconfig/network file to keep
## the hostname, then set the hostname and run puppet to get the certificate.
## Sign it on the other side during first boot.

%post 
$SNIPPET('log_ks_post')
$yum_config_stanza

$SNIPPET('download_config_files')

# set initial time
/usr/sbin/ntpdate -b pool.ntp.org
# or maybe ntpd -gqx

# set the hw clock
/sbin/hwclock --set --date="`/bin/date`"

# turn on puppet
/sbin/chkconfig --level 345 puppet on
#/bin/echo "192.168.3.82 puppet" >> /etc/hosts
/bin/echo "10.100.2.202 puppet" >> /etc/hosts
#/bin/echo "nameserver 192.168.3.82" >> /etc/resolv.conf
/bin/echo "nameserver 10.100.2.202" >> /etc/resolv.conf
hostname $hostname
# Write out the hostname to a file for reboot.
/bin/echo -e "NETWORKING=yes\nHOSTNAME=$hostname" > /etc/sysconfig/network
/usr/bin/puppet agent -tv

yum -y upgrade
$SNIPPET('post_anamon')
$kickstart_done
$SNIPPET('kickstart_done')
%end