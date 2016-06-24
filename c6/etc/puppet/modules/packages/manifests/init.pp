class packages {
    $base_packages = [
    "openssh-server",
    "etckeeper",
    "htop",
    "iotop",
    "iftop",
    ]
 
    $editor_packages = [
    "emacs22-nox",
    "emacs-goodies-el",
    "elscreen",
     ]
 
     $all_packages = [
     $base_packages,
     $editor_packages,
     ]
 
     package { $all_packages:
         ensure => installed,
     }
}