import "*"
class ntp::client {
    package { "ntp":
        ensure => installed,
    }
 
    service { "ntp_client":
        name       => "ntp"
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        require    => Package["ntp"],
    }
}