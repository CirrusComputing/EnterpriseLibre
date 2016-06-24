# Initial configuration for physical OpenVZ servers.
# Puppet Agent need only be run once when installing the server, and again if anything needs to be changed.
#
# 2012 08 29 Rick Leir
# 2013 02 19 Nagios nrpe has new packages
# 2013 04 02 recurse in directories, correct requires
# 2013 12 16 shorewall masq file needs the vlan100 IP
#
class base {

}

class ssh_setup {
    # create directory
    file {  "/root/.ssh" :
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 700,
    }
    
    file { '/root/.ssh/authorized_keys':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0600,
        source => "puppet:///modules/ssh/authorized_keys",
        require => File["/root/.ssh"],
    }
}

class sbin_setup {
    file { '/usr/sbin/cirrus-create-lvolume':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/sbin/cirrus-create-lvolume",
    }
}

class volume_group_setup {
    physical_volume { "/dev/sda4":
        ensure => present
    }

    volume_group { "mastervg":
        ensure => present,
        physical_volumes => "/dev/sda4",
        require => [ Physical_volume["/dev/sda4"] ]
    }
}

class ubuntu_setup {

    file { '/vz/template/cache/ubuntu-10.04-i386-eseri-1.8.tar.gz':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/ubuntu/ubuntu-10.04-i386-eseri-1.8.tar.gz",
        require => Package["vzctl"],
    }
    file { '/vz/template/cache/ubuntu-12.04-i386-eseri-1.0.tar.gz':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/ubuntu/ubuntu-12.04-i386-eseri-1.0.tar.gz",
        require => Package["vzctl"],
    }
}


class etc_setup {

    exec { "create_needed_git1":
        command => "bash -c 'cd /etc/; git init'",
        path    => "/usr/bin/:/bin/",
        creates => "/etc/.git"
    }

    $str_network = "NETWORKING=yes
HOSTNAME=$::fqdn
GATEWAY=209.87.243.65
GATEWAYDEV=vlan100
NOZEROCONF=true
NETWORKING_IPV6=no
"
#                  or $clientcert certname
    file { '/etc/sysconfig/network':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "$str_network",
    }

    $str_eth0 = "DEVICE=\"eth0\"
BOOTPROTO=\"static\"
HWADDR=\"$::macaddress_eth0\"
NM_CONTROLLED=\"yes\"
ONBOOT=\"yes\"
"
    file { '/etc/sysconfig/network-scripts/ifcfg-eth0':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "$str_eth0",
    }

# Cobbler / Anaconda left us with eth1 as the main LAN if. We need to overwrite that:    
    $str_eth1 = "DEVICE=\"eth1\"
BOOTPROTO=\"static\"
HWADDR=\"$::macaddress_eth1\"
NM_CONTROLLED=\"yes\"
ONBOOT=\"yes\"
"
    file { '/etc/sysconfig/network-scripts/ifcfg-eth1':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "$str_eth1",
    }

