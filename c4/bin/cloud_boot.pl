#!/usr/bin/perl -w
#
# cloud_boot.pl - v2.7
#
# This script handles the C3 requests for starting/stopping/rebooting all containers of a cloud
# The logs should be written to /var/log/c4/cloud_boot.log
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
use POSIX qw(floor);
use Getopt::Long;
use Data::Dumper::Simple;
# To get rid of the newline that Dumper prints.
$Data::Dumper::Indent = 0;

use common qw(:cloud_boot);

my $c4_root = abs_path( getcwd() . "/../");

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain($db_conn);

my $network_name;
my $boot_action;

GetOptions('network_name=s' => \$network_name, 'boot_action=s' => \$boot_action) or die ("Options set incorrectly");

mylog("-- ".Dumper($network_name)) && check_value($network_name);
mylog("-- ".Dumper($boot_action)) && check_value($boot_action);

my $cloud_boot;
my $hwh_short_name;
my $veid_base;
my $short_domain;
my $alias_domain;
my $cloud_status;
my $prime_dns="dns.$system_anchor_domain";
my $dns_config_folder="/etc/bind";
my @dns_servers=('dns');
my $nagios="nagios.$system_anchor_domain";
my $nagios_config_folder="/etc/nagios3";
my $amanda_backup_server = "nanook.$system_anchor_domain";
my $amanda_backup_pids = "";
my $amanda_backup_config = "DailySet";

my %capabilities;
my @capabilities;
my @containers;
my @vps_list;
my $deployment_name = "cloud_boot-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/Reboot_Create/";
my @deploy_nodes;
my %password_nodes;

deploy_main();

sub check_value{
    my ($arg) = @_;
    unless($arg){
        mylog("ERROR: One of the values is NULL.");
	exit(1);
    }
}

