#!/usr/bin/perl -w
#
# cloudcapability_config.pl - v5.0
#
# This script handles the C3 requests for configuring cloud capabilities
# The logs should be written to /var/log/c4/cloudcapability_config.pl
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
use Digest::MD5 qw(md5_hex);
use Getopt::Long;

use common qw(:cloudcapability_config);

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
my @capability;
my @enable;

GetOptions('network_name=s' => \$network_name, 'capability=s@' => \@capability, 'enable=s@' => \@enable) or die ("Options set incorrectly");

@capability = map {glob ($_)} @capability;
@enable = map {glob ($_)} @enable;

my %capabilities;
my %capabilities_enabled;
my @capabilities;
my @capabilities_enabled;
my %containers = (
    Cloud => ['hera', 'poseidon', 'trident', 'chaos'],
    Drupal => ['zeus', 'hermes', 'aphrodite', 'hades', 'trident', 'chaos'],
    CiviCRM => ['zeus', 'hermes', 'hades', 'trident', 'chaos'],
    ChurchInfo => ['zeus', 'hermes', 'aphrodite', 'hades', 'trident', 'chaos'],
    Moodle => ['zeus', 'hermes', 'aphrodite', 'hades', 'trident', 'chaos'],
    OpenERP => ['zeus', 'hermes', 'aphrodite', 'hades', 'trident', 'chaos'],
    TesseractOCR => ['chaos'],
    Lector => ['chaos'],
    );
my %userlist;
my %superuser_details;
my %domain_config_details;
my $deployment_name = "cloudcapability_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = '';
my @deploy_nodes;
my %password_nodes;
my %capability_dependencies = (
    CiviCRM => ['Drupal'],
    Lector => ['TesseractOCR'],
    );

deploy_main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'system_anchor_domain'){
	return $system_anchor_domain;
    }
    elsif ($arg eq 'manager_username'){
        return $superuser_details{'username'};
    }
    elsif ($arg eq 'short_domain'){
    	return @{ [ split(/\.$system_anchor_domain/, $network_name) ]}[0];
    }
    elsif ($arg eq 'cloud_domain'){
        return $domain_config_details{'email_domain'};
    }
    elsif ($arg eq 'alias_domain'){
        return $domain_config_details{'alias_domain'};
    }    
    elsif ($arg eq 'status'){
	return join(' ', @{$userlist{'status'}});
    }
    elsif ($arg eq 'usertype'){
	return join(' ', @{$userlist{'type'}});
    }
    elsif ($arg eq 'username'){
	return join(' ', @{$userlist{'username'}});
    }
    elsif ($arg eq 'email_prefix'){
	return join(' ', @{$userlist{'email_prefix'}});
    }
    elsif ($arg eq 'firstname'){
	return join(' ', @{$userlist{'first_name'}});
    }
    elsif ($arg eq 'lastname'){
	return join(' ', @{$userlist{'last_name'}});
    }
    elsif ($arg eq 'password'){
	return join(' ', @{$userlist{'password'}});
    }
    elsif ($arg eq 'md5_password'){
	return join (' ', map {md5_hex($_)} @{$userlist{'password'}});
    }
    elsif ($arg eq 'timezone'){
	return join(' ', @{$userlist{'timezone'}});
    }
}

sub generate_deployment{
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;
    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    determine_capabilities($db_conn, $network_name, 'enabled', \%capabilities_enabled, \@capabilities_enabled);

    deploy_capabilities($deployment_file, 'CAPABILITY', \%capabilities);
    deploy_capabilities($deployment_file, 'CAPABILITY_ENABLE', \%capabilities_enabled);

    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }
    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub deploy_main{
    get_userlist($db_conn, $network_name, \%userlist);
    get_superuser_details($db_conn, $network_name, \%superuser_details);
    get_domain_config_details($db_conn, $network_name, \%domain_config_details);
    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    for (my $i=0; $i < scalar @capability; $i++){
	if ($capability[$i] eq 'Oscar' or $capability[$i] eq 'Chrome' or $capability[$i] eq 'OpenOffice'){
	    ($enable[$i] eq 't') ? (`echo "To: support\@$system_anchor_domain\nFrom: registration\@$system_anchor_domain\nSubject: $capability[$i]\n\n$capability[$i] was requested by $network_name" | ssmtp support\@$system_anchor_domain`) : ();
	}
	else{
	    ($enable[$i] eq 't') ? (install_capability($capability[$i])) : ();
	}

	# Lastly, add dependencies to initial request params, so that dependencies are also enabled/disable along with the actual capabilities.
	for (my $j=0; $j<(($capability_dependencies{$capability[$i]}) ? (scalar @{$capability_dependencies{$capability[$i]}}) : (0)); $j++){
	    push @capability, $capability_dependencies{$capability[$i]}[$j];
	    push @enable, $enable[$i];
	}
    }
    deploy_cloudcapability_config();
    firewallproxy_config();
}