    # external IP's for phys servers.
    # there are more elgant ways to manage IP's but this was quicker.
    case $::hostname {
        'freyja': { $ipaddr = "209.87.243.90" }
        'tenris': { $ipaddr = "209.87.243.81" }
        'odin':   { $ipaddr = "209.87.243.86" }
        'odin74':   { $ipaddr = "209.87.243.80" }
        'odin75':   { $ipaddr = "209.87.243.80" }
        'odin76':   { $ipaddr = "209.87.243.0" }
        'odin77':   { $ipaddr = "209.87.243.0" }
        'odin78':   { $ipaddr = "209.87.243.0" }
        'odin79':   { $ipaddr = "209.87.243.0" }
        'odin80':   { $ipaddr = "209.87.243.0" }
        'odin81':   { $ipaddr = "209.87.243.0" }
        'odin82':   { $ipaddr = "209.87.243.0" }
        'odin83':   { $ipaddr = "209.87.243.0" }
        'odin84':   { $ipaddr = "209.87.243.0" }
        'odin85':   { $ipaddr = "209.87.243.0" }
        'odin86':   { $ipaddr = "209.87.243.0" }
        'odin87':   { $ipaddr = "209.87.243.0" }
        'odin88':   { $ipaddr = "209.87.243.0" }
        'odin89':   { $ipaddr = "209.87.243.0" }
        'odin90':   { $ipaddr = "209.87.243.0" }
        'odin91':   { $ipaddr = "209.87.243.0" }
        'odin92':   { $ipaddr = "209.87.243.0" }
        'odin93':   { $ipaddr = "209.87.243.0" }
        'odin94':   { $ipaddr = "209.87.243.0" }
        'odin95':   { $ipaddr = "209.87.243.0" }
        'odin96':   { $ipaddr = "209.87.243.0" }
        'odin97':   { $ipaddr = "209.87.243.0" }
        'odin98':   { $ipaddr = "209.87.243.0" }
        'odin99':   { $ipaddr = "209.87.243.0" }
        'odin100':   { $ipaddr = "209.87.243.0" }
        'odin101':   { $ipaddr = "209.87.243.0" }
        'odin102':   { $ipaddr = "209.87.243.0" }
        'odin103':   { $ipaddr = "209.87.243.0" }
        'odin104':   { $ipaddr = "209.87.243.0" }
        'odin105':   { $ipaddr = "209.87.243.0" }
        'odin106':   { $ipaddr = "209.87.243.0" }
        'odin107':   { $ipaddr = "209.87.243.0" }
        'odin108':   { $ipaddr = "209.87.243.0" }
        'odin109':   { $ipaddr = "209.87.243.0" }
        'odin110':   { $ipaddr = "209.87.243.0" }
        'odin111':   { $ipaddr = "209.87.243.0" }
        'odin112':   { $ipaddr = "209.87.243.0" }
        'odin113':   { $ipaddr = "209.87.243.0" }
        'odin114':   { $ipaddr = "209.87.243.0" }
        'odin115':   { $ipaddr = "209.87.243.0" }
        'odin116':   { $ipaddr = "209.87.243.0" }
        'odin117':   { $ipaddr = "209.87.243.0" }
        'odin118':   { $ipaddr = "209.87.243.0" }
        'odin119':   { $ipaddr = "209.87.243.0" }
        'odin120':   { $ipaddr = "209.87.243.0" }
        'odin121':   { $ipaddr = "209.87.243.0" }
        'odin122':   { $ipaddr = "209.87.243.0" }
        'odin123':   { $ipaddr = "209.87.243.0" }
        'odin124':   { $ipaddr = "209.87.243.0" }
        'odin125':   { $ipaddr = "209.87.243.0" }
        'odin126':   { $ipaddr = "209.87.243.0" }
        'odin127':   { $ipaddr = "209.87.243.0" }
        'odin128':   { $ipaddr = "209.87.243.0" }
        'odin129':   { $ipaddr = "209.87.243.0" }
        'odin130':   { $ipaddr = "209.87.243.0" }
        'odin131':   { $ipaddr = "209.87.243.0" }
        'odin132':   { $ipaddr = "209.87.243.0" }
        'odin133':   { $ipaddr = "209.87.243.0" }
        'odin134':   { $ipaddr = "209.87.243.0" }
        'odin135':   { $ipaddr = "209.87.243.0" }
        'odin136':   { $ipaddr = "209.87.243.0" }
        'odin137':   { $ipaddr = "209.87.243.0" }
        'odin138':   { $ipaddr = "209.87.243.0" }
        'odin139':   { $ipaddr = "209.87.243.0" }
        'odin140':   { $ipaddr = "209.87.243.0" }
        'odin141':   { $ipaddr = "209.87.243.0" }
        'odin142':   { $ipaddr = "209.87.243.0" }
        'odin143':   { $ipaddr = "209.87.243.0" }
        'odin144':   { $ipaddr = "209.87.243.0" }
        'odin145':   { $ipaddr = "209.87.243.0" }
        'odin146':   { $ipaddr = "209.87.243.0" }
        'odin147':   { $ipaddr = "209.87.243.0" }
        'odin148':   { $ipaddr = "209.87.243.0" }
        'odin149':   { $ipaddr = "209.87.243.0" }
        'odin150':   { $ipaddr = "209.87.243.0" }
        'odin151':   { $ipaddr = "209.87.243.0" }
        'odin152':   { $ipaddr = "209.87.243.0" }
        'odin153':   { $ipaddr = "209.87.243.0" }
        'odin154':   { $ipaddr = "209.87.243.0" }
        'odin155':   { $ipaddr = "209.87.243.0" }
        'odin156':   { $ipaddr = "209.87.243.0" }
        'odin157':   { $ipaddr = "209.87.243.0" }
        'odin158':   { $ipaddr = "209.87.243.0" }
        'odin159':   { $ipaddr = "209.87.243.0" }
        'odin160':   { $ipaddr = "209.87.243.0" }
        'odin161':   { $ipaddr = "209.87.243.0" }
        'odin162':   { $ipaddr = "209.87.243.0" }
        'odin163':   { $ipaddr = "209.87.243.0" }
        'odin164':   { $ipaddr = "209.87.243.0" }
        'odin165':   { $ipaddr = "209.87.243.0" }
        'odin166':   { $ipaddr = "209.87.243.0" }
        'odin167':   { $ipaddr = "209.87.243.0" }
        'odin168':   { $ipaddr = "209.87.243.0" }
        'odin169':   { $ipaddr = "209.87.243.0" }
        'odin170':   { $ipaddr = "209.87.243.0" }
        'odin171':   { $ipaddr = "209.87.243.0" }
        'odin172':   { $ipaddr = "209.87.243.0" }
        'odin173':   { $ipaddr = "209.87.243.0" }
        'odin174':   { $ipaddr = "209.87.243.0" }
        'odin175':   { $ipaddr = "209.87.243.0" }
        'odin176':   { $ipaddr = "209.87.243.0" }
        'odin177':   { $ipaddr = "209.87.243.0" }
        'odin178':   { $ipaddr = "209.87.243.0" }
        'odin179':   { $ipaddr = "209.87.243.0" }
        'odin180':   { $ipaddr = "209.87.243.0" }
        'odin181':   { $ipaddr = "209.87.243.0" }
        'odin182':   { $ipaddr = "209.87.243.0" }
        'odin183':   { $ipaddr = "209.87.243.0" }
        'odin184':   { $ipaddr = "209.87.243.0" }
        'odin185':   { $ipaddr = "209.87.243.0" }
        'odin186':   { $ipaddr = "209.87.243.0" }
        'odin187':   { $ipaddr = "209.87.243.0" }
        'odin188':   { $ipaddr = "209.87.243.0" }
        'odin189':   { $ipaddr = "209.87.243.0" }
        'odin190':   { $ipaddr = "209.87.243.0" }
        'odin191':   { $ipaddr = "209.87.243.0" }
        'odin192':   { $ipaddr = "209.87.243.0" }
        'odin193':   { $ipaddr = "209.87.243.0" }
        'odin194':   { $ipaddr = "209.87.243.0" }
        'odin195':   { $ipaddr = "209.87.243.0" }
        'odin196':   { $ipaddr = "209.87.243.0" }
        'odin197':   { $ipaddr = "209.87.243.0" }
        'odin198':   { $ipaddr = "209.87.243.0" }
        'odin199':   { $ipaddr = "209.87.243.0" }
    }

