#!/usr/bin/perl -w
# 
# A new physical server is being installed. First,
# you choose an external IP in the 243 block
#  (see http://wiki.team.virtualorgs.net/index.php/New_Server_Config)
#
# This script adds the records to the Prime DB
# then starts the installation via Cobbler.
#
# Run this script,
# then power on the new blank server. It will pxe boot from cobbler, follow the kickstart, 
# then reboot with mcollective running. 
# When this script detects mcollective is ready, it starts puppet
# to configure the new server.
#
# By blank server we mean that it is in its default BIOS state with no boot block on the disk. 
# There is a bios command that can erase and reset a server. See
#   wiki.team.virtualorgs.net/index.php/New_Server_Config
#
# 2013-04- Rick
#

use strict;
use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Sys::Syslog qw( :DEFAULT );
use DateTime;

my $conf = new Config::General("newPhysServer.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

openlog("newPhys", "", "user");

# we are expecting just one argument
if ($#ARGV != 0 ) {
    print "usage: newPhysServer.pl new_external_IP \n";
    print "   eg: newPhysServer.pl 209.87.243.86 \n";
    exit 0;
}
my $new_external_IP = $ARGV[0];

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $sql = "";
$sql = "select organization, id, hostname      "
     . "from network.server                    "
     . "where organization=5                   "
     . "and hostname ~ '^odin'                 "
     . "order by id desc                       ";

my $get_last_server = $db_conn->prepare( $sql);

$get_last_server->execute()
    or die "Couldn't execute statement: " . $get_last_server->errstr;

my ($org_id, $server_id, $server_name) = $get_last_server->fetchrow_array();

# slice first 4 chars off (remove odin) 
my $last_num =  substr $server_name, 4;

print "$last_num \n";
my $new_num =  $last_num+1;

#special case: numbering jumps from odin5 to odin74
if ( $new_num == 6) {
    $new_num =  74;
}
if ( $new_num == 200) {
    die "IP addresses exhausted in this block \n"
}

$sql = "insert into network.server (organization, hostname)  "
     . "values ('5', ?)         "
     . "returning id            ";

my $servers_insert= $db_conn->prepare( $sql);

my $new_server_name = "odin" . $new_num;
$servers_insert->bind_param(1, $new_server_name);
$servers_insert->execute()
    or die "Couldn't execute statement: " . $servers_insert->errstr;
my $hwh_id = -1;
($hwh_id) = $servers_insert->fetchrow();

print "$new_server_name  $hwh_id \n";

$sql = "insert into network.hardware_hosts                    "
     . "( id, version_available, gateway_ip, gateway_hwh,     "
     . "   max_disk_in_gib, disk_free_in_gib, max_ram_in_mib) "
     . "values (?,?,?,?,?,?,?)                                ";

my $hwh_insert= $db_conn->prepare( $sql);
#id
$hwh_insert->bind_param(1, $hwh_id);

#version
$hwh_insert->bind_param(2, 2);

#gateway_ip
my $gw_ip = "10.100.2." . $new_num . "/32";
$hwh_insert->bind_param(3, $gw_ip);

#gateway_hwh
$hwh_insert->bind_param(4, 3);

#max_disk: this is a dummy value, which will be updated after installation
$hwh_insert->bind_param(5, 500);
#free_disk: this is a dummy value, which will be updated after installation
$hwh_insert->bind_param(6, 500);
#max_ram: this is a dummy value, which will be updated after installation
$hwh_insert->bind_param(7, 96000);

$hwh_insert->execute()
    or die "Couldn't execute statement: " . $hwh_insert->errstr;
print "$new_server_name  $hwh_id \n";
# zzz config prime db IP addre here?



# at Jari, edit
#   /etc/bind/zones/external/db.virtualorgs.net
# (this might be optional, the Domain name might not be needed)



# Then, we will edit 
# /etc/puppet/manifests/nodes.pp 
# IE
#  case $::hostname {
#        'odin': { $ipaddr = "209.87.243.86" }
#  }
# and insert the IP from commandline parm 1

my $commandline = "";
#make a backup copy
$commandline = "cp /etc/puppet/manifests/nodes.pp{,.bak}" ;
`$commandline`;

#edit the IP into the file
$commandline = "sed -i[sav] -e '/$new_server_name.*ipaddr/s/209.87.243.[0-9]*/$new_external_IP/' "
    . " /etc/puppet/manifests/nodes.pp";
`$commandline`;

#start Cobbler
$commandline = "./install-server.sh  $new_server_name";
`$commandline`;

exit $?
