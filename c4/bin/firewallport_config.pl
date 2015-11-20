#!/usr/bin/perl -w
#
# firewallport_config.pl - v1.0
#
# This script handles the C3 requests for opening the firewall port in order for Syncthing to connect (for now).
# The logs should be written to /var/log/c4/firewallport_config.pl
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

use strict;

use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Cwd;
use Cwd 'abs_path';
use XML::LibXML;
use Getopt::Long;

use common qw(:firewallport_config);

my $c4_root = abs_path( getcwd() . "/../");

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $network_name;
my $username;
my $port;

GetOptions('network_name=s' => \$network_name, 'username=s' => \$username, 'port=s' => \$port) or die ("Options set incorrectly");

my @containers=('hermes');
my $deployment_name = "firewallport_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/FirewallPort_Config/";
my @deploy_nodes = ("username", "port");
my %password_nodes = ();

deploy_main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'username'){
	return $username;
    }
    elsif ($arg eq 'port'){
	return $port;
    }
}

sub generate_deployment{
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;
    
    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }

    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub deploy_main{
    generate_deployment();
    mylog(" - Performing Firewall Port Config at $network_name - Username: $username - Port: $port");
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);
}

exit 0