    case $::hostname {
        'freyja': { $LANaddr = "10.100.2.2" }
        'tenris': { $LANaddr = "10.100.2.4" }
        'odin':   { $LANaddr = "10.100.2.5" }
        'odin74':  { $LANaddr = "10.100.2.74" }
        'odin75':  { $LANaddr = "10.100.2.75" }
        'odin76':  { $LANaddr = "10.100.2.76" }
        'odin77':  { $LANaddr = "10.100.2.77" }
        'odin78':  { $LANaddr = "10.100.2.78" }
        'odin79':  { $LANaddr = "10.100.2.79" }
        'odin80':  { $LANaddr = "10.100.2.80" }
        'odin81':  { $LANaddr = "10.100.2.81" }
        'odin82':  { $LANaddr = "10.100.2.82" }
        'odin83':  { $LANaddr = "10.100.2.83" }
        'odin84':  { $LANaddr = "10.100.2.84" }
        'odin85':  { $LANaddr = "10.100.2.85" }
        'odin86':  { $LANaddr = "10.100.2.86" }
        'odin87':  { $LANaddr = "10.100.2.87" }
        'odin88':  { $LANaddr = "10.100.2.88" }
        'odin89':  { $LANaddr = "10.100.2.89" }
        'odin90':  { $LANaddr = "10.100.2.90" }
        'odin91':  { $LANaddr = "10.100.2.91" }
        'odin92':  { $LANaddr = "10.100.2.92" }
        'odin93':  { $LANaddr = "10.100.2.93" }
        'odin94':  { $LANaddr = "10.100.2.94" }
        'odin95':  { $LANaddr = "10.100.2.95" }
        'odin96':  { $LANaddr = "10.100.2.96" }
        'odin97':  { $LANaddr = "10.100.2.97" }
        'odin98':  { $LANaddr = "10.100.2.98" }
        'odin99':  { $LANaddr = "10.100.2.99" }
        'odin100':  { $LANaddr = "10.100.2.100" }
        'odin101':  { $LANaddr = "10.100.2.101" }
        'odin102':  { $LANaddr = "10.100.2.102" }
        'odin103':  { $LANaddr = "10.100.2.103" }
        'odin104':  { $LANaddr = "10.100.2.104" }
        'odin105':  { $LANaddr = "10.100.2.105" }
        'odin106':  { $LANaddr = "10.100.2.106" }
        'odin107':  { $LANaddr = "10.100.2.107" }
        'odin108':  { $LANaddr = "10.100.2.108" }
        'odin109':  { $LANaddr = "10.100.2.109" }
        'odin110':  { $LANaddr = "10.100.2.110" }
        'odin111':  { $LANaddr = "10.100.2.111" }
        'odin112':  { $LANaddr = "10.100.2.112" }
        'odin113':  { $LANaddr = "10.100.2.113" }
        'odin114':  { $LANaddr = "10.100.2.114" }
        'odin115':  { $LANaddr = "10.100.2.115" }
        'odin116':  { $LANaddr = "10.100.2.116" }
        'odin117':  { $LANaddr = "10.100.2.117" }
        'odin118':  { $LANaddr = "10.100.2.118" }
        'odin119':  { $LANaddr = "10.100.2.119" }
        'odin120':  { $LANaddr = "10.100.2.120" }
        'odin121':  { $LANaddr = "10.100.2.121" }
        'odin122':  { $LANaddr = "10.100.2.122" }
        'odin123':  { $LANaddr = "10.100.2.123" }
        'odin124':  { $LANaddr = "10.100.2.124" }
        'odin125':  { $LANaddr = "10.100.2.125" }
        'odin126':  { $LANaddr = "10.100.2.126" }
        'odin127':  { $LANaddr = "10.100.2.127" }
        'odin128':  { $LANaddr = "10.100.2.128" }
        'odin129':  { $LANaddr = "10.100.2.129" }
        'odin130':  { $LANaddr = "10.100.2.130" }
        'odin131':  { $LANaddr = "10.100.2.131" }
        'odin132':  { $LANaddr = "10.100.2.132" }
        'odin133':  { $LANaddr = "10.100.2.133" }
        'odin134':  { $LANaddr = "10.100.2.134" }
        'odin135':  { $LANaddr = "10.100.2.135" }
        'odin136':  { $LANaddr = "10.100.2.136" }
        'odin137':  { $LANaddr = "10.100.2.137" }
        'odin138':  { $LANaddr = "10.100.2.138" }
        'odin139':  { $LANaddr = "10.100.2.139" }
        'odin140':  { $LANaddr = "10.100.2.140" }
        'odin141':  { $LANaddr = "10.100.2.141" }
        'odin142':  { $LANaddr = "10.100.2.142" }
        'odin143':  { $LANaddr = "10.100.2.143" }
        'odin144':  { $LANaddr = "10.100.2.144" }
        'odin145':  { $LANaddr = "10.100.2.145" }
        'odin146':  { $LANaddr = "10.100.2.146" }
        'odin147':  { $LANaddr = "10.100.2.147" }
        'odin148':  { $LANaddr = "10.100.2.148" }
        'odin149':  { $LANaddr = "10.100.2.149" }
        'odin150':  { $LANaddr = "10.100.2.150" }
        'odin151':  { $LANaddr = "10.100.2.151" }
        'odin152':  { $LANaddr = "10.100.2.152" }
        'odin153':  { $LANaddr = "10.100.2.153" }
        'odin154':  { $LANaddr = "10.100.2.154" }
        'odin155':  { $LANaddr = "10.100.2.155" }
        'odin156':  { $LANaddr = "10.100.2.156" }
        'odin157':  { $LANaddr = "10.100.2.157" }
        'odin158':  { $LANaddr = "10.100.2.158" }
        'odin159':  { $LANaddr = "10.100.2.159" }
        'odin160':  { $LANaddr = "10.100.2.160" }
        'odin161':  { $LANaddr = "10.100.2.161" }
        'odin162':  { $LANaddr = "10.100.2.162" }
        'odin163':  { $LANaddr = "10.100.2.163" }
        'odin164':  { $LANaddr = "10.100.2.164" }
        'odin165':  { $LANaddr = "10.100.2.165" }
        'odin166':  { $LANaddr = "10.100.2.166" }
        'odin167':  { $LANaddr = "10.100.2.167" }
        'odin168':  { $LANaddr = "10.100.2.168" }
        'odin169':  { $LANaddr = "10.100.2.169" }
        'odin170':  { $LANaddr = "10.100.2.170" }
        'odin171':  { $LANaddr = "10.100.2.171" }
        'odin172':  { $LANaddr = "10.100.2.172" }
        'odin173':  { $LANaddr = "10.100.2.173" }
        'odin174':  { $LANaddr = "10.100.2.174" }
        'odin175':  { $LANaddr = "10.100.2.175" }
        'odin176':  { $LANaddr = "10.100.2.176" }
        'odin177':  { $LANaddr = "10.100.2.177" }
        'odin178':  { $LANaddr = "10.100.2.178" }
        'odin179':  { $LANaddr = "10.100.2.179" }
        'odin180':  { $LANaddr = "10.100.2.180" }
        'odin181':  { $LANaddr = "10.100.2.181" }
        'odin182':  { $LANaddr = "10.100.2.182" }
        'odin183':  { $LANaddr = "10.100.2.183" }
        'odin184':  { $LANaddr = "10.100.2.184" }
        'odin185':  { $LANaddr = "10.100.2.185" }
        'odin186':  { $LANaddr = "10.100.2.186" }
        'odin187':  { $LANaddr = "10.100.2.187" }
        'odin188':  { $LANaddr = "10.100.2.188" }
        'odin189':  { $LANaddr = "10.100.2.189" }
        'odin190':  { $LANaddr = "10.100.2.190" }
        'odin191':  { $LANaddr = "10.100.2.191" }
        'odin192':  { $LANaddr = "10.100.2.192" }
        'odin193':  { $LANaddr = "10.100.2.193" }
        'odin194':  { $LANaddr = "10.100.2.194" }
        'odin195':  { $LANaddr = "10.100.2.195" }
        'odin196':  { $LANaddr = "10.100.2.196" }
        'odin197':  { $LANaddr = "10.100.2.197" }
        'odin198':  { $LANaddr = "10.100.2.198" }
        'odin199':  { $LANaddr = "10.100.2.199" }
    }
#can continue to 199


#        'odin6':  { $LANaddr = "10.100.2.6" }
#        'odin7':  { $LANaddr = "10.100.2.7" }
#        'odin8':  { $LANaddr = "10.100.2.8" }
#        'odin9':  { $LANaddr = "10.100.2.9" }
#        'odin10':  { $LANaddr = "10.100.2.10" }
#        'odin11':  { $LANaddr = "10.100.2.11" }
#        'odin12':  { $LANaddr = "10.100.2.12" }
#        'odin13':  { $LANaddr = "10.100.2.13" }
#        'odin14':  { $LANaddr = "10.100.2.14" }
#        'odin15':  { $LANaddr = "10.100.2.15" }
#        'odin16':  { $LANaddr = "10.100.2.16" }
#        'odin17':  { $LANaddr = "10.100.2.17" }
#        'odin18':  { $LANaddr = "10.100.2.18" }
#        'odin19':  { $LANaddr = "10.100.2.19" }
#        'odin20':  { $LANaddr = "10.100.2.20" }
#        'odin21':  { $LANaddr = "10.100.2.21" }
#        'odin22':  { $LANaddr = "10.100.2.22" }
#        'odin23':  { $LANaddr = "10.100.2.23" }
#        'odin24':  { $LANaddr = "10.100.2.24" }
#        'odin25':  { $LANaddr = "10.100.2.25" }
#        'odin26':  { $LANaddr = "10.100.2.26" }
#        'odin27':  { $LANaddr = "10.100.2.27" }
#        'odin28':  { $LANaddr = "10.100.2.28" }
#        'odin29':  { $LANaddr = "10.100.2.29" }
#        'odin30':  { $LANaddr = "10.100.2.30" }
#        'odin31':  { $LANaddr = "10.100.2.31" }
#        'odin32':  { $LANaddr = "10.100.2.32" }
#        'odin33':  { $LANaddr = "10.100.2.33" }
#        'odin34':  { $LANaddr = "10.100.2.34" }
#        'odin35':  { $LANaddr = "10.100.2.35" }
#        'odin36':  { $LANaddr = "10.100.2.36" }
#        'odin37':  { $LANaddr = "10.100.2.37" }
#        'odin38':  { $LANaddr = "10.100.2.38" }
#        'odin39':  { $LANaddr = "10.100.2.39" }
#        'odin40':  { $LANaddr = "10.100.2.40" }
#        'odin41':  { $LANaddr = "10.100.2.41" }
#        'odin42':  { $LANaddr = "10.100.2.42" }
#        'odin43':  { $LANaddr = "10.100.2.43" }
#        'odin44':  { $LANaddr = "10.100.2.44" }
#        'odin45':  { $LANaddr = "10.100.2.45" }
#        'odin46':  { $LANaddr = "10.100.2.46" }
#        'odin47':  { $LANaddr = "10.100.2.47" }
#        'odin48':  { $LANaddr = "10.100.2.48" }
#        'odin49':  { $LANaddr = "10.100.2.49" }
#        'odin50':  { $LANaddr = "10.100.2.50" }
#        'odin51':  { $LANaddr = "10.100.2.51" }
#        'odin52':  { $LANaddr = "10.100.2.52" }
#        'odin53':  { $LANaddr = "10.100.2.53" }
#        'odin54':  { $LANaddr = "10.100.2.54" }
#        'odin55':  { $LANaddr = "10.100.2.55" }
#        'odin56':  { $LANaddr = "10.100.2.56" }
#        'odin57':  { $LANaddr = "10.100.2.57" }
#        'odin58':  { $LANaddr = "10.100.2.58" }
#        'odin59':  { $LANaddr = "10.100.2.59" }
#        'odin60':  { $LANaddr = "10.100.2.60" }
#        'odin61':  { $LANaddr = "10.100.2.61" }
#        'odin62':  { $LANaddr = "10.100.2.62" }
#zz        'odin63':  { $LANaddr = "10.100.2.63" }
#        'odin64':  { $LANaddr = "10.100.2.64" }
#        'odin65':  { $LANaddr = "10.100.2.65" }
#        'odin66':  { $LANaddr = "10.100.2.66" }
#        'odin67':  { $LANaddr = "10.100.2.67" }
#        'odin68':  { $LANaddr = "10.100.2.68" }
#        'odin69':  { $LANaddr = "10.100.2.69" }
#        'odin70':  { $LANaddr = "10.100.2.70" }
#        'odin71':  { $LANaddr = "10.100.2.71" }
#        'odin72':  { $LANaddr = "10.100.2.72" }
#        'odin73':  { $LANaddr = "10.100.2.73" }

