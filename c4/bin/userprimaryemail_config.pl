#!/usr/bin/perl -w
#
# userprimaryemail_config.pl - v1.3
#
# This script handles the C3 requests for changing the users primary email
# The logs should be written to /var/log/c4/userprimaryemail_config.pl
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

use common qw(:userprimaryemail_config);

my $c4_root = abs_path( getcwd() . "/../");

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $network_name;
my @username;
my @old_email;
my @new_email;

GetOptions('network_name=s' => \$network_name, 'username=s@' => \@username, 'old_email=s@' => \@old_email, 'new_email=s@' => \@new_email) or die ("Options set incorrectly");

@username = map {glob ($_)} @username;
@old_email = map {glob ($_)} @old_email;
@new_email = map {glob ($_)} @new_email;

my %capabilities;
my @capabilities;
my @containers=('hera', 'hades', 'chaos');
my $cloud;
my %domain_config_details;
my $deployment_name = "userprimaryemail_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/UserPrimaryEmail_Config/";
my @deploy_nodes = ("username", "old_email", "new_email", "domain_config_version");
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
    if ($arg eq 'username'){
        return join(' ', @username);
    }
    elsif ($arg eq 'old_email'){
        return join(' ', @old_email);
    }
    elsif ($arg eq 'new_email'){
        return join(' ', @new_email);
    }
    elsif ($arg eq 'domain_config_version'){
	return $domain_config_details{'config_version'};
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

sub configure_database{
    mylog(" - Configuring Database");
    for (my $i=0; $i < scalar @username; $i++){
	my $update_userprimaryemail = $db_conn->prepare("UPDATE network.eseri_user SET email_prefix = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND username = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_userprimaryemail->bind_param(1, @{[split(/@/, $new_email[$i])]}[0]);
	$update_userprimaryemail->bind_param(2, $network_name);
	$update_userprimaryemail->bind_param(3, $username[$i]);
	$update_userprimaryemail->execute()                                                                                                                                         
	    or die "Couldn't execute statement: " . $update_userprimaryemail->errstr;
	$update_userprimaryemail->finish;
    }
}

sub deploy_main{
    get_domain_config_details($db_conn, $network_name, \%domain_config_details);
    generate_deployment();
    mylog(" - Performing User Primary Email Config at $network_name for Username: @username - Old Email: @old_email - New Email: @new_email");
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);
    configure_database();
    mylog(" - Done");
}
