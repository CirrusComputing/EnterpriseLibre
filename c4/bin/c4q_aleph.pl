#!/usr/bin/perl -w
#
# C4 Aleph - v3.8
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
use DateTime;

use common qw(get_system_anchor_domain);

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();

my $conf = new Config::General("c4q_aleph.config");
my %config = $conf->getall;
for (values %config) {s|\[-system_anchor_domain-\]|$system_anchor_domain|g};

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};
my $MAILTEMPLATEDIR = $config{"mailtemplatedir"};
my $EXTRAERROREMAILADDRESS = $config{'erroremail'};
my $EMAILFROM			= $config{'emailfrom'};
my $INTERVAL = $config{"sleeptime"};

openlog("c4q_aleph", "", "user");
syslog('info', "Database connection established, loop engaging");

while(1){
	my $db_conn;
        my $conn_done = 0;
        while( $conn_done == 0) {
                if( $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")) {
                        $conn_done = 1;
                } else {
                        syslog('info', "Aleph cannot connect, $DBI::errstr");
                        sleep(5);
                }
        }
        # or die "Can't connect to database: $DBI::errstr\n";

	my $get_queue = $db_conn->prepare("SELECT data, date FROM loginsite.org_queue");
	my $queue_ref = $db_conn->selectrow_arrayref($get_queue);
        if (! defined $queue_ref){
                syslog('debug', "ready");
		$db_conn->disconnect
			or warn "Disconnection failed: $DBI::errstr\n";
                sleep($INTERVAL);
                next;
        }

	my $sql = "";
	$sql = "DELETE "
	     . "FROM loginsite.org_queue "
	     . "WHERE data = ? AND date = ?";
	
	my $delete_from_queue = $db_conn->prepare( $sql)
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "SELECT id, status FROM network.organization "
	     . "WHERE (network_name = ? or email_domain = ?)"
	     . "ORDER BY creation desc "
	     . "LIMIT 1";
	
	my $org_exists = $db_conn->prepare( $sql)
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO network.organization "
	     . "   (full_name, short_name, network_name, email_domain, nxserver, nxport, status, network, customer_type) "
	     . "VALUES "
	     . "   (' ', ' ', ' ', ' ', ' ', 80, 'ENQUEUED', '1.1.1.1/32', 'regular')"
	     . "RETURNING id";
	my $add_org = $db_conn->prepare( $sql)	
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "UPDATE network.organization "
	     . "SET full_name = ?, "
	     . "    short_name = ?, "
	     . "    network_name = ?, "
	     . "    email_domain = ?, "
	     . "    nxserver = ?, "
	     . "    status = ? "
	     . "WHERE id = ?";
	my $update_org = $db_conn->prepare( $sql)
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO network.domain_config "
	     . "VALUES "
	     . "   (?, '1.1', ?, ?, ?, '0.0.0.0')";
	my $add_domain_config = $db_conn->prepare( $sql)	
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO network.org_queue_omega "
	     . "   (id, username, first_name, last_name, email, timezone) "
	     . "VALUES (?, ?, ?, ?, ?, ?)";
	my $add_to_omega = $db_conn->prepare( $sql)
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO loginsite.paypal VALUES (?,?,?,?,?,?,?,?,?,?)";
        my $insert_paypal_details = $db_conn->prepare( $sql)
                or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO network.billing (organization, latest_txn_id) VALUES (?,?)";
	my $insert_billing_details = $db_conn->prepare( $sql)
                or die "Couldn't prepare statement: " . $db_conn->errstr;
	
	$sql = "INSERT INTO network.timezone_config "
	     . "    (organization, timezone) "
	     . "VALUES (?, ?)";
	my $add_timezone_config = $db_conn->prepare( $sql)	
		or die "Couldn't prepare statement: " . $db_conn->errstr;

	$sql = "INSERT INTO network.organization_config_status "
	     . "    (organization, dc, ccc, tzc, fpc, bc) "
	     . "VALUES (?, 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE')";
	my $add_organization_config_status = $db_conn->prepare( $sql)	
		or die "Couldn't prepare statement: " . $db_conn->errstr;

	# timestamp for the log
	my $t = DateTime->now;
	print "aleph: " . $t->datetime() . "\n";

	#Harvest the data
	my $data = $queue_ref->[0];
	my $date = $queue_ref->[1];
	#Prep our XML crunching apparatus
	my $parser = XML::LibXML->new();
	my $dom = $parser->load_xml({ string => $data });
	my $xpc = XML::LibXML::XPathContext->new( $dom );

	my $first_name 	= 	trim( $xpc->findvalue('/organization/firstname'));
	my $last_name 	= 	trim( $xpc->findvalue('/organization/lastname'));
	my $username	=	trim( $xpc->findvalue('/organization/username'));
	my $full_name 	= 	trim( $xpc->findvalue('/organization/full_name'));
	my $domain      =       $xpc->findvalue('/organization/domain');
	my $email 	= 	trim( $xpc->findvalue('/organization/email'));
	my $timezone	=	$xpc->findvalue('/organization/timezone');

	$add_org->execute()
		or die "Couldn't execute statement: " . $add_org->errstr;

	#Retrieve the ID of the org we just inserted
	my ($org_id) = $add_org->fetchrow();	
	if ($full_name eq ''){
		$full_name = 'a'.$org_id;
	}
	my $short_name	=	&choose_short_name($full_name);
	if ($domain eq ''){
		$domain = lc($short_name.".$system_anchor_domain");
	}
	my $network = $domain;	
		
	syslog('info', "Data is: $first_name $last_name ($username), $email, $short_name, $network, $domain, $email, $timezone");
	
	$org_exists->bind_param(1, $network);
	$org_exists->bind_param(2, $domain);
	$org_exists->execute()
		or die "Couldn't execute statement: " . $org_exists->errstr;
	my ($org_exists_id, $org_exists_status) = $org_exists->fetchrow_array();
	
	if (! defined $org_exists_status){
			syslog('info', "New Organization");
	}
	elsif ($org_exists_status eq 'ARCHIVED'){
			syslog('info', "Restore Organization");
			syslog('info', "Organization exists in Database with Status = ARCHIVED and Organization ID = $org_exists_id");
	}
	else{
		syslog('info', "Organization exists in the database and needs to be manually cleaned first - $domain/$network");
		#The org exists in the database, so send email to admin, ie Nimesh
		my $title = "ORG_EXISTS | Firstname: ".$first_name." | Lastname: ".$last_name." | Username: ".$username." | Email: ".$email." | Shortname: ".$short_name." | Network: ".$network." | Timezone: ".$timezone. " | Status: ".$org_exists_status." |";
		&sendMail('org_exists', $title , $full_name, $domain, $EXTRAERROREMAILADDRESS);
		#Purge the Data in the aleph queue
        	$delete_from_queue->bind_param(1, $data);
	        $delete_from_queue->bind_param(2, $date);
        	$delete_from_queue->execute()
			or die "Couldn't execute statement: " . $delete_from_queue->errstr;
	        syslog('info', "Removed from aleph queue");
		$db_conn->disconnect
                        or warn "Disconnection failed: $DBI::errstr\n";
		next;
	}
	
	$update_org->bind_param(1, $full_name);
	$update_org->bind_param(2, $short_name);
	$update_org->bind_param(3, $network);
	$update_org->bind_param(4, $domain);
	$update_org->bind_param(5, $network);
	$update_org->bind_param(6, "NEW");
	$update_org->bind_param(7, $org_id, SQL_INTEGER);
	$update_org->execute()
		or die "Couldn't execute statement: " . $update_org->errstr;
		
	#Add info to table network.domain_config
	$add_domain_config->bind_param(1, $org_id, SQL_INTEGER);
	$add_domain_config->bind_param(2, $domain);
	$add_domain_config->bind_param(3, "imap.".$network);
	$add_domain_config->bind_param(4, $domain);
	$add_domain_config->execute()
	    or die "Couldn't execute statement: " . $add_domain_config->errstr;

	#Now add the extra details into the omega queue
	$add_to_omega->bind_param(1, $org_id, SQL_INTEGER);
	$add_to_omega->bind_param(2, $username);
	$add_to_omega->bind_param(3, $first_name);
	$add_to_omega->bind_param(4, $last_name);
	$add_to_omega->bind_param(5, $email);
	$add_to_omega->bind_param(6, $timezone);
	$add_to_omega->execute()
	    or die "Couldn't execute statement: " . $add_to_omega->errstr;
	syslog('info', "Added to omega queue");
	
        #Now insert paypal details
	$insert_paypal_details->bind_param(1, $org_id, SQL_INTEGER);
	$insert_paypal_details->bind_param(2, $org_id);
	$insert_paypal_details->bind_param(3, $email);
	$insert_paypal_details->bind_param(4, $org_id);
	$insert_paypal_details->bind_param(5, 'web_accept');
	$insert_paypal_details->bind_param(6, $org_id);
	$insert_paypal_details->bind_param(7, '');
	$insert_paypal_details->bind_param(8, 'CAD');
	$insert_paypal_details->bind_param(9, '0.01');
	$insert_paypal_details->bind_param(10, $date);
	$insert_paypal_details->execute()
	    or die "Couldn't execute statement: " . $insert_paypal_details->errstr;
	syslog('info', "Inserted PayPal details");

	#Now insert billing details
	$insert_billing_details->bind_param(1, $org_id, SQL_INTEGER);
	$insert_billing_details->bind_param(2, $org_id);
	$insert_billing_details->execute()
	    or die "Couldn't execute statement: " . $insert_billing_details->errstr;
	syslog('info', "Inserted billing details");

	#Add info to table network.timezone_config
	$add_timezone_config->bind_param(1, $org_id, SQL_INTEGER);
	$add_timezone_config->bind_param(2, $timezone);
	$add_timezone_config->execute()
	    or die "Couldn't execute statement: " . $add_timezone_config->errstr;

	#Add info to table network.organization_config_status
	$add_organization_config_status->bind_param(1, $org_id, SQL_INTEGER);
	$add_organization_config_status->execute()
	    or die "Couldn't execute statement: " . $add_organization_config_status->errstr;

	#Finally, purge the remaining data in the aleph queue
	$delete_from_queue->bind_param(1, $data);
	$delete_from_queue->bind_param(2, $date);
	$delete_from_queue->execute()
	    or die "Couldn't execute statement: " . $delete_from_queue->errstr;
	syslog('info', "Removed from aleph queue");
	$db_conn->disconnect
                or warn "Disconnection failed: $DBI::errstr\n";
}
closelog;

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
# Take the org's formal name from top field in the form,
# and generate a short name with no spaces
# that is unique with existing orgs in the DB 
sub choose_short_name{
                my ($full_name) = @_;
                #We'll take any alphanumeric, make it all lowercase
                my @longchars = split(//, $full_name);
                my $alphachars = '';
                foreach my $char (@longchars){
                        if ($char =~ m/[A-Za-z0-9]/){
                                $alphachars .= $char;
                        }
                }

                #Truncate at 20
                if (length($alphachars) > 20){
                        $alphachars = substr($alphachars, 0, 20);
                }
                return uc($alphachars);
}

sub trim {
    (my $s = $_[0]) =~ s/^\s+|\s+$//g;
    return $s;        
}