    $str_vlan100 = "VLAN=yes
VLAN_NAME_TYPE=VLAN_PLUS_VID_NO_PAD
DEVICE=vlan100
PHYSDEV=eth0
BOOTPROTO=static
ONBOOT=yes
TYPE=Ethernet
IPADDR=$ipaddr
NETMASK=255.255.255.224
"
    file { '/etc/sysconfig/network-scripts/ifcfg-vlan100':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "$str_vlan100",
    }

    $str_vlan200 = "VLAN=yes
VLAN_NAME_TYPE=VLAN_PLUS_VID_NO_PAD
DEVICE=vlan200
PHYSDEV=eth0
BOOTPROTO=static
ONBOOT=yes
TYPE=Ethernet
BRIDGE=brServ
"
    file { '/etc/sysconfig/network-scripts/ifcfg-vlan200':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
	content => "$str_vlan200",
    }

    $str_brServ = "DEVICE=brServ
TYPE=Bridge
BOOTPROTO=static
IPADDR=$LANaddr
NETMASK=255.255.255.0
ONBOOT=yes
"
    file { '/etc/sysconfig/network-scripts/ifcfg-brServ':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
	content => "$str_brServ",
    }

    file { '/etc/sysconfig/network-scripts/route-brServ':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "10.0.0.0/8 via 10.100.2.1 dev brServ\n",
    }

