#!/usr/bin/perl -w
#
# C4 Omega - v3.3
#
# Grabs request from web server and puts it in processing queue for C4 Omega.
#
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

use MIME::Lite::TT::HTML;
use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use XML::LibXML;
use Sys::Syslog qw( :DEFAULT );

use Cwd;
use Cwd 'abs_path';
use DateTime;
use PrimeDB qw(&countUsers);
use common qw(get_system_anchor_domain);

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();

my $conf = new Config::General("c4q_omega.config");
my %config = $conf->getall;
for (values %config) {s|\[-system_anchor_domain-\]|$system_anchor_domain|g};

my $DBNAME 			= $config{"dbname"};
my $DBHOST 			= $config{"dbhost"};
my $DBUSER 			= $config{"dbuser"};
my $DBPASS 			= $config{"dbpass"};
my $MAILTEMPLATEDIR 		= $config{"mailtemplatedir"};
my $EXTRAERROREMAILADDRESS 	= $config{'erroremail'};
my $EMAILFROM			= $config{'emailfrom'};
my $INTERVAL 			= $config{"sleeptime"};
my $ORGDIR			= $config{"xmldirectory"};

openlog("c4q_omega", "", "user");

syslog('info', "Database connection established, loop engaging");
writeTestLog( -1, 'init',  'init',  'init',  'init');
while(1){
	my $db_conn;
	my $conn_done = 0;
	while( $conn_done == 0) {
		if( $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")) {
			$conn_done = 1;
		} else {
			syslog('info', "Omega cannot connect, $DBI::errstr");
			sleep(15);
		}
	}
	# or die "Can't connect to database: $DBI::errstr\n";

	my $get_from_queue_proc = $db_conn->prepare("SELECT id FROM network.organization WHERE status = 'PROCESSING'")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	my $queue_ref_proc = $db_conn->selectrow_arrayref($get_from_queue_proc);
	$get_from_queue_proc->finish;
	if (defined $queue_ref_proc){
		my $org_id_proc = $queue_ref_proc->[0];
		sendMail('hold_resources', "There is already an org $org_id_proc with status PROCESSING. Can't process another at the same time.", 'Super', 'User', $EXTRAERROREMAILADDRESS);
		exit;
	}	

	my $get_from_queue	= $db_conn->prepare("SELECT id, short_name FROM network.organization WHERE status = 'NEW' ORDER BY creation ASC")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	my $queue_ref = $db_conn->selectrow_arrayref($get_from_queue);
	$get_from_queue->finish;
	if (! defined $queue_ref){
		syslog('info', "Nothing in queue");
		$db_conn->disconnect
			or warn "Disconnection failed: $DBI::errstr\n";			
		sleep($INTERVAL);
		next;
	}

	my $get_data            = $db_conn->prepare("SELECT first_name, last_name, email, timezone, username FROM network.org_queue_omega WHERE id = ?")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
    my $get_free_space      = $db_conn->prepare("SELECT disk_per_org FROM network.usage_stats")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
    my $delete_from_queue   = $db_conn->prepare("DELETE FROM network.org_queue_omega WHERE id = ?")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
    my $get_hwh_hostname	= $db_conn->prepare("SELECT hostname FROM network.server WHERE id = ?")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
		
	#assume that only one org is PROCESSING
	
	#Determine the best hardware host to use
	#Choose this by selecting all HWH such that:
	#They have free disk capacity
	#Their version is 2
	
	# count active users in orgs in each server
	# check that the server has IP's available
	# divide the RAM by the user count 
	# sort with best ratio first
		
	#bingo
	#there were problems if the hwh had no orgs yet
	#solved by 
	#  -adding 1 to the user count to avoid divide-by-zero
	#  -left joins to preserve all hwhs
	#  -allow hostname to be NULL
       	
	my $sql = " "
	    . "SELECT "
	    . "    hwh.id, "
	    . "    ROUND(hwh.max_ram_in_mib / (1+ ( "
	    . "        SELECT "
	    . "            SUM(CASE "
	    . "                 WHEN usr.type='full' "
	    . "                    THEN 1 "
	    . "                 WHEN usr.type='email_only' "
	    . "                     THEN 1::float/20 END) "
	    . "        FROM "
	    . "            network.server as srv "
	    . "        LEFT JOIN "
	    . "            network.eseri_user AS usr "
	    . "        ON srv.organization=usr.organization "
	    . "        WHERE (usr.status='ACTIVE' "
	    . "        OR   usr.status='ACTIVATING' "
	    . "        OR   usr.status='UPDATING') "
	    . "        AND srv.hardware_host=hwh.id "
	    . "        AND srv.hostname='chaos' or srv.hostname is NULL ))) AS ramratio "
	    . "FROM "
	    . "    network.usage_stats AS stats, "
	    . "    network.hardware_hosts AS hwh "
	    . "WHERE "
	    . "    hwh.version_available = 2 "
	    . "AND hwh.disk_free_in_gib > stats.disk_per_org "
	    . "ORDER BY ramratio DESC ";
	
	my $find_hardware_host = $db_conn->prepare( $sql);
		
	$sql = "SELECT address FROM network.free_ips "
	    . "WHERE address IN "
	    . "(SELECT address "
	    . "    FROM network.hwh_ips "
	    . "    WHERE serverid = "
	    . "    (SELECT gatewayid "
	    . "	FROM network.server_pool "
	    . "	WHERE serverid = ?)) "
	    . "ORDER BY address ASC";
	my $get_free_ips = $db_conn->prepare( $sql);
	
	$sql = "UPDATE network.address_pool "
	    . "SET organization = ? "
	    . "WHERE address = ?";
	my $update_address = $db_conn->prepare( $sql);

	############################
	##### Harvest the data #####
	############################
	my $org_id = $queue_ref->[0];
	my $short_name = $queue_ref->[1];

	$get_data->bind_param(1, $org_id, SQL_INTEGER);
	$get_data->execute()
		or die "Couldn't execute statement: " . $get_data->errstr;
	my ($first_name, $last_name, $email, $timezone, $username) = $get_data->fetchrow_array();
	$get_data->finish;
	
	##################################################
	##### Find hwh with the best RAM/users ratio #####
	##################################################
	my ($hwh_id, $hwh_hostname) = "";
	my $hwh_ref = $db_conn->selectrow_arrayref($find_hardware_host);
	$find_hardware_host->finish;
	if ($hwh_ref){
		$hwh_id = $hwh_ref->[0];
		syslog('info', "Hardware host is $hwh_id");
		
		#Get hardware hostname
		$get_hwh_hostname->bind_param(1, $hwh_id, SQL_INTEGER);
		$get_hwh_hostname->execute()
			or die "Couldn't execute statement: " . $get_hwh_hostname->errstr;
		($hwh_hostname) = $get_hwh_hostname->fetchrow_array();
		$get_hwh_hostname->finish;
		syslog('info', "Data is $first_name $last_name ($username), $email, $timezone, HWH:$hwh_id ($hwh_hostname)");
		
		#Get min disk space needed to create an org.
		my ($min_free_space) = $db_conn->selectrow_array($get_free_space);
		$get_free_space->finish;
		
		#Check if it hwh really does have free space.
		#Here is some good double-checking, because we already know from the DB that there is enough space,
		#but we also check the actual value from the hwh:
		my $full_hostname = "$hwh_hostname.$system_anchor_domain";
		print " -- Clearing SSH known hosts for target host $full_hostname \n";
		`ssh-keygen -R $full_hostname`;
		do {
			print " -- Acquiring SSH fingerprint for target host \n";
			`ssh-keyscan -t rsa -H $full_hostname`;
			sleep(2);
		} while ($? !=0);
		`ssh-keyscan -t rsa -H $full_hostname >> $ENV{HOME}/.ssh/known_hosts`;
	
		my $volgroups_out = `ssh root\@$hwh_hostname.$system_anchor_domain "vgs --noheadings --nosuffix --units g --separator ','"`;
		my @volgroups = split(/\n/, $volgroups_out);
		my $has_free_space = 0;	
		foreach my $group (@volgroups){
			my @data = split(/,/, $group);
			my $name = $data[0];
			my $free_space = $data[6];
			if ($min_free_space < $free_space){
				$has_free_space = 1;
				last;
			}
		}
		unless ($has_free_space){
			update_org($db_conn, $org_id, 'HOLD_FOR_DISK');
			syslog('notice', "Org Hold - HOLD_FOR_DISK");
			sendMail('hold_resources', "Org Hold - HOLD_FOR_DISK", $first_name, $last_name, $EXTRAERROREMAILADDRESS);
			$db_conn->disconnect
				or warn "Disconnection failed: $DBI::errstr\n";
			exit;
		}
		syslog('info', "Free space available");
	}
	else{
		update_org($db_conn, $org_id, 'HOLD_FOR_DISK');
		syslog('notice', "Org Hold - HOLD_FOR_DISK");
		sendMail('hold_resources', "Org Hold - HOLD_FOR_DISK", $first_name, $last_name, $EXTRAERROREMAILADDRESS);
		$db_conn->disconnect
			or warn "Disconnection failed: $DBI::errstr\n";
		exit;
	}
	
	########################
	##### Determine IP #####
	########################
	my ($ip_address) = "";
	$get_free_ips->bind_param(1, $hwh_id, SQL_INTEGER);
	$get_free_ips->execute()
		or die "Couldn't execute statement: " . $get_free_ips->errstr;
	($ip_address) = $get_free_ips->fetchrow();
	$get_free_ips->finish;
	
	if ($ip_address){
		$update_address->bind_param(1, $org_id, SQL_INTEGER);
		$update_address->bind_param(2, $ip_address);
		$update_address->execute()
			or die "Couldn't execute statement: " . $update_address->errstr;
		$update_address->finish;
		syslog('info', "IP address is $ip_address");
	}
	else{
		update_org($db_conn, $org_id, 'HOLD_FOR_IP');
		syslog('notice', "Org Hold - HOLD_FOR_IP");
		sendMail('hold_resources', "Org Hold - HOLD_FOR_IP", $first_name, $last_name, $EXTRAERROREMAILADDRESS);
		$db_conn->disconnect
			or warn "Disconnection failed: $DBI::errstr\n";
		exit;
	}
	
	####################################
	##### Make the XML file for C4 #####
	####################################
	open(XML, ">$ORGDIR/$short_name.xml");
	print XML <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<c4:config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:c4="http://www.eseri.com/C4" xsi:schemaLocation="http://lucid-mirror.wan.virtualorgs.net/schema/C4/C4.xsd">
<country>CA</country>
<province>ON</province>
<vps_config_template>vswap-256m</vps_config_template>
<hardware_host>$hwh_hostname.$system_anchor_domain</hardware_host>
<document_type>ODF</document_type>
<sql_ledger_chart_of_accounts>Canada-English_General</sql_ledger_chart_of_accounts>

EOF

	print XML "<timezone>$timezone</timezone>\n";
	print XML "<manager_username>$username</manager_username>\n";
	print XML "<manager_firstname>$first_name</manager_firstname>\n";
	print XML "<manager_lastname>$last_name</manager_lastname>\n";
	print XML "<manager_external_email>$email</manager_external_email>\n";
	print XML "</c4:config>\n\n";
	close XML;
	
	#Delete from omega queue
	$delete_from_queue->bind_param(1, $org_id, SQL_INTEGER);
	$delete_from_queue->execute()
		or die "Couldn't execute statement: " . $delete_from_queue->errstr;
	$delete_from_queue->finish;
	#Update org status
	update_org($db_conn, $org_id, 'PROCESSING');
	
	####################
	##### Start C4 #####
	####################
	`lockfile -30 -r-1 c4.lock`;
	sendMail('begin', 'Your new cloud has started processing', $first_name, $last_name, $email);
	sendMail('begin', 'Org start', $first_name, $last_name, $EXTRAERROREMAILADDRESS);
	syslog('info', "About to start C4");
	writeTestLog( -1, $org_id, $short_name, $hwh_hostname, $hwh_id);

	system("./c4.pl", "--file", "../orgs/$short_name.xml", "--org_id", "$org_id");
	my $ret = $?;
	$ret = $ret >> 8;
	if ($ret == 0){
		update_org($db_conn, $org_id, 'ACTIVE');
		syslog('info', 'Org created successfully');
	}
	else{
		update_org($db_conn, $org_id, 'PROCESSING_FAILED');
		sendMail('failure', 'FAILURE', $first_name, $last_name, $EXTRAERROREMAILADDRESS);
		syslog('notice', 'Org create failed');
	}

	`rm -f c4.lock`;
	$db_conn->disconnect
		or warn "Disconnection failed: $DBI::errstr\n";

	writeTestLog( $ret, $org_id, $short_name, $hwh_hostname, $hwh_id);
	sleep($INTERVAL);
}

