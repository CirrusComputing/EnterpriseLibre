#
# PrimeDB.pm - v1.1
#
# Module to access the Prime DB
# Currently only has a func to set the host's disk free space
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

package PrimeDB;

use strict;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Config::General;
use DBI qw(:sql_types);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(updateFree countUsers func2);
%EXPORT_TAGS = ( DEFAULT => [qw(&updateFree countUsers)],
                 Both    => [qw(&updateFree &func2)]);

sub updateFree  { 
    my $hw_hostname = shift;
    my $free_space = shift;
    # print "host $hw_hostname sp $free_space \n";
    my $conf = new Config::General("$ENV{HOME}/bin/c4.config");
    my %config = $conf->getall;
    my $DBNAME = $config{"dbname"};
    my $DBHOST = $config{"dbhost"};
    my $DBUSER = $config{"dbuser"};
    my $DBPASS = $config{"dbpass"};

    my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")
	or die "Couldn't connect to database: " . DBI->errstr;

    my $set_free_space = $db_conn->prepare("UPDATE network.hardware_hosts SET disk_free_in_gib = ? "
					   . "WHERE id = (SELECT id FROM network.server WHERE hostname = ?)") 
       or die "Couldn't prepare statement: " . $db_conn->errstr;

    $set_free_space->bind_param(1, $free_space, SQL_INTEGER );
    $set_free_space->bind_param(2, $hw_hostname );
#    $set_free_space->bind_param(2, "'" . $hw_hostname . "'");
    $set_free_space->execute()
       or die "Couldn't execute statement: " . $set_free_space->errstr;

    $set_free_space->finish;
    return 0;
}

# How many users, given the hwh id?
sub countUsers  { 
    my $hwh_id = shift;
    my $conf = new Config::General("$ENV{HOME}/bin/c4.config");
    my %config = $conf->getall;
    my $DBNAME = $config{"dbname"};
    my $DBHOST = $config{"dbhost"};
    my $DBUSER = $config{"dbuser"};
    my $DBPASS = $config{"dbpass"};

    my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")
	or die "Couldn't connect to database: " . DBI->errstr;

    my $sql = " "
	    . "SELECT usr.organization, count(usr.id)            "
	    . "FROM                                              "
	    . "   network.server as srv                          "
	    . "LEFT JOIN                                         "
	    . "   network.eseri_user as usr                      "
	    . "ON                                                " 
	    . "   srv.organization=usr.organization              "
	    . "WHERE                                             " 
	    . "   usr.status<>'ARCHIVED'                         "
	    . "AND                                               "
	    . "   usr.status<>'PROCESSING_FAILED'                "
	    . "AND                                               "
	    . "   srv.hardware_host=?                            "
	    . "AND                                               "
	    . "   srv.hostname='chaos' or srv.hostname is NULL   "
	    . "GROUP BY usr.organization;                        ";

    my $count_users = $db_conn->prepare( $sql);
    $count_users->bind_param(1, $hwh_id);
    $count_users->execute()
	or die "Couldn't execute statement: " . $count_users->errstr;
    # for each org in the hwh, count the users
    my $total = 0;
    my $moreInner = 1;
    while( $moreInner) {
	my ($org, $count ) = $count_users->fetchrow_array;
	if (!$org){
	    $moreInner = 0;
	} else {
	    $total += $count;
	}
    }
    return $total;
}

sub func2  { return reverse @_  }

1;