    file { '/etc/sysconfig/network-scripts/route-vlan200':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        content => "10.0.0.0/8 via 10.100.2.1 dev vlan200\n",
    }

    
    file { '/etc/sysconfig/network-scripts/cirrus-add-ip':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/etc/cirrus-add-ip",
    }

    file { '/etc/sysconfig/network-scripts/cirrus-add-bridge':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/etc/cirrus-add-bridge",
    }

    file { '/etc/sysconfig/network-scripts/cirrus-del-ip':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/etc/cirrus-del-ip",
    }

    file { '/etc/sysconfig/network-scripts/cirrus-del-bridge':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/etc/cirrus-del-bridge",
    }
    package { "vzquota":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/vz/vzquota-3.1-1.x86_64.rpm",
        require =>  Package ["vzkernel"]
    }
    package { "vzctl-core":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/vz/vzctl-core-4.2-1.x86_64.rpm",
        require =>  Package ["vzkernel"]
    }
    package { "vzctl":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/vz/vzctl-4.2-1.x86_64.rpm",
        require => [ Package ["vzkernel"],
                     Package ["vzquota"],
                     Package ["vzctl-core"]]
    }
#    package { "vzkernel-firmware":
#        provider => rpm,
#        ensure => installed,
#        source => "http://borvo2/vz/vzkernel-firmware-2.6.32-042stab076.5.noarch.rpm",
#    }
    package { "vzkernel":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/vz/vzkernel-2.6.32-042stab076.5.x86_64.rpm",
    }
      
#    package { "openssh-server": ensure => latest   }

