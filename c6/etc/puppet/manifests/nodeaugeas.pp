    augeas{ "yum excludes" :
        context => "/files/etc/yum.conf",
        changes => [
            "set dir[. = 'exclude=kernel*'] exclude=kernel*",
        ],
    }

# adds a line:
#onlyif => "match dir[. = 'exclude'] size == 0",
#     "set dir[last()+1] 'exclude=kernel*'",

#service { "sshd":    ensure    => running,    require   => Package[ opennssh-server ],
#    subscribe => File[sshdconfig],
#    subscribe => File[sshdauth],}
#        require => Package["rpmforge-release"],
  
