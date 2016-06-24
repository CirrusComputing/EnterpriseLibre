
class base {
   yumrepo { "openvz-utils":
      baseurl => "http://download.openvz.org/current/",
#     dl.iuscommunity.org/pub/ius/stable/$operatingsystem/$operatingsystemrelease/$architecture",
      descr => "OpenVZ utils repository",
      enabled => 1,
      gpgcheck => 0
   }
   yumrepo { "openvz-kernel-rhel6":
      baseurl => "http://download.openvz.org/kernel/branches/rhel6-2.6.32/current/",
#     dl.iuscommunity.org/pub/ius/stable/$operatingsystem/$operatingsystemrelease/$architecture",
      descr => "OpenVZ kernel repository",
      enabled => 1,
      gpgcheck => 0
   }
}

class openvz {
   package { "vzctl":     ensure => installed, require => Yumrepo["openvz-utils"] }
   package { "ovzkernel": ensure => installed, require => Yumrepo["openvz-kernel-rhel6"] }
}