sub deploy_cloudcapability_config{
    configure_database();
    generate_deployment();
    $script_folder = "$c4_root/storage/CloudCapability_Config/deployCloud";
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, $containers{'Cloud'});
    configure_user_menu();
}

sub firewallproxy_config{
    mylog(" -- Performing firewallproxy_config");
    my @fpc_capability;
    my @fpc_external_name;
    my @fpc_ssl;
    my $get_firewallproxy_config_values = $db_conn->prepare("SELECT a.name, b.external_name, b.ssl FROM packages.capabilities AS a, packages.organizationcapabilities AS b WHERE b.organization = (SELECT id FROM network.organization WHERE network_name = ?) AND a.capid = b.capability AND a.external_access='t' AND b.enabled='t' and b.external_access='t' ORDER BY a.capid")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_firewallproxy_config_values->bind_param(1, lc($network_name));
    $get_firewallproxy_config_values->execute()
	or die "Couldn't execute statement: " . $get_firewallproxy_config_values->errstr;
    while( my $result = $get_firewallproxy_config_values->fetchrow_hashref) {
	push (@fpc_capability, $result->{'name'});
	push (@fpc_external_name, $result->{'external_name'});
	push (@fpc_ssl, $result->{'ssl'});
    }
    `./firewallproxy_config.pl --network_name "$network_name" --capability "@fpc_capability" --external_name "@fpc_external_name" --ssl "@fpc_ssl" >&2`;
    if ($? != 0){
	mylog(" -- Failed to perform firewallproxy_config");
	exit 1;
    }	
}

sub install_capability{
    my ($cap) = @_;
    if (! has_capability($cap, \@capabilities)){	
	for (my $i=0; $i<(($capability_dependencies{$cap}) ? (scalar @{$capability_dependencies{$cap}}) : (0)); $i++){
	    install_capability($capability_dependencies{$cap}[$i]);
	}
	get_deployment_xml('cloudcapability_config/'.$cap.'.xml', \%password_nodes, \@deploy_nodes);
	generate_deployment();
	$script_folder = "$c4_root/storage/CloudCapability_Config/deploy".$cap;
	run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, $containers{$cap});
	configure_database($cap);
	determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    }
}

sub configure_user_menu{
    mylog(" - Configuring user menu");
    my $applications_menu_filename='/tmp/applications.menu';
    my $settings_menu_filename='/tmp/settings.menu';
    my $c3address='c3.'.$system_anchor_domain;
    my $short_name='chaos';
    ssh("$c3address", "/home/c3/bin/create_menu.pl --capabilities_enabled '@capabilities_enabled' --applications_menu_filename '$applications_menu_filename' --settings_menu_filename '$settings_menu_filename'");
    scp($applications_menu_filename,"root\@$short_name.$network_name:$applications_menu_filename");
    scp($settings_menu_filename,"root\@$short_name.$network_name:$settings_menu_filename");
    ssh("$short_name.$network_name", "for dir1 in /home/*; do cp $applications_menu_filename $settings_menu_filename ".'\$'."dir1/.config/menus; done; rm -f $applications_menu_filename $settings_menu_filename");
}

sub configure_database{
    my ($cap) = @_;
    $cap //= '';
    mylog(" - Configuring Database");
    mylog(" -- Updating Capabilities Info");
    if ($cap eq ''){
	for (my $i=0; $i < scalar @capability; $i++){
	    my $update_cloudcapability = $db_conn->prepare("UPDATE packages.organizationcapabilities SET enabled = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND capability = (SELECT capid FROM packages.capabilities WHERE name = ?)")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	    $update_cloudcapability->bind_param(1, $enable[$i], PG_BOOL);
	    $update_cloudcapability->bind_param(2, $network_name);
	    $update_cloudcapability->bind_param(3, $capability[$i]);
	    $update_cloudcapability->execute()
	    or die "Couldn't execute statement: " . $update_cloudcapability->errstr;
	    $update_cloudcapability->finish;
	}
    }
    else {
	my $insert_cloudcapability = $db_conn->prepare("INSERT INTO packages.organizationcapabilities (organization, capability, enabled, external_name) SELECT A.id, B.capid, 't', (CASE WHEN B.external_access='t' THEN LOWER(B.name) ELSE '' END) FROM network.organization A, packages.capabilities B WHERE A.network_name = ? AND B.name = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$insert_cloudcapability->bind_param(1, $network_name);
	$insert_cloudcapability->bind_param(2, $cap);
	$insert_cloudcapability->execute()
	    or die "Couldn't execute statement: " . $insert_cloudcapability->errstr;
	$insert_cloudcapability->finish;
    }
}