    # a package from rpmforge
    service { "nrpe":
        enable => true,
    }
 
    package { "nagios-common":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-common-3.4.4-1.el6.x86_64.rpm",
    }
    package { "nagios-plugins":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-plugins-1.4.16-5.el6.x86_64.rpm",
        require => Package["nagios-common"],
    }
#            require =>  Service["nrpe"],

    package { "nagios-nrpe": 
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/rpmforge/nagios-nrpe-2.14-1.el6.rf.x86_64.rpm",
        require => Package["nagios-plugins"],
    }
    package { "nagios-plugins-disk":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-plugins-disk-1.4.16-5.el6.x86_64.rpm",
        require => Package["nagios-plugins"],   }
    package { "nagios-plugins-load":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-plugins-load-1.4.16-5.el6.x86_64.rpm",
        require => Package["nagios-plugins"],   }
    package { "nagios-plugins-users":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-plugins-users-1.4.16-5.el6.x86_64.rpm",
        require => Package["nagios-plugins"],   }
    package { "nagios-plugins-procs":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/epel/nagios-plugins-procs-1.4.16-5.el6.x86_64.rpm",
        require => Package["nagios-plugins"],   }
 
    # nagios config 
    file { "/etc/nagios/nrpe.cfg":
        notify  => Service["nrpe"],  # restart nrpe
        mode    => 644,
        owner   => "root",
        group   => "root",
        source => "puppet:///modules/nagios/nrpe.cfg",
        require => Package["nagios-nrpe"],
    }

#        content => template(""),

