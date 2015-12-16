#!/usr/bin/perl -w
#
# create_nagios_config.pl - v1.4
#
# This script creates the cloud configuration file for Nagios
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

#Imports and declarations
use strict;
use diagnostics;
use Getopt::Long;
use Sys::Syslog;

my @vps_list;
my @container_list;
my $system_anchor_domain;
my $short_domain;
my $longname;
my $network;
my $hwh_name;
my $wan_ip;

GetOptions('vps_list=s@' => \@vps_list, 'container_list=s@' => \@container_list, 'system_anchor_domain=s' => \$system_anchor_domain, 'short_domain=s' => \$short_domain, 'longname=s' => \$longname, 'network=s' => \$network, 'hardware_hostname=s' => \$hwh_name, 'wan_ip=s' => \$wan_ip) or die ("Options set incorrectly");

@vps_list = map {glob ($_)} @vps_list;
@container_list = map {glob ($_)} @container_list;
my $cfg = '';

sub container_exists{
    my $target = shift;
    #Determine if container exists
    foreach my $container (@container_list){
        if ($target eq $container){
            return 1;
        }
    }
    return 0;
}

sub add_service{
    my ($container_name, $service) = @_;
    $cfg .= <<EOF;
define service {
	use		$service
	host_name	$short_domain.$container_name
	}
EOF
}

$cfg .= <<EOF;
# Hostgroup

define hostgroup {
	hostgroup_name	$short_domain.org
	alias		$longname Organization
	}

# Hosts

define host {
	use		openvz-vps-host
	host_name	$short_domain.external
	alias		$short_domain.$system_anchor_domain
	address		$wan_ip
	parents		+$hwh_name
	hostgroups	+$short_domain.org
	}
EOF

for (my $i=0; $i<scalar @container_list; $i++){
    $cfg .= <<EOF;
define host {
	use		openvz-vps-host
	host_name	$short_domain.$container_list[$i]
	alias		$container_list[$i].$short_domain.$system_anchor_domain
	address		$network.$vps_list[$i]
	parents		+$hwh_name
	hostgroups	+$short_domain.org
	}	
EOF
}

$cfg .= <<EOF;

# Services

EOF

add_service("external", "ping-service");

for (my $i=0; $i<scalar @container_list; $i++){ 
    add_service("$container_list[$i]", "load-service");
    add_service("$container_list[$i]", "total-procs-service");
    add_service("$container_list[$i]", "zombie-procs-service");
    add_service("$container_list[$i]", "disk-service");
    add_service("$container_list[$i]", "openvz-service");
    add_service("$container_list[$i]", "ssh-service");
}

$cfg .= <<EOF;

# Custom Services

EOF

for (my $i=0; $i<scalar @container_list; $i++){
    ($container_list[$i] eq "hermes" && container_exists("hermes")) ? (add_service("$container_list[$i]", "shorewall-service")) : ();
    ($container_list[$i] eq "hermes" && container_exists("hermes")) ? (add_service("$container_list[$i]", "http-service")) : ();
    ($container_list[$i] eq "zeus" && container_exists("zeus")) ? (add_service("$container_list[$i]", "dns-service")) : ();    
    ($container_list[$i] eq "apollo" && container_exists("apollo")) ? (add_service("$container_list[$i]", "fuse-service")) : ();
    ($container_list[$i] eq "athena" && container_exists("athena")) ? (add_service("$container_list[$i]", "kerberos-service")) : ();
    ($container_list[$i] eq "aphrodite" && container_exists("aphrodite")) ? (add_service("$container_list[$i]", "ldaps-service")) : ();    
    ($container_list[$i] eq "hades" && container_exists("hades")) ? (add_service("$container_list[$i]", "mysql-service")) : ();
    ($container_list[$i] eq "hades" && container_exists("hades")) ? (add_service("$container_list[$i]", "pgsql-service")) : ();    
    ($container_list[$i] eq "hera" && container_exists("hera")) ? (add_service("$container_list[$i]", "imap-service")) : ();
    ($container_list[$i] eq "hera" && container_exists("hera")) ? (add_service("$container_list[$i]", "http-service")) : ();
    ($container_list[$i] eq "hera" && container_exists("hera")) ? (add_service("$container_list[$i]", "submission-service")) : ();
    ($container_list[$i] eq "hera" && container_exists("hera")) ? (add_service("$container_list[$i]", "sieve-service")) : ();
    ($container_list[$i] eq "poseidon" && container_exists("poseidon")) ? (add_service("$container_list[$i]", "http-service")) : ();    
    ($container_list[$i] eq "cronus" && container_exists("cronus")) ? (add_service("$container_list[$i]", "ajp-service")) : ();    
    ($container_list[$i] eq "erato" && container_exists("erato")) ? (add_service("$container_list[$i]", "jabber-service")) : ();
    ($container_list[$i] eq "trident" && container_exists("trident")) ? (add_service("$container_list[$i]", "http-service")) : ();
}

open (MYFILE1, ">/etc/nagios3/clouds/$short_domain.cfg");
print MYFILE1 "$cfg";
close (MYFILE1);
