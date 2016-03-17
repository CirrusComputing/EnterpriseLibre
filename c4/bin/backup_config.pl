#!/usr/bin/perl -w
#
# backup_config.pl - v1.2
#
# This script handles the C3 requests for configuring backup for a cloud.
# The logs should be written to /var/log/backup_config.log
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

use strict;

use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Cwd;
use Cwd 'abs_path';
use XML::LibXML;
use Getopt::Long;
use Data::Dumper::Simple;
# To get rid of the newline that Dumper prints.
$Data::Dumper::Indent = 0;

use common qw(:backup_config);

my $c4_root = abs_path( getcwd() . "/../");

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $network_name;
my $option;
my $profile_id;
my $name;
my $frequency_number;
my $frequency_duration;
my $time;
my $target_url;
my $enabled;
my $snapshot;

GetOptions('network_name=s' => \$network_name, 'option=s' => \$option, 'profile_id=s' => \$profile_id, 'name=s' => \$name, 'frequency_number=s' => \$frequency_number, 'frequency_duration=s' => \$frequency_duration, 'time=s' => \$time, 'target_url=s' => \$target_url, 'enabled=s' => \$enabled, 'snapshot=s' => \$snapshot) or die ("Options set incorrectly");

mylog("-- ".Dumper($network_name)) && check_value($network_name);
mylog("-- ".Dumper($option)) && check_value($option);
mylog("-- ".Dumper($profile_id)) && check_value($profile_id);
mylog("-- ".Dumper($name)) && check_value($name);
mylog("-- ".Dumper($frequency_number)) && check_value($frequency_number);
mylog("-- ".Dumper($frequency_duration)) && check_value($frequency_duration);
mylog("-- ".Dumper($time)) && check_value($time);
mylog("-- ".Dumper($target_url)) && check_value($target_url);
mylog("-- ".Dumper($enabled)) && check_value($enabled);
mylog("-- ".Dumper($snapshot)) && check_value($snapshot);

my $system_anchor_domain=get_system_anchor_domain($db_conn);
my $backup_server = "storage.$system_anchor_domain";
my $profile;
my $next_profile_id;

my %capabilities;
my @capabilities;
my @containers=('apollo');
my @vps_list;
my $deployment_name = "backup_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/Backup_Config/";
my @deploy_nodes = ("option", "profile", "frequency_number", "frequency_duration", "time", "target_url", "enabled", "snapshot");
my %password_nodes;

deploy_main();

sub check_value{
    my ($arg) = @_;
    unless($arg){
        mylog("ERROR: One of the values is NULL.");
	exit(1);
    }
}

sub get_backup_config_details{
    mylog("- Getting required details");
    if ($option eq 'add'){
	# Get next profile id.
	my $get_next_profile_id = $db_conn->prepare("SELECT MAX(profile_id+1) FROM network.backup_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$get_next_profile_id->bind_param(1, $network_name);
	$get_next_profile_id->execute()
	    or die "Couldn't execute statement: " . $get_next_profile_id->errstr;
	($next_profile_id) = $get_next_profile_id->fetchrow_array();
	$get_next_profile_id->finish;

	$profile = "profile".$next_profile_id;	
    }
    else{
	$profile = "profile".$profile_id;
    }
}

sub configure_database{
    mylog("- Configuring Database");
    if ($option eq 'add'){
	my $insert_backup_config = $db_conn->prepare("INSERT INTO network.backup_config (organization, profile_id, name, frequency, time, target_url, enabled) VALUES ((SELECT id FROM network.organization WHERE network_name = ?), ?, ?, ?, ?, ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$insert_backup_config->bind_param(1, $network_name);
	$insert_backup_config->bind_param(2, $next_profile_id, SQL_INTEGER);
	$insert_backup_config->bind_param(3, $name);
	$insert_backup_config->bind_param(4, "$frequency_number $frequency_duration");
	$insert_backup_config->bind_param(5, $time);
	$insert_backup_config->bind_param(6, $target_url);
	$insert_backup_config->bind_param(7, $enabled, PG_BOOL);
	$insert_backup_config->execute()
	    or die "Couldn't execute statement: " . $insert_backup_config->errstr;
	$insert_backup_config->finish;
    }
    elsif ($option eq 'edit'){
	my $update_backup_config = $db_conn->prepare("UPDATE network.backup_config SET (name, frequency, time, enabled) = (?, ?, ?, ?) WHERE profile_id = ? AND organization = (SELECT id from network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_backup_config->bind_param(1, $name);
	$update_backup_config->bind_param(2, "$frequency_number $frequency_duration");
	$update_backup_config->bind_param(3, $time);
	$update_backup_config->bind_param(4, $enabled, PG_BOOL);
	$update_backup_config->bind_param(5, $profile_id);
	$update_backup_config->bind_param(6, $network_name);
	$update_backup_config->execute()
	    or die "Couldn't execute statement: " . $update_backup_config->errstr;
	$update_backup_config->finish;
    }
    elsif ($option eq 'delete'){
	my $delete_backup_config = $db_conn->prepare("DELETE FROM network.backup_config WHERE profile_id = ? and organization = (SELECT id from network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$delete_backup_config->bind_param(1, $profile_id);
	$delete_backup_config->bind_param(2, $network_name);
	$delete_backup_config->execute()
	    or die "Couldn't execute statement: " . $delete_backup_config->errstr;
	$delete_backup_config->finish;
    }
}

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'option'){
	return $option;
    }
    elsif ($arg eq 'profile'){
	return $profile;
    }
    elsif ($arg eq 'frequency_number'){
	return $frequency_number;
    }
    elsif ($arg eq 'frequency_duration'){
	return $frequency_duration;
    }
    elsif ($arg eq 'time'){
	return $time;
    }
    elsif ($arg eq 'target_url'){
	return $target_url;
    }
    elsif ($arg eq 'enabled'){
	return $enabled;
    }
    elsif ($arg eq 'snapshot'){
	return $snapshot;
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

sub deploy_main{
    mylog(" - Performing Backup Config for $network_name with option $option\.");
    get_backup_config_details();
    generate_deployment();
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);
    configure_database();
}
