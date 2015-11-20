#!/usr/bin/perl -w
#
# cleanup_db_ip.pl - v1.3
#
# This script frees the external IP in the DB.
# just the new IP in cloud_move
#
# Created by Rick Leir <rleir@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
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
use Sys::Syslog qw( :DEFAULT );

my $wan_address = shift or die "IP not specified.\n";

my $conf = new Config::General("$ENV{HOME}/bin/c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $sql = "UPDATE network.address_pool "
        . "SET organization = NULL    "
        . "WHERE address = ?";

#Remove the wan IP and cloud mapping
my $update_cloud_wan_ip_mapping = $db_conn->prepare( $sql)
    or die "Couldn't prepare statement: " . $db_conn->errstr;
$update_cloud_wan_ip_mapping->bind_param(1, $wan_address);
$update_cloud_wan_ip_mapping->execute()
    or die "Couldn't execute statement: " . $update_cloud_wan_ip_mapping->errstr;
$update_cloud_wan_ip_mapping->finish;

$db_conn->disconnect;

syslog('info', "Cloud_move init cleanup for $wan_address");
