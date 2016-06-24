#!/usr/bin/perl -w
my $new_server_name = "odin75";
my $new_num = "75";


my $commandline = "";
#make a backup copy
$commandline = "cp /etc/puppet/manifests/nodes.pp{,.bak}" ;
`$commandline`;

#edit the IP into the file
$commandline = "sed -i -e '/$new_server_name.*ipaddr/s/209.87.243.[0-9]*/209.87.243.$new_num/' "
    . " /etc/puppet/manifests/nodes.pp";
`$commandline`;
