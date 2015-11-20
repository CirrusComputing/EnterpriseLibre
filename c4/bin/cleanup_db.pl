#!/usr/bin/perl -w
#
# cleanup_db.pl - v1.6
#
# This script removes the configuration at the mail servers and 
# also execute the appropriate database queries depending on the
# db_option (ie. DELETE or BACKUP
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
use Cwd;
use Cwd 'abs_path';
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Sys::Syslog qw( :DEFAULT );

# EMAIL_DOMAIN=domainneverused.net
# DOMAIN=a1.newvirtualorgs.net
# BRIDGE=brA1
# NETWORK=10.101.32

my $db_option = shift or die "db_option not specified.\n";
my $org_name = shift or die "org name not specified.\n";
my $network_name = shift or die "network_name not specified.\n";
my $network_cidr = shift or die "network not specified.\n";
my $filename = shift or die "filename not specified.\n";

my $c4_root = abs_path( getcwd() . "/../");;
my $conf = new Config::General("$c4_root/bin/c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $sql = "";

#Get values of email_domain from the database.
$sql = "SELECT id from network.organization WHERE "
     . "network_name = ? AND network = ? "
     . "ORDER BY creation desc "
     . "LIMIT 1";
my $get_org_id = $db_conn->prepare($sql)
	or die "Couldn't prepare statement: " . $db_conn->errstr;
$get_org_id->bind_param(1, $network_name);
$get_org_id->bind_param(2, $network_cidr . ".0/24");
$get_org_id->execute()
        or die "Couldn't execute statement: " . $get_org_id->errstr;
my ($org_id) = $get_org_id->fetchrow_array();
$get_org_id->finish;

#Use of uninitialized value $org_id in string eq at ./cleanup_db.pl line 104.
if ((!defined $org_id) or $org_id eq ''){
	print "\n -- Record not found in the database. Therefore, not executing any database queries.\n"
}
else{
	if ($db_option eq 'DELETE'){
		#Delete organization record from database.
#		print "\n -- Deleting record from network.organization";
		$sql = "DELETE from network.organization "
		     . "WHERE id = ?";
		my $delete_from_db = $db_conn->prepare($sql)
			or die "Couldn't prepare statement: " . $db_conn->errstr;
		$delete_from_db->bind_param(1, $org_id, SQL_INTEGER);
		$delete_from_db->execute()
			or die "Couldn't execute statement: " . $delete_from_db->errstr;
		$delete_from_db->finish();

		#Delete previous ARCHIVED records for the same organization.
#		print "\n -- Deleting previous ARCHIVED records for the same organization\n";
		$sql = "DELETE from network.organization "
                     . "WHERE network = ? and status = 'ARCHIVED'";
                my $delete_archived_from_db = $db_conn->prepare($sql)
                        or die "Couldn't prepare statement: " . $db_conn->errstr;
                $delete_archived_from_db->bind_param(1, $network_cidr . ".0/24");
                $delete_archived_from_db->execute()
                        or die "Couldn't execute statement: " . $delete_archived_from_db->errstr;
                $delete_archived_from_db->finish();
	}
	elsif ($db_option eq 'BACKUP'){
		#Delete backup records from database because there is nothing to backup anymore.
#		print "\n -- Deleting record from network.backup";
		$sql = "DELETE from network.backup "
		     . "WHERE organization = ?";
		my $delete_from_table_backup = $db_conn->prepare($sql)
	                or die "Couldn't prepare statement: " . $db_conn->errstr;
	        $delete_from_table_backup->bind_param(1, $org_id, SQL_INTEGER);
	        $delete_from_table_backup->execute()
	                or die "Couldn't execute statement: " . $delete_from_table_backup->errstr;
		$delete_from_table_backup->finish();
	
		#Delete domain_config information since it doesn't apply anymore.
#		print "\n -- Deleting record from network.domain_config";
		$sql = "DELETE from network.domain_config "
	             . "WHERE organization = ?";
	        my $delete_from_table_domain_config = $db_conn->prepare($sql)
	                or die "Couldn't prepare statement: " . $db_conn->errstr;
	        $delete_from_table_domain_config->bind_param(1, $org_id, SQL_INTEGER);
	        $delete_from_table_domain_config->execute()
	                or die "Couldn't execute statement: " . $delete_from_table_domain_config->errstr;
	        $delete_from_table_domain_config->finish();

		#Remove the wan IP and cloud mapping
		my $update_cloud_wan_ip_mapping = $db_conn->prepare("UPDATE network.address_pool SET organization = NULL WHERE organization = ?")
                        or die "Couldn't prepare statement: " . $db_conn->errstr;
                $update_cloud_wan_ip_mapping->bind_param(1, $org_id, SQL_INTEGER);
                $update_cloud_wan_ip_mapping->execute()
                        or die "Couldn't execute statement: " . $update_cloud_wan_ip_mapping->errstr;
                $update_cloud_wan_ip_mapping->finish;
	
	
		#Update status of the org so that the next time C4 is run, c4q_aleph.pl knows that this organization needs to be restored.
		print "\n -- Updating organization status to ARCHIVED\n";
		$sql = "UPDATE network.organization "
	     	     . "SET status = 'ARCHIVED' "
		     . "WHERE id = ? ";
		my $update_org_status = $db_conn->prepare($sql)
			or die "Couldn't prepare statement: " . $db_conn->errstr;
	        $update_org_status->bind_param(1, $org_id, SQL_INTEGER);
	        $update_org_status->execute()
	                or die "Couldn't execute statement: " . $update_org_status->errstr;
	        $update_org_status->finish();
	}
	
	`chmod -x $c4_root/bin/cleanup/$filename; mv $c4_root/bin/cleanup/$filename $c4_root/bin/cleanup/$filename\_wasRun-$db_option`;
}

$db_conn->disconnect;

if ((!defined $org_id) or $org_id eq ''){
	$org_id = 'null';
}
syslog('info', "C4 cleanup performed $db_option for organization $org_name with id = $org_id ");