sub update_org{
	my ($db_conn, $id, $status) = @_;
	my $update_org	= $db_conn->prepare("UPDATE network.organization SET status = ? WHERE id = ?")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_org->bind_param(1, $status);
	$update_org->bind_param(2, $id, SQL_INTEGER);
	$update_org->execute()
		or die "Couldn't execute statement: " . $update_org->errstr;
	$update_org->finish;
}

sub sendMail{
	my ($msg_name, $title, $first, $last, $address) = @_;
	my %email_params;
	$email_params{'firstname'} = $first;
	$email_params{'lastname'} = $last;
	my %email_options;
	$email_options{INCLUDE_PATH} = $MAILTEMPLATEDIR;
	my $msg = MIME::Lite::TT::HTML->new(
		From => $EMAILFROM,
		To => $address,
		Subject => $title,
		Template => {
			text => "$msg_name.txt.tt",
			html => "$msg_name.html.tt"
		},
		TmplOptions => \%email_options,
		TmplParams => \%email_params
	);
	$msg->send();
}

sub writeTestLog {
    my( $status, $org_id, $short_name, $hwh_hostname, $hwh_id) =  @_;

    my $t = DateTime->now;
    my $logLine = $t->datetime() . " , ";

    if( $status == 1) {
	$logLine .=  "Fail   , ";
    } elsif ( $status == 0) {
	$logLine .=  "Success, ";
    } else {
	$logLine .=  "Start,   ";
    }

    $logLine .= sprintf "%9d , ", $org_id;
    $logLine .= sprintf "%10s , ", $hwh_hostname;

    foreach my $hwh_id_temp (2680, 384, 693) {
	my $n_users = countUsers( $hwh_id_temp );
	$logLine .=  sprintf "%12d , ", $n_users;
    }

    my $c4_root = abs_path( getcwd() . "/../");
    open( LOG, ">> $c4_root/cache/loadBalanceTest.log");
    print LOG "$logLine \n";
    close( LOG);
}