    service { "ntpd":
        enable => true,
#        require => Package[""],
    }

#    package { "rpmforge-release": 
#        provider => rpm,
#        ensure => installed,
#        source => "http://borvo2/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm",
#    }

    # a package from rpmforge
    package { "perl-Regexp-Common":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/rpmforge/perl-Regexp-Common-2010010201-2.el6.rf.noarch.rpm",
    }

    # get dir tree
    file { '/etc/vz':
        source => "puppet:///modules/openvz",
        recurse => true,
        require => Package["vzkernel"],
    }
    file { '/usr/sbin/vznetcfg.custom':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0755,
        source => "puppet:///modules/openvz/vznetcfg.custom",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/dists/scripts/debian-set_hostname.sh':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0755,
        source => "puppet:///modules/openvz/debian-set_hostname.sh",
        require => Package["vzkernel"],
    }

    # link the vz dir to where our scripts expect it to be
    file { '/var/lib/vz':
        ensure => 'link',
        target => '/vz',
    }

#         source => "http://www.invoca.ch/pub/packages/shorewall/RPMS/ils-6/noarch/shorewall-core-4.5.14.0-3.el6.noarch.rpm",  
#         source => "http://www.invoca.ch/pub/packages/shorewall/RPMS/ils-6/noarch/shorewall-4.5.14.0-3.el6.noarch.rpm",
    package { "shorewall-core": 
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/shorewall/shorewall-core-4.5.14.0-3.el6.noarch.rpm",  
    }
    package { "shorewall": 
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/shorewall/shorewall-4.5.14.0-3.el6.noarch.rpm",
        require => Package["shorewall-core"],
    }

