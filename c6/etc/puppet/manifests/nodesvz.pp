
historical

#    package { "vzctl":          ensure => latest, require =>  [ Package ["vzkernel"], Yumrepo ["openvz-utils"] ]}
#    package { "vzkernel":       ensure => latest, require => Yumrepo["openvz-kernel-rhel6"] }
    yumrepo { "openvz-utils":
        baseurl  => "http://download.openvz.org/current/",
        descr    => "OpenVZ utils repository",
        enabled  => 1,
        priority => 1,
        gpgcheck => 0
    }
#    yumrepo { "openvz-kernel-rhel6":
#        baseurl  => "http://download.openvz.org/kernel/branches/rhel6-2.6.32/current/",
#        descr    => "OpenVZ kernel repository",
#        enabled  => 1,
#        priority => 1,
#        gpgcheck => 0
#    }


file { '/etc/vz/vz.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/vz.conf",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/conf/ve-vswap-256m.conf-sample':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/ve-vswap-256m.conf-sample",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/conf/ve-vswap-512m.conf-sample':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/ve-vswap-512m.conf-sample",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/conf/ve-vswap-1024m.conf-sample':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/ve-vswap-1024m.conf-sample",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/conf/ve-unlimited.conf-sample':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/ve-unlimited.conf-sample",
        require => Package["vzkernel"],
    }

    file { '/etc/vz/vznet.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/openvz/vznet.conf",
        require => Package["vzkernel"],
    }

