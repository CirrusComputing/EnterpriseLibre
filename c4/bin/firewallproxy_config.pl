#!/usr/bin/perl -w
#
# firewallproxy_config.pl - v1.6
#
# This script handles the C3 requests for changing the firewall and proxy config.
# The logs should be written to /var/log/c4/firewallproxy_config.log
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

use common qw(:firewallproxy_config);

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
my @external_name;
my @ssl;

GetOptions('network_name=s' => \$network_name, 'capability=s@' => \@capability, 'external_name=s@' => \@external_name, 'ssl=s@' => \@ssl) or die ("Options set incorrectly");

@capability = map {glob ($_)} @capability;
@external_name = map {glob ($_)} @external_name;
@ssl = map {glob ($_)} @ssl;

my @containers=('zeus', 'hermes', 'hades');
my %domain_config_details;
my $deployment_name = "firewallproxy_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/FirewallProxy_Config/";
my @deploy_nodes = ("capability", "external_name", "ssl", "alias_domain");
my %password_nodes = (
    DB_PASSWORD_MYSQL => {
	mysql => 'root',	
    },
    DB_PASSWORD_POSTGRES => {
	pgsql => 'pgadmin',
    },
    );
my $short_domain = @{ [ split(/\.$system_anchor_domain/, $network_name) ]}[0];
my $cloud_wan_ip;
my $system_anchor_ip;
my $sites_available_folder = '/etc/apache2/sites-available';
my $sites_enabled_folder = '/etc/apache2/sites-enabled';

deploy_main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'capability'){
	return join(' ', @capability);
    }
    elsif ($arg eq 'external_name'){
	return join(' ', @external_name);
    }
    elsif ($arg eq 'ssl'){
	return join(' ', @ssl);
    }
    elsif ($arg eq 'alias_domain'){
	return $domain_config_details{'alias_domain'};
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

sub configure_smc_proxy{
    mylog(" - Configure SMC proxy");

    # Get System Anchor IP.
    my $get_system_anchor_ip = $db_conn->prepare("SELECT address FROM network.address_pool WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_system_anchor_ip->bind_param(1, $system_anchor_domain);
    $get_system_anchor_ip->execute()  
	or die "Couldn't execute statement: " . $get_system_anchor_ip->errstr;
    ($system_anchor_ip) = $get_system_anchor_ip->fetchrow_array();
    $get_system_anchor_ip->finish;

    # Get Cloud Wan IP.
    my $get_cloud_wan_ip = $db_conn->prepare("SELECT address FROM network.address_pool WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_wan_ip->bind_param(1, $network_name);
    $get_cloud_wan_ip->execute()
	or die "Couldn't execute statement: " . $get_cloud_wan_ip->errstr;
    ($cloud_wan_ip) = $get_cloud_wan_ip->fetchrow_array();
    $get_cloud_wan_ip->finish;

    #Get list of Enabled sites.
    my @enabled_sites = ssh("hermes.$network_name", "find $sites_enabled_folder/* ! -name '000-default' ! -name 'default-ssl' -printf '%f '");
    mylog("Enabled sites - @enabled_sites");
    @enabled_sites = map {glob ($_)} @enabled_sites;

    # Remove old sites.
    ssh("smc-hermes.$system_anchor_domain", "rm -f $sites_available_folder/custom-$short_domain-*");

    # Copy Certificate and Private key.
    `mkdir -p $deployment_file`;
    scp("root\@hermes.$network_name:/etc/ssl/certs/ssl.$network_name.pem", "$deployment_file/ssl.$network_name.pem_cert");
    scp("root\@hermes.$network_name:/etc/ssl/private/ssl.$network_name.pem", "$deployment_file/ssl.$network_name.pem_key");
    scp("$deployment_file/ssl.$network_name.pem_cert", "root\@smc-hermes.$system_anchor_domain:/etc/ssl/certs/ssl.$network_name.pem");
    scp("$deployment_file/ssl.$network_name.pem_key", "root\@smc-hermes.$system_anchor_domain:/etc/ssl/private/ssl.$network_name.pem");
    ssh("smc-hermes.$system_anchor_domain", "chown root:ssl-cert /etc/ssl/private/ssl.$network_name.pem");

    # Copy Apache2 sites.
    foreach my $enabled_site (@enabled_sites){
	print "$enabled_site\n";
	my $proxy_site = "custom-$short_domain-$enabled_site";
	scp("root\@hermes.$network_name:/$sites_enabled_folder/$enabled_site", "$deployment_file/$proxy_site");
	scp("$deployment_file/$proxy_site", "root\@smc-hermes.$system_anchor_domain:/$sites_available_folder/$proxy_site");
	ssh("smc-hermes.$system_anchor_domain", "sed -i 's|$cloud_wan_ip|$system_anchor_ip|' $sites_available_folder/$proxy_site");
	ssh("smc-hermes.$system_anchor_domain", "a2ensite $proxy_site");
    }

    # Reload Apache2 process.
    ssh("smc-hermes.$system_anchor_domain", "/etc/init.d/apache2 reload");
    `rm -rf $deployment_file`;    
}

sub configure_database{
    mylog(" - Configuring Database");
    my $disable_organizationcapabilities_external = $db_conn->prepare("UPDATE packages.organizationcapabilities SET external_access = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $disable_organizationcapabilities_external->bind_param(1, "f", PG_BOOL);
    $disable_organizationcapabilities_external->bind_param(2, $network_name);
    $disable_organizationcapabilities_external->execute()                                                                                                                                         
	or die "Couldn't execute statement: " . $disable_organizationcapabilities_external->errstr;
    $disable_organizationcapabilities_external->finish;
    
    for (my $i=0; $i < scalar @capability; $i++){
	my $update_organizationcapabilities_external = $db_conn->prepare("UPDATE packages.organizationcapabilities SET external_name = ?, external_access = ? , ssl = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND capability = (SELECT capid FROM packages.capabilities WHERE name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_organizationcapabilities_external->bind_param(1, $external_name[$i]);
	$update_organizationcapabilities_external->bind_param(2, "t", PG_BOOL);
	$update_organizationcapabilities_external->bind_param(3, $ssl[$i], PG_BOOL);
	$update_organizationcapabilities_external->bind_param(4, $network_name);
	$update_organizationcapabilities_external->bind_param(5, $capability[$i]);
	$update_organizationcapabilities_external->execute()                                                                                                                                         
	    or die "Couldn't execute statement: " . $update_organizationcapabilities_external->errstr;
	$update_organizationcapabilities_external->finish;
    }
}

sub deploy_main{
    get_domain_config_details($db_conn, $network_name, \%domain_config_details);
    generate_deployment();
    mylog(" - Performing Firewall Proxy Config at $network_name - Capability: @capability - External name: @external_name");
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);    
    configure_smc_proxy();
    configure_database();
}

exit 0
