#!/usr/bin/perl -w
#
# timezone_config.pl - v2.1
#
# This script handles the C3 requests for changing a server/user timezone
# The logs should be written to /var/log/c4/timezone_config.log
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
use Digest::MD5 qw(md5_hex);
use Getopt::Long;

use common qw(:timezone_config);

my $c4_root = abs_path( getcwd() . "/../");

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $network_name;
my $new_timezone;
my $server_user;
my $username;

GetOptions('network_name=s' => \$network_name, 'new_timezone=s' => \$new_timezone, 'server_user=s' => \$server_user, 'username=s' => \$username) or die ("Options set incorrectly");

my %capabilities;
my @capabilities;
my %containers = (
    server => [],
    user => ['hades', 'chaos'],
    );
my %userlist;
my $deployment_name = "timezone_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = '';
my @deploy_nodes = ("new_timezone", "username");
my %password_nodes = (
    DB_PASSWORD_MYSQL => {
	mysql => 'root',	
    },
    DB_PASSWORD_POSTGRES => {
	pgsql => 'pgadmin',
    },
    );

deploy_main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'new_timezone'){
	($server_user eq 'serveruser') ? (return join(' ', @{$userlist{'timezone'}})) : (return $new_timezone);
    }
    elsif ($arg eq 'username'){
	($server_user eq 'serveruser') ? (return join(' ', @{$userlist{'username'}})) : (return $username);
    }
}

sub generate_deployment{
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;

    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    deploy_capabilities($deployment_file, 'CAPABILITY', \%capabilities);

    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }

    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub deploy_timezone_config{
    mylog(" - Performing ".$server_user." timezone configuration");
    generate_deployment();
    my $script_folder = "$c4_root/storage/Timezone_Config/deploy".ucfirst($server_user)."/";
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, $containers{$server_user});
    configure_database();
}

sub configure_database{
    mylog(" - Configuring Database");
    if ($server_user eq 'server'){
	my $update_server_timezone = $db_conn->prepare("UPDATE network.timezone_config SET timezone = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_server_timezone->bind_param(1, $new_timezone);
	$update_server_timezone->bind_param(2, $network_name);
	$update_server_timezone->execute()
	    or die "Couldn't execute statement: " . $update_server_timezone->errstr;
	$update_server_timezone->finish;
    }
    elsif ($server_user eq 'user'){
	my $update_user_timezone = $db_conn->prepare("UPDATE network.eseri_user SET timezone = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) and username = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_user_timezone->bind_param(1, $new_timezone);
	$update_user_timezone->bind_param(2, $network_name);       
	$update_user_timezone->bind_param(3, $username);       
	$update_user_timezone->execute()
	    or die "Couldn't execute statement: " . $update_user_timezone->errstr;
	$update_user_timezone->finish;
    }
}

sub configure_users{
    if ($server_user eq 'server'){
	mylog(" - Configuring timezone for all the users in the cloud.");
	$server_user = 'serveruser';
	get_userlist($db_conn, $network_name, \%userlist);
	generate_deployment();
	my $script_folder = "$c4_root/storage/Timezone_Config/deployUser/";
	run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, $containers{'user'});
    }
}

sub deploy_main{
    determine_all_containers($db_conn, $network_name, \@{$containers{'server'}});
    deploy_timezone_config();
    configure_users();
    mylog(" - Done");
}

exit 0
