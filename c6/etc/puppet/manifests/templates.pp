

node default {
   include base
   include ssh_setup
   include sbin_setup
   include volume_group_setup 
   include etc_setup
   include ubuntu_setup 
}
