zzz historical
$str_eth1 = "#!/bin/sh
# Switch the main network interface to eth0
cd /etc/sysconfig/network-scripts
cat >> ifcfg-eth0 <<EOF
DNS1=\"10.100.2.12\"
GATEWAY=\"10.100.2.1\"
IPADDR=\"$LANaddr\"
NETMASK=\"255.255.255.0\"
MTU=\"1500\"
TYPE=\"Ethernet\"
EOF
sed -i '/DNS1/d'    ifcfg-eth1
sed -i '/GATEWAY/d' ifcfg-eth1
sed -i '/IPADDR/d'  ifcfg-eth1
sed -i '/NETMASK/d' ifcfg-eth1
sed -i '/MTU/d'     ifcfg-eth1
# when we reboot we will come up using eth0.
"
    file { '/etc/sysconfig/network-scripts/cirrus-eth1-eth0':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        content => "$str_eth1",
    }
#        source => "puppet:///modules/etc/cirrus-eth1-eth0",