sub get_cloud_boot_details{
    mylog("- Gettting information from database.");

    # Get Cloud's Current Status
    my $get_cloud_status = $db_conn->prepare("SELECT status FROM network.organization WHERE network_name = ?")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_status->bind_param(1, $network_name);
    $get_cloud_status->execute()
        or die "Couldn't execute statement: " . $get_cloud_status->errstr;
    ($cloud_status) = $get_cloud_status->fetchrow_array();
    $get_cloud_status->finish;

    # Get Hardware host short name and Cloud's veid base.
    my $get_cloud_boot_details = $db_conn->prepare("SELECT a.hostname, FLOOR(b.veid/100)*100 AS veid_base FROM network.server AS a, network.server AS b WHERE b.organization = (SELECT id FROM network.organization WHERE network_name = ?) AND b.hardware_host = a.id GROUP BY a.hostname, veid_base")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_boot_details->bind_param(1, $network_name);
    $get_cloud_boot_details->execute()
        or die "Couldn't execute statement: " . $get_cloud_boot_details->errstr;
    ($hwh_short_name, $veid_base) = $get_cloud_boot_details->fetchrow_array();
    $get_cloud_boot_details->finish;

    # Get Cloud's Alias Domain
    my $get_cloud_alias_domain = $db_conn->prepare("SELECT alias_domain FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_alias_domain->bind_param(1, $network_name);
    $get_cloud_alias_domain->execute()
        or die "Couldn't execute statement: " . $get_cloud_alias_domain->errstr;
    ($alias_domain) = $get_cloud_alias_domain->fetchrow_array();
    $get_cloud_alias_domain->finish;

    # Cloud's VPS List
    my $get_cloud_vps_list = $db_conn->prepare("SELECT (veid-FLOOR(veid/100)*100) FROM network.server WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY veid")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_vps_list->bind_param(1, $network_name);
    $get_cloud_vps_list->execute()
        or die "Couldn't execute statement: " . $get_cloud_vps_list->errstr;

    while (my $vps = $get_cloud_vps_list->fetchrow()){
        push(@vps_list, $vps);
    }
    $get_cloud_vps_list->finish;

    ($short_domain = $network_name) =~ s/.$system_anchor_domain//;
 
    mylog("-- ".Dumper($hwh_short_name)) && check_value($hwh_short_name);
    mylog("-- ".Dumper($veid_base)) && check_value($veid_base);
    mylog("-- ".Dumper($cloud_status)) && check_value($cloud_status);
    mylog("-- ".Dumper($alias_domain)) && check_value($alias_domain);
    mylog("-- ".Dumper(@vps_list)) && check_value(@vps_list);
    mylog("-- ".Dumper($short_domain)) && check_value($short_domain);
}

sub check_boot{
    # Check if cloud is already suspended/resumed.
    mylog("- Cloud status is $cloud_status");
    if ($cloud_status eq 'ACTIVE' && $boot_action eq 'resume'){
	mylog("- No need to resume since cloud is already resumed.");
	exit(0);
    }
    elsif ($cloud_status eq 'SUSPENDED' && $boot_action eq 'suspend'){
	mylog("- No need to suspend since cloud is already suspended.");
	exit(0);
    }
}

sub configure_nagios{
    # Configure nagios only if boot_action is suspend or resume.
    # Here we move the nagios configuration file at maui to <name>.cfg.suspend
    mylog("- Configuring Nagios");
    if ($boot_action eq 'suspend'){
	ssh("$nagios", "mv $nagios_config_folder/organizations/$short_domain\.cfg $nagios_config_folder/organizations/$short_domain\.cfg\.suspend");
	ssh("$nagios", "rm -f /etc/nagios3/conf.d/ngraph/serviceext/$short_domain\_*\.cfg");
	ssh("$nagios", "/etc/init.d/nagios3 reload");
    }
    elsif ($boot_action eq 'resume'){
	ssh("$nagios", "mv $nagios_config_folder/organizations/$short_domain\.cfg\.suspend $nagios_config_folder/organizations/$short_domain\.cfg");
	ssh("$nagios", "/etc/init.d/nagios3 reload");
    }
}    

sub configure_dns{
    # Configure dns only if boot_action is suspend or resume.
    # Here we make sure that the internal and external zones files for the cloud are not included at the prime dns server. Otherwise the prime dns server keeps trying to transfer the cloud db files and fails, because the cloud containers have been stopped.
    mylog("- Configuring DNS");
    if ($boot_action eq 'suspend'){
	foreach my $dns_server (@dns_servers) {
	    my $full_hostname = "$dns_server.$system_anchor_domain";
	    if ($dns_server eq 'dns'){
		ssh("$full_hostname", "sed -i '/^include.*\\\/$network_name.conf/s|include|\\\/\\\/include|' $dns_config_folder/named.conf.internal.customerzones");
		if($network_name ne $alias_domain){
		    ssh("$full_hostname", "sed -i '/^include.*\\\/$alias_domain.conf/s|include|\\\/\\\/include|' $dns_config_folder/named.conf.internal.customerzones");
		}
	    }
	    ssh("$full_hostname", "/etc/init.d/bind9 reload;");
	}
    }
    elsif ($boot_action eq 'resume'){
	foreach my $dns_server (@dns_servers) {
	    my $full_hostname = "$dns_server.$system_anchor_domain";
	    if ($dns_server eq 'dns'){
		ssh("$full_hostname", "sed -i '/^\\\/\\\/include.*\\\/$network_name.conf/s|\\\/\\\/include|include|' $dns_config_folder/named.conf.internal.customerzones");
		if($network_name ne $alias_domain){
		    ssh("$full_hostname", "sed -i '/^\\\/\\\/include.*\\\/$alias_domain.conf/s|\\\/\\\/include|include|' $dns_config_folder/named.conf.internal.customerzones");
		}
	    }
	    ssh("$full_hostname", "/etc/init.d/bind9 reload;");
	}	
    }
}

sub configure_database{
    mylog("- Configuring Database");
    my $update_cloud_boot = $db_conn->prepare("UPDATE network.organization SET status = ? WHERE network_name = ?")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    ($boot_action eq 'suspend') ? ($update_cloud_boot->bind_param(1, 'SUSPENDED')) : ($update_cloud_boot->bind_param(1, 'ACTIVE'));
    $update_cloud_boot->bind_param(2, $network_name);
    $update_cloud_boot->execute()
	or die "Couldn't execute statement: " . $update_cloud_boot->errstr;
    $update_cloud_boot->finish;
}

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'veid_base'){
	return $veid_base;
    }
    elsif ($arg eq 'boot_action'){
	return $boot_action;
    }
    elsif ($arg eq 'vps_list'){
	return join(' ', @vps_list);
    }
}

sub generate_deployment{
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;
    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    deploy_capabilities($deployment_file, 'CAPABILITY', \%capabilities);
    get_deployment_xml('task_config/Reboot.xml', \%password_nodes, \@deploy_nodes);
    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }
    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub deploy_main{
    mylog(" - Performing Cloud Boot for $network_name with option $boot_action\.");
    get_cloud_boot_details();
    check_boot();
    push(@containers, $hwh_short_name);

    # For cloud suspend, do nagios and dns configurations before stopping VPS. So that dns doesn't keep trying to transfer zone from cloud dns when it's stopped, and nagios doesn't send us emails saying cloud containers are down.
    if ($boot_action eq 'suspend'){
	configure_nagios();
	configure_dns();
    }

    generate_deployment();
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);

    # For cloud resume, do nagios and dns configurations in the same manner as for active cloud.
    if ($boot_action eq 'resume'){
	configure_nagios();
	configure_dns();
    }

    configure_database();
}
