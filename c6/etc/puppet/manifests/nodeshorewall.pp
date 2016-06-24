zzz historical

    file { "/tmp/shorewall-core-4.5.14.0-3.el6.noarch.rpm":
        source => "puppet:///modules/shorewall/shorewall-core-4.5.14.0-3.el6.noarch.rpm",
        notify => Exec["install-shorewall-core"],
        require => Package["perl-Digest-SHA1"],
    }
    exec { "install-shorewall-core":
        command => "/bin/rpm -Uvh /tmp/shorewall-core-4.5.14.0-3.el6.noarch.rpm",
        refreshonly => true,
    }
zzzz

file { '/etc/shorewall/shorewall.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/shorewall.conf",
        require => Package["shorewall"],
    }

    file { '/etc/shorewall/interfaces':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/interfaces",
        require => File["/etc/shorewall"],
    }

    file { '/etc/shorewall/masq':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/masq",
        require => File["/etc/shorewall"],
    }

    file { '/etc/shorewall/policy':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/policy",
        require => File["/etc/shorewall"],
    }

    file { '/etc/shorewall/routestopped':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/routestopped",
        require => File["/etc/shorewall"],
    }

    file { '/etc/shorewall/rules':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/rules",
        require => File["/etc/shorewall"],
    }

    file { '/etc/shorewall/zones':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/zones",
    }
    # create directory
    file { [ "/etc/shorewall/",
             "/etc/shorewall/orgs.local/",
             "/etc/shorewall/orgs.local/.TEMPLATE" ]:
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 755,
        require => Package["shorewall"],
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/interfaces':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/orgs.local/interfaces",
        require => File["/etc/shorewall"],
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/masq':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/masq",
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/policy':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/orgs.local/policy",
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/routestopped':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/orgs.local/routestopped",
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/rules':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/orgs.local/rules",
    }
    file { '/etc/shorewall/orgs.local/.TEMPLATE/zones':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0644,
        source => "puppet:///modules/shorewall/orgs.local/zones",
    }

    file { '/etc/shorewall/orgs.local/cirrus-add-org':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/shorewall/cirrus-add-org",
        require => File["/etc/shorewall/orgs.local"],
    }
    file { '/etc/shorewall/orgs.local/cirrus-del-org':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0744,
        source => "puppet:///modules/shorewall/cirrus-del-org",
        require => File["/etc/shorewall/orgs.local"],
    }