    # get dir tree, except the macros
    file { "/etc/shorewall":
        source => "puppet:///modules/shorewall",
        recurse => true,
        ignore => ["macro.HTTP8080", "macro.HTTP8081"],
        require => Package["shorewall"],
    }
  
    exec { "create_needed_git":
        command => "bash -c 'cd /etc/shorewall; git init'",
        path    => "/usr/bin/:/bin/",
        creates => "/etc/shorewall/.git",
        require => File["/etc/shorewall"],
    }

    file { '/usr/share/shorewall/macro.HTTP8080':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/macro.HTTP8080",
        require => Package["shorewall"],
    }
    file { '/usr/share/shorewall/macro.HTTP8081':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/macro.HTTP8081",
        require => Package["shorewall"],
    }

    $str_masq = "#
#INTERFACE:DEST		SOURCE		ADDRESS		PROTO	PORT(S)	IPSEC	MARK	USER/
#											GROUP
vlan100                 10.100.2.0/24  $ipaddr
vlan100                 10.101.0.0/16  $ipaddr
"
    file { '/etc/shorewall/masq':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
	content => "$str_masq",
    }

    # Network Time Protocol
    file { '/etc/ntp.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/ntp/ntp.conf",
    }

    # Kernel tuning parameters
    file { '/etc/sysctl.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/kernel/sysctl.conf",
    }

    # for hpacucli
    package { "glibc":          ensure => latest,}
    package { "glibc-common":   ensure => latest,}
    package { "libgcc":         ensure => latest,}
    package { "libstdc++":      ensure => latest,}
    
    # a utility to check RAID
    package { "hpacucli":
        provider => rpm,
        ensure => installed,
        source => "http://borvo2/raid/hpacucli-9.30-15.0.i386.rpm",
        require => [ Package["glibc"],
                     Package ["glibc-common"],
                     Package ["libgcc"],
                     Package ["libstdc++"],
                     ]
    }
#                     Package [""],
    
    # cron job to check RAID
    # zzz replace this with nagios check_cciss-1.11
    file { '/etc/cron.hourly/1raid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/raid/1raid",
    }

}
