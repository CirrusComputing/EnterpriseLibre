#!/usr/bin/perl -w

# Delete Org Record
# If C4 fails before the cleanup script is created, this utility can be handy. 
# We want to delete the record in network.organization,
#     with no chance of typo's.  If you have ever typed a bad DELETE into the psql cli then you will understand me.

use strict;

use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);

if (scalar @ARGV != 1){
	print "Usage: <ORG_ID> \n";
	exit;
}

my $username = getpwuid($<);
if ($username ne 'c4'){
	print "Usage: Please run this script as C4\n";
	exit;
}

my $org_id = $ARGV[0];

my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

my $sql = "SELECT status, network, bridge FROM network.organization "
        . "WHERE id = ?";

my $org_exists = $db_conn->prepare( $sql);

$org_exists->bind_param(1, $org_id);
$org_exists->execute()
    or die "Couldn't execute statement: " . $org_exists->errstr;

my ($org_exists_status, $org_exists_network, $org_exists_bridge) = $org_exists->fetchrow_array();

# check that the org exists
if (! defined $org_exists_status){
    die "no such org: " . $org_id;

# check that the org is in a basic state,
# otherwise a cleanup script probably exists
#   and it should be used instead of this script
} elsif ( (($org_exists_status ne 'PROCESSING_FAILED') 
	   && ($org_exists_status ne 'NEW')
	   && ($org_exists_status ne 'HOLD_FOR_IP'))
	  || ($org_exists_network ne '1.1.1.1/32')
	  || ( defined ($org_exists_bridge ))) {
    if (!defined $org_exists_bridge){
	$org_exists_bridge = 'null';
    }
    die "we might not want to del org: " . $org_id . " " . $org_exists_status . " " . $org_exists_network . " " . $org_exists_bridge ;

} else {
    # delete org record
    $sql = "DELETE FROM network.organization "
         . "WHERE id = ?";

    my $org_del = $db_conn->prepare( $sql);

    $org_del->bind_param(1, $org_id);
    $org_del->execute()
	or die "Couldn't delete org: " . $org_id . " " . $org_del->errstr;
}
print "Deleted record " . $org_id . "\n";
#end







