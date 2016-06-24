historical      
      
    
    file { "/tmp/hpacucli-9.30-15.0.i386.rpm":
        source => "puppet:///modules/raid/hpacucli-9.30-15.0.i386.rpm",
        notify => Exec["install-app"],
    }

    exec { "install-app":
        command => "/bin/rpm -Uvh /tmp/hpacucli-9.30-15.0.i386.rpm",
        refreshonly => true,
