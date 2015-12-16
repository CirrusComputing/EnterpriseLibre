#!/usr/bin/perl -w
#
# domain_config.pl - v2.8
#
# This script handles the C3 requests for changing an organization email_domain.
# Depending on the config version, the script configures an organization.
# The logs should be written to /var/log/c4/domain_config.log
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

use MIME::Lite::TT::HTML;
use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use XML::LibXML;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;

use common qw(:domain_config);

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
my $new_config_version;
my $new_email_domain;
my $new_imap_server;
my $new_alias_domain;
my $new_website_ip;

GetOptions('network_name=s' => \$network_name, 'new_config_version=s' => \$new_config_version, 'new_email_domain=s' => \$new_email_domain, 'new_imap_server=s' => \$new_imap_server, 'new_alias_domain=s' => \$new_alias_domain, 'new_website_ip=s' => \$new_website_ip) or die ("Options set incorrectly");

my %capabilities;
my @capabilities;
my @containers=('smc-zeus', 'smc-hermes', 'smc-hera', 'zeus', 'hermes', 'hera', 'hades', 'poseidon', 'trident', 'gaia', 'chaos');
my %userlist;
my %domain_config_details;
my $deployment_name = "domain_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/Domain_Config/";
my @deploy_nodes = ("system_anchor_domain", "short_domain", "new_config_version", "old_email_domain", "old_imap_server", "old_alias_domain", "old_website_ip", "new_email_domain", "new_imap_server", "new_alias_domain", "new_website_ip", "username", "email_prefix", "password");
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
    if ($arg eq 'system_anchor_domain'){
	return $system_anchor_domain;
    }
    elsif ($arg eq 'short_domain'){
	return @{ [ split(/\.$system_anchor_domain/, $network_name) ]}[0];
    }
    elsif ($arg eq 'new_config_version'){
	($new_config_version eq '1.1') ? (return $domain_config_details{'config_version'}.'to1.1') : (return $new_config_version);
    }
    elsif ($arg eq 'old_email_domain'){
        return $domain_config_details{'email_domain'};
    }
    elsif ($arg eq 'old_imap_server'){
        return $domain_config_details{'imap_server'};
    }
    elsif ($arg eq 'old_alias_domain'){
        return $domain_config_details{'alias_domain'};
    }
    elsif ($arg eq 'old_website_ip'){
        return $domain_config_details{'website_ip'};
    }
    elsif ($arg eq 'new_email_domain'){
	return $new_email_domain;
    }
    elsif ($arg eq 'new_imap_server'){
	return $new_imap_server;
    }
    elsif ($arg eq 'new_alias_domain'){
	return $new_alias_domain;
    }
    elsif ($arg eq 'new_website_ip'){
	return $new_website_ip;
    }
    elsif ($arg eq 'username'){
	return join(' ', @{$userlist{'username'}});
    }
    elsif ($arg eq 'email_prefix'){
	return join(' ', @{$userlist{'email_prefix'}});
    }
    elsif ($arg eq 'password'){
	return join(' ', @{$userlist{'password'}});
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

sub userprimaryemail_config{
    mylog(" -- Performing userprimaryemail_config");
    my @username = @{$userlist{'username'}};
    my @old_email = join('@'.$domain_config_details{'email_domain'}.' ', @{$userlist{'email_prefix'}}) . '@'.$domain_config_details{'email_domain'};
    my @new_email = join('@'.$new_email_domain.' ', @{$userlist{'email_prefix'}}) . '@'.$new_email_domain;
    `./userprimaryemail_config.pl --network_name "$network_name" --username "@username" --old_email "@old_email" --new_email "@new_email" >&2`;
    if ($? != 0){
	mylog(" -- Failed to perform userprimaryemail_config");
	exit 1;
    }	
}

sub configure_database{
	my $update_domain_config = $db_conn->prepare("UPDATE network.domain_config set config_version = ?, email_domain = ?, imap_server = ?, alias_domain = ?, website_ip = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_domain_config->bind_param(1, $new_config_version);
	$update_domain_config->bind_param(2, $new_email_domain);
	$update_domain_config->bind_param(3, $new_imap_server);
	$update_domain_config->bind_param(4, $new_alias_domain);
	$update_domain_config->bind_param(5, $new_website_ip);
	$update_domain_config->bind_param(6, $network_name);
	$update_domain_config->execute()
	    or die "Couldn't execute statement: " . $update_domain_config->errstr;
	
	my $update_network_organization = $db_conn->prepare("UPDATE network.organization set email_domain = ? WHERE network_name = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_network_organization->bind_param(1, $new_email_domain);
	$update_network_organization->bind_param(2, $network_name);
	$update_network_organization->execute()
	    or die "Couldn't execute statement: " . $update_network_organization->errstr;
}

sub deploy_domain_config{
    mylog(" - Performing Domain Config at $network_name - $domain_config_details{'config_version'} => $new_config_version, $domain_config_details{'email_domain'} => $new_email_domain, $domain_config_details{'imap_server'} => $new_imap_server, $domain_config_details{'alias_domain'} => $new_alias_domain, $domain_config_details{'website_ip'} => $new_website_ip");
    get_userlist($db_conn, $network_name, \%userlist);
    generate_deployment();
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);
    userprimaryemail_config();
    configure_database();
}

sub deploy_main{
    my $temp_new_config_version = $new_config_version;
    my $temp_new_email_domain = $new_email_domain;
    my $temp_new_imap_server = $new_imap_server;
    my $temp_new_alias_domain = $new_alias_domain;
    my $temp_website_ip = $new_website_ip;
    get_domain_config_details($db_conn, $network_name, \%domain_config_details);
    if ($domain_config_details{'config_version'} ne '1.1'){
	$new_config_version = '1.1';
	$new_email_domain = $network_name;
	$new_imap_server = 'imap.'.$network_name;
	$new_alias_domain = $network_name;
	$new_website_ip = '0.0.0.0';
	deploy_domain_config();
	get_domain_config_details($db_conn, $network_name, \%domain_config_details);
    }
    $new_config_version = $temp_new_config_version;
    $new_email_domain = $temp_new_email_domain;
    $new_imap_server = $temp_new_imap_server;
    $new_alias_domain = $temp_new_alias_domain;
    $new_website_ip = $temp_website_ip;
    if ($new_config_version ne '1.1'){
	deploy_domain_config();
    }
    mylog("- Done");
}

exit 0
