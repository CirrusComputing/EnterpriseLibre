#!/usr/bin/perl -w
#
# userfullname_config.pl - v1.1
#
# This script handles the C3 requests for changing the users fullname
# The logs should be written to /var/log/c4/userfullname_config.pl
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

use common qw(:userfullname_config);

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
my @old_firstname;
my @old_lastname;
my @new_firstname;
my @new_lastname;

GetOptions('network_name=s' => \$network_name, 'username=s@' => \@username, 'old_firstname=s@' => \@old_firstname, 'old_lastname=s@' => \@old_lastname, 'new_firstname=s@' => \@new_firstname, 'new_lastname=s@' => \@new_lastname) or die ("Options set incorrectly");

@username = map {glob ($_)} @username;
@old_firstname = map {glob ($_)} @old_firstname;
@old_lastname = map {glob ($_)} @old_lastname;
@new_firstname = map {glob ($_)} @new_firstname;
@new_lastname = map {glob ($_)} @new_lastname;

my %capabilities;
my @capabilities;
my @containers=('hades', 'chaos');
my $deployment_name = "userfullname_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/UserFullname_Config/";
my @deploy_nodes = ("username", "old_firstname", "old_lastname", "new_firstname", "new_lastname");
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
    elsif ($arg eq 'old_firstname'){
        return join(' ', @old_firstname);
    }
    elsif ($arg eq 'old_lastname'){
        return join(' ', @old_lastname);
    }
    elsif ($arg eq 'new_firstname'){
        return join(' ', @new_firstname);
    }
    elsif ($arg eq 'new_lastname'){
        return join(' ', @new_lastname);
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
	my $update_userfullname = $db_conn->prepare("UPDATE network.eseri_user SET first_name = ?, last_name = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND username = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_userfullname->bind_param(1, $new_firstname[$i]);
	$update_userfullname->bind_param(2, $new_lastname[$i]);
	$update_userfullname->bind_param(3, $network_name);
	$update_userfullname->bind_param(4, $username[$i]);
	$update_userfullname->execute()                                                                                                                                         
	    or die "Couldn't execute statement: " . $update_userfullname->errstr;
	$update_userfullname->finish;
    }
}

sub deploy_main{
    generate_deployment();
    mylog(" - Performing User Fullname Config at $network_name for Username: @username - Old Firstname: @old_firstname - Old Lastname: @old_lastname - New Firstname: @new_firstname - New Lastname: @new_lastname");
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);
    configure_database();
    mylog(" - Done");
}
