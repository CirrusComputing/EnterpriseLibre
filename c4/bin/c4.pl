#!/usr/bin/perl -w
#
# C4 - v5.9
#
# Perl script that drives the C4 organization creation process
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

use strict;
use Getopt::Long;
use Net::SSH2;
use Pod::Usage;
use Locale::Country;
use Locale::SubCountry;
use DateTime;
use Net::DNS;
use DateTime::TimeZone;
use IPC::Run qw( run timeout );
use Regexp::Common qw[Email::Address];
use Email::Address;
use threads;
use threads::shared;
use Thread::Queue;
use Cwd;
use Cwd 'abs_path';
use XML::LibXML;
use Config::General;
use DBD::Pg qw(:pg_types);
use DBI qw(:sql_types);
use RPC::XML;
use RPC::XML::Client;
use File::Find;
use File::Slurp;
use File::Path;
use File::Copy;
use Tie::File;
use POSIX qw(floor);

require File::Temp;
use File::Temp ();
use Comms qw(ssh scp ssh_key);
use common qw(get_system_anchor_domain);


my $debug_mode = 1;

#Load configuration settings
my $conf = new Config::General("c4.config");
my %config = $conf->getall;

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};
my $C3ADDRESS = $config{"c3address"};
my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")
    or die "Couldn't connect to database: " . DBI->errstr;

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain($db_conn);
my $system_anchor_ip;

# From DB rec network.organization 
my $email_domain;

#Variables to retrieve from the command line
my $short_name = ""; # "A1" or "A2"
my $org_full = ""; # "Free Open Source Solutions Incorporated"
my $org_domain = ""; # a1.$system_anchor_domain or a2.$system_anchor_domain - this becomes the Kerberos realm name

my $org_country = ""; # Country code for org - ca, us, etc.
my $org_province = ""; # Province/state code for org - on, al, nb, bc, etc.
my $org_timezone = ""; # Timezone for org - America/Toronto, Etc/UTC, etc.

my $cidr_network = ""; #Network as returned from Postgres database
my $org_network = ""; # 24-bit form of the IPv4 network for the cloud, without a trailing "." or netmask (E.g. 10.1.100)
my $hardware_host = ""; # FQDN of the hardware host for the cloud (e.g. server.$system_anchor_domain)
my $hardware_hostname = ""; #hostname for the hardware host (e.g. server1 server2)
my $veid_base = 0; #Positive integer base on which we index all virtual server VEIDs
my $vz_base_path = ""; #Root folder for OpenVZ
my $bridge = ""; #Name of the network bridge for the hardware host
my $wan_ip = ""; #WAN IP address for the organization
my $wan_netmask = ""; #Netmask for WAN IP address for the organization (E.g 255.255.255.240)
my $custom_email_domain = ""; #Domain name that should be used to form contact emails for organization (e.g. example.org)
my $has_custom_email; #Leave as undef until we know there is a custom email domain
my $sql_ledger_chart_of_accounts = ""; # The SQL Ledger Chart Of Accounts in text format (e.g. Canada-English_General)
my $gateway_hostname = ""; # The hostname of the server that will act as the gateway for the local data centre
my $hwgateway = ""; # The IP address of the server in the data centre that the gateway must route to
my $short_domain = ""; # Short domain name
my $cloud_volume_size = "30"; # The cloud volume size to be created. 

my $backup_server = ""; # The hostname of the server backup up the org containers
my $backup_target_url = ""; # The backup target url that duply uses to make a connection.

my $manager_username = ""; # Username for the IT manager - first user in the organization
my $manager_firstname = ""; # First name for the IT manager
my $manager_lastname = ""; # Last name for the IT manager
my $manager_phonenumber = ""; # Telephone contact number for the IT manager
my $manager_external_email = ""; # External e-mail account for the IT manager

my $document_format = ""; # Whether to use ODF or MS file formats

my $country_code_object; #We'll use this to determine the validity of the given country's state/prov, compared with ISO standard
my $xmldoc; #Root of the DOM for the XML config file
my $parser; #XML parsing object
my $schema; #XML schema validating object
my $xpath;  #XPath object
my %capabilities; #List of capabilities to install for the organization, always Enterprise package capabilities
my %capabilities_enable; #List of capabilities to enable for the package chosen for the organization
my @all_capabilities = (); #List of all possible capabilities
my @vps1_list = (); # List of veids for VPS1
my @vps2_list = (); # List of veids for VPS2
my @container_list = (); # Container List

my $org_id = -1; #Database ID for the organization
my $hwh_id = -1; #Database ID for the hardware host
my $org_status = "";
my $man = 0;
my $help =0;

my $previous_org_id; #Previous org id for Backup/Restore
my $previous_org_network; #Previous org network for Backup/Restore
my $previous_org_status; #Previous org status for Backup/Restore

#VEID offsets for all hosts
my %veids = (
	zeus => 2,
	hermes => 3,
        apollo => 4,
	athena => 10,
	aphrodite => 11,
	hades => 30,
	hera => 31,
	poseidon => 32,
	cronus => 33,
	atlas => 34,
	erato => 35,
	metis => 36,
	gaia => 37,
	trident => 39,
	chaos => 50
);


my $c4_root = abs_path( getcwd() . "/../");

#VALIDATION CODE
my $input_file;
GetOptions("file=s" => \$input_file, "help|?" => \$help, "man" => \$man, "org_id=i" => \$org_id) or pod2usage(1);
pod2usage(1) if $help;
pod2usage("-exitstatus" => 0, "-verbose" => 2) if $man;
pod2usage("-exitstatus" => 1, "-message" => "Could not read XML input file") unless ( $input_file && -r $input_file);

#Create parser
$parser = XML::LibXML->new();
#Create DOM from file using parser
my $dom = $parser->load_xml( location => $input_file );
#Create XPath object
my $xpc = XML::LibXML::XPathContext->new( $dom );
#Create schema validation object using schema location drawn from XML document
my $xmlschema = XML::LibXML::Schema->new( location => $xpc->findvalue( '//@xsi:schemaLocation' ) );
#Validate XML DOM against loaded schema
eval { $xmlschema->validate( $dom ) };
die $@ if $@; #If validation failed, stop
#Retrieve XML elements that can't be validated by schema alone, and validate
#$org_domain = $xpc->findvalue('/c4:config/domain');
$org_country = $xpc->findvalue('/c4:config/country');
$org_province = $xpc->findvalue('/c4:config/province');
$org_timezone = $xpc->findvalue('/c4:config/timezone');
$has_custom_email = 1;
$manager_external_email = $xpc->findvalue('/c4:config/manager_external_email');


#FLOW VARIABLES
#These variables control what happens, and when in the course of c4's execution
#To add new elements to or remove elements from the c4 script, you should only have to modify these variables
#Blocks are run in order as listed
#Blocks which have "thread" set to "yes" will run completely independently in a forked process - they'll never return a success or failure

my @flow = (
	{ name => "Read_Entry", thread => "no", function => \&read_db},
	{ name => "Choose_Network", thread => "no", function => \&choose_network},
	{ name => "Choose_VEID", thread => "no", function => \&choose_veid},
	{ name => "HW_Host", thread => "no", function => \&set_hardware_host},
	{ name => "Capabilities", thread => "no", function => \&determine_capabilities},
        { name => "VPS_List", thread => "no", function => \&determine_vps_list},
	{ name => "CA", thread => "no", function => \&createRootCertificate},
	{ name => "Make_Cleanup", thread => "no", function => \&make_cleanup},
	{ name => "Network", thread => "no"},
	{ name => "Record_Bridge", thread => "no", function => \&record_bridge},
	{ name => "Update_Cleanup", thread => "no", function => \&update_cleanup},
	{ name => "Storage", thread => "no"},
	{ name => "VPS1", thread => "no" },
	{ name => "SMC_DNS1", thread => "no" },
	{ name => "DNS", thread => "no" },
	{ name => "SMC_DNS2", thread => "no" },
	{ name => "Firewall", thread => "no" },
	{ name => "VPS2", thread => "no" },
	{ name => "Update_Free_Space", thread => "no", function => \&update_free_space},
	{ name => "Backup", thread => "no"},
	{ name => "Kerberos", thread => "no"},
	{ name => "LDAP", thread => "no"},
	{ name => "Database", thread => "no"},
	{ name => "Email", thread => "no"},
	{ name => "Web", thread => "no"},
	{ name => "Web2", thread => "no"},
	{ name => "Nuxeo", thread => "no"},
	{ name => "SOGo", thread => "no"},
	{ name => "Funambol", thread => "no"},
	{ name => "Webhuddle", thread => "no"},
	{ name => "XMPP", thread => "no"},
	{ name => "Desktop", thread => "no"},
	{ name => "NX_key_entry", thread => "no", function => \&set_org_nx_key},
	{ name => "Reboot", thread => "no"},
	{ name => "Backup_Configuration", thread => "no", function => \&backup_configuration},
	{ name => "SMC_Nagios", thread => "no"},
	{ name => "SMC_C5", thread => "no"},
        { name => "SMC_Email", thread => "no"},
	{ name => "Cloud_Email_SSH_Key", thread => "no", function => \&cloud_email_ssh_key},
    	{ name => "FirewallProxy_Config_Defaults", thread => "no", function => \&firewallproxy_config_defaults},
    	{ name => "CloudCapability_Config_Defaults", thread => "no", function => \&cloudcapability_config_defaults},
	{ name => "First_user", thread => "no", function => \&create_first_user}
);

#System control variables - change these to make C4 more or (yeah, right) less retarded
my $number_of_threads = 6;

#Block functions are defined here
sub set_hardware_host{
	my ($xpc) = @_;
	print " -- Setting hardware host\n";
	$hardware_host = $xpc->findvalue('/c4:config/hardware_host');
	$hardware_host =~ m/([^.]+)\.(.+)/;
	$hardware_hostname = $1;
	my $hardware_network = $2;
	print " --- HWH appears to be $hardware_hostname in network $hardware_network\n";
	my $db_st = $db_conn->prepare("SELECT COUNT(*) FROM network.organization WHERE network_name = ? AND is_customer = FALSE")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$db_st->bind_param(1, $hardware_network); # zzz pass parm to execute
	$db_st->execute()
	    or die "Couldn't execute statement: " . $db_st->errstr;
	my ($hwh_org_count) = $db_st->fetchrow();
	$db_st->finish;

	my $hwh_org_id = -1;
	print " --- Found $hwh_org_count instances of hwh network\n";
	if ($hwh_org_count == 0){
		#This means the hardware host's org doesn't exist
		#We'll just fill in the blanks with some defaults so we can keep going
		my $make_hwh_org = $db_conn->prepare("INSERT INTO network.organization (full_name, short_name, network_name, email_domain, is_customer) VALUES (?, ?, ?, ?, ?) RETURNING id")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$make_hwh_org->bind_param(1, "Hardware hosting network");
		$make_hwh_org->bind_param(2, "HWHN");
		$make_hwh_org->bind_param(3, $hardware_network);
		$make_hwh_org->bind_param(4, $hardware_network);
		$make_hwh_org->bind_param(5, "f", PG_BOOL);
		$make_hwh_org->execute()
		    or die "Couldn't execute statement: " . $make_hwh_org->errstr;
		($hwh_org_id) = $make_hwh_org->fetchrow();
		print " --- Inserted new hwh network, ID id $hwh_org_id\n";
		$make_hwh_org->finish;
	}
	else{
		#The HWH org does exist, now we just need to get its ID
		my $find_hwh_org = $db_conn->prepare("SELECT id FROM network.organization WHERE network_name = ? AND is_customer = FALSE")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$find_hwh_org->bind_param(1, $hardware_network);
		$find_hwh_org->execute()
		    or die "Couldn't execute statement: " . $find_hwh_org->errstr;
		($hwh_org_id) = $find_hwh_org->fetchrow();
		print " --- Found existing hwh network, ID is $hwh_org_id\n";
		$find_hwh_org->finish;
	}
	#Now that we know the HWH org, find out if the HWH exists
	my $hwh_exists = $db_conn->prepare("SELECT COUNT(*) FROM network.server WHERE organization = ? AND hardware_host IS NULL AND hostname = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$hwh_exists->bind_param(1, $hwh_org_id);
	$hwh_exists->bind_param(2, $hardware_hostname);
	$hwh_exists->execute()
	    or die "Couldn't execute statement: " . $hwh_exists->errstr;
	my ($hwh_count) = $hwh_exists->fetchrow();
	$hwh_exists->finish;

	$hwh_id = -1;
	print " --- Found $hwh_count instances of hardware host\n";
	if ($hwh_count == 0){
		#Hardware host doesn't exist, we have to insert it
		my $hwh_insert = $db_conn->prepare("INSERT INTO network.server (hostname, organization) VALUES (?, ?) RETURNING id")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$hwh_insert->bind_param(1, $hardware_hostname);
		$hwh_insert->bind_param(2, $hwh_org_id);
		$hwh_insert->execute()
		    or die "Couldn't execute statement: " . $hwh_insert->errstr;
		($hwh_id) = $hwh_insert->fetchrow();
		print " --- Inserted new hwh node, ID is $hwh_id\n";
		$hwh_insert->finish;
	}
	else{
		my $hwh_find = $db_conn->prepare("SELECT id FROM network.server WHERE hostname = ? AND organization = ? AND hardware_host IS NULL")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$hwh_find->bind_param(1, $hardware_hostname);
		$hwh_find->bind_param(2, $hwh_org_id);
		$hwh_find->execute()
		    or die "Couldn't execute statement: " . $hwh_find->errstr;
		($hwh_id) = $hwh_find->fetchrow();
		print " --- Found existing hwh node, ID is $hwh_id\n";
		$hwh_find->finish;
	}

	#Now that we have the HWH id, find out the gateway settings (gateway host, gateway IP)
	print " --- Determining gateway hardware host and IP address settings\n";
	my $get_gw_settings = $db_conn->prepare("SELECT gateway_hwh, gateway_ip FROM network.hardware_hosts WHERE id = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$get_gw_settings->bind_param(1, $hwh_id, SQL_INTEGER);
	$get_gw_settings->execute()
	    or die "Couldn't execute statement: " . $get_gw_settings->errstr;
	my ($gw_hwh, $gw_ip) = $get_gw_settings->fetchrow();
	$get_gw_settings->finish;

	if ($gw_hwh && $gw_ip){
		$gw_ip = @{[ split(/\//, $gw_ip) ]}[0];
		print " --- Gateway hardware host ID is $gw_hwh and IP is $gw_ip\n";
		my $get_gw_hostname = $db_conn->prepare("SELECT s.hostname, o.network_name FROM network.server AS s, network.organization AS o WHERE s.organization = o.id AND s.id = ?")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$get_gw_hostname->bind_param(1, $gw_hwh, SQL_INTEGER);
		$get_gw_hostname->execute()
		    or die "Couldn't execute statement: " . $get_gw_hostname->errstr;
		my ($gw_hostname, $gw_network_name) = $get_gw_hostname->fetchrow();
		$get_gw_hostname->finish;

		$gateway_hostname = $gw_hostname . "." . $gw_network_name;
		$hwgateway = $gw_ip;
		print " --- Gateway hardware hostname is $gateway_hostname\n";
	}
	else {
		#Pedantically unset the hostname and IP, since we're either dealing with the gateway itself
		#Or some other configuration
		print " --- No gateway hardware host/IP detected\n";
		$gateway_hostname = '';
		$hwgateway = '';
	}
}

sub set_org_nx_key{
	my ($xpc) = @_;
	my $db_st = $db_conn->prepare("UPDATE network.organization SET nxkey=? WHERE id=?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;	
	my $sep = $/;
	local $/=undef;
	open NXKEY, "$c4_root/cache/$short_name/Desktop/result/default.id_dsa.key";
	binmode NXKEY;
	my $nxkey = <NXKEY>;
	close NXKEY;
	local $/ = $sep;
	$db_st->bind_param(1, $nxkey);
	$db_st->bind_param(2, $org_id, SQL_INTEGER);
	my $res = $db_st->execute()
	    or die "Couldn't execute statement: " . $db_st->errstr;
	$db_st->finish;
}

sub backup_configuration{
    if (exists $capabilities{"Duplicity"}) {
	#Copying the key into every container
	print " --- Copying the backup key into every containers authorized_keys file\n";
        my $backup_key = ssh( "apollo.$org_domain", "cat /var/lib/backup/.ssh/id_rsa.pub" );
	chomp($backup_key);

        foreach my $org ( @container_list ){
	    my $host = $org.".".$org_domain;	    
	    ssh( $host, "echo '$backup_key' >> /root/.ssh/authorized_keys" );
	    print " --- Copied backup key on " . $host . "\n";
        }

	# Get GPG private key.
	my $gpg_backup_private_key = ssh("apollo.$org_domain","su - -c 'gpg -a --export-secret-keys backup\@$org_domain' backup");
	chomp($gpg_backup_private_key);
	my $gpg_backup_private_file = "$c4_root/certs/$short_name/backup.$org_domain\_private_gpg.key";
	
	# Write GPG private key to file.
	open (MYFILE, ">>$gpg_backup_private_file");
	print MYFILE "$gpg_backup_private_key";
	close (MYFILE);

	# Inserting GPG private key into database.
	print " --- Inserting GPG private key into database.\n";
	my $insert_gpg_key = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES (?, ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	my @exec_params = ($org_id, $gpg_backup_private_file, $gpg_backup_private_key);
	$insert_gpg_key->execute(@exec_params)
	    or die "Couldn't execute statement: " . $insert_gpg_key->errstr;
	$insert_gpg_key->finish;

	#Inserting backup config record into database.
	print " --- Inserting backup config record into database.\n";
	my $backup_ins_query = $db_conn->prepare("INSERT INTO network.backup_config (organization, profile_id, name, frequency, time, target_url, enabled) VALUES (?, '1', 'Primary Backup', '1 day(s)', '22:00',  ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$backup_ins_query->bind_param(1, $org_id, SQL_INTEGER);
	$backup_ins_query->bind_param(2, $backup_target_url);
	$backup_ins_query->bind_param(3, "f", PG_BOOL);
	
	$backup_ins_query->execute()
	    or die "Couldn't execute statement: " . $backup_ins_query->errstr;
	$backup_ins_query->finish;
    }
    elsif (exists $capabilities{"Amanda"}) {
        #Copying the key into every container
	print " --- Copying the amandabackup key into every containers authorized_keys file\n";
        my $amandabackup_key = ssh( "chaos.$org_domain", "cat /var/lib/amanda/.ssh/id_rsa.pub");
	chomp($amandabackup_key);

        foreach my $org ( @container_list ){
	    my $host = $org.".".$org_domain;	    
	    ssh( $host, "echo '$amandabackup_key' >> /root/.ssh/authorized_keys");           
	    print " --- Copied amandabackup key on " . $host . "\n";
        }
	
        #Including line for new organization into the backup server
	print " --- Configuring Backup server: " . $backup_server . "\n";

	ssh( $backup_server, "echo chaos.$org_domain root amindexd amidxtaped >> ~/.amandahosts", "backup"); # optional username
	ssh( $backup_server, "echo  hera.$org_domain root amindexd amidxtaped >> ~/.amandahosts", "backup");
	ssh( $backup_server, "chmod 700 ~/.amandahosts", "backup");

	my @backup_column1 = ("chaos", "chaos", "hera");
	my @backup_column2 = ("/home", "/tmp/dumps", "/var");
	my @backup_column3 = ("comp-user-tar", "comp-user-dumptar", "comp-user-tar");

	for (my $i=0; $i < scalar @backup_column1; $i++){	    
	    #Inserting values into the database
	    print " --- Inserting values into database.\n";
	    my $backup_ins_query = $db_conn->prepare("INSERT INTO network.backup (organization, hostname, network_name, location, type) VALUES (?, ?, ?, ?, ?)")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	    my @exec_params = ($org_id, $backup_column1[$i], $org_domain, $backup_column2[$i], $backup_column3[$i]);
	    $backup_ins_query->execute(@exec_params)
		or die "Couldn't execute statement: " . $backup_ins_query->errstr;
	    $backup_ins_query->finish;
	}
    }
}

sub create_first_user{
	my ($xpc) = @_;

        if($previous_org_status eq 'ARCHIVED'){
		print " --- Blanking out email_domain and network_name for previous organization with id $previous_org_id\n";
	        my $blank_out_domain_query = $db_conn->prepare("UPDATE network.organization SET email_domain='', network_name='' WHERE id=?")
        	        or die "Couldn't prepare statement: " . $db_conn->errstr;
	        my @exec_params = ($previous_org_id);
        	$blank_out_domain_query->execute(@exec_params)
                	or die "Couldn't execute statement: " . $blank_out_domain_query->errstr;
	        $blank_out_domain_query->finish;
		
		print " -- Copying eseri.users from previous org with id = $previous_org_id\n";
                my $restore_users_query = $db_conn->prepare("UPDATE network.eseri_user SET organization = ? WHERE organization = ?")
                        or die "Couldn't prepare statement: " . $db_conn->errstr;
                @exec_params = ($org_id, $previous_org_id);
                $restore_users_query->execute(@exec_params)
                        or die "Couldn't execute statement: " . $restore_users_query->errstr;
                $restore_users_query->finish;

                print " -- Copying vault.passwords from previous org with id = $previous_org_id\n";
                my $restore_passwords_query = $db_conn->prepare("UPDATE vault.passwords SET organization = ? WHERE organization = ?")
                        or die "Couldn't prepare statement: " . $db_conn->errstr;
                $restore_passwords_query->execute(@exec_params)
                        or die "Couldn't execute statement: " . $restore_passwords_query->errstr;
                $restore_passwords_query->finish;
        }	
	else{	
		print " -- Preparing XML RPC call to create first user \n";
	        my $user = $xpc->findvalue('/c4:config/manager_username');
        	my $org = $email_domain;
	        my $fname = $xpc->findvalue('/c4:config/manager_firstname');
        	my $lname = $xpc->findvalue('/c4:config/manager_lastname');
	        my $email = $xpc->findvalue('/c4:config/manager_external_email');
		print " --   user $user $org_id $org $fname $lname $email \n";

		my $client = RPC::XML::Client->new($C3ADDRESS);
		my $rcode = $?;
		if ($rcode == 0){
			print " -- Created client for address: $C3ADDRESS\n";
		} else {
			print "ERROR: xmrpc new to $C3ADDRESS failed \n";
			exit(1);
		}
		my $response = $client->send_request("net.eseri.createNewUser", $user, $user, $org, $fname, $lname, $email, "full");
		$rcode = $?;
		if ($rcode == 0){
			print " -- Received response from $C3ADDRESS " . $response->value()->{'Reason'} . "\n";
			print " -- Response: " . $response->as_string() . "\n";
		} else {
			print "ERROR: xmrpc send to $C3ADDRESS failed \n";
			exit(1);
                }
		# print ref $response ? join(', ', @{$response->value}) : "Error: xmrpc response $response \n";
		# Not an ARRAY reference

		my $c3Done = 0;
		my $loop_count = 0;
		while( $c3Done == 0) {
			$loop_count += 1;
			sleep( 4 * 60);
			my $get_status = $db_conn->prepare("SELECT status FROM network.eseri_user WHERE username = ? AND organization = ?")
				or die "Couldn't prepare statement: " . $db_conn->errstr;
			$get_status->bind_param(1, $user);
			$get_status->bind_param(2, $org_id, SQL_INTEGER);
			$get_status->execute()
				or die "Couldn't execute statement: " . $get_status->errstr;
			my ( $user_status) = $get_status->fetchrow();
			$get_status->finish;
			print " -- C3 first user status $user_status\n";

                	if ($user_status eq "ACTIVE"){
				$c3Done = 1;
				print " -- C3 first user done $loop_count\n";
			}

			if( $loop_count == 6){
				print " -- C3 first user taking too long\n";
				exit(1);
			}
		}
	}
}

# Just put a ssh key in Hera.
sub cloud_email_ssh_key{
	print " -- Adding chaos key to hera to disable Junk mail login in Evolution\n";
        my $chaos_key = ssh( "chaos.$org_domain", "cat /root/.ssh/id_rsa.pub");

	ssh( "hera.$org_domain", "echo '$chaos_key' >> /root/.ssh/authorized_keys ");
}

sub firewallproxy_config_defaults{
    print " -- Setting default external names for apps with external access enabled.\n";
    my $set_fpc_defaults = $db_conn->prepare("UPDATE packages.organizationcapabilities SET external_name = LOWER(a.name) FROM packages.capabilities AS a WHERE organization = ? and capability=a.capid AND a.external_access = 't'")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $set_fpc_defaults->bind_param(1, $org_id, SQL_INTEGER);
    $set_fpc_defaults->execute()
	or die "Couldn't execute statement: " . $set_fpc_defaults->errstr;
    $set_fpc_defaults->finish;
    print " -- Calling firewallproxy_config at C4.\n";
    # Default list of capabilities available externally
    my @fpc_capability = ('IMAP', 'SMTP', 'Vtiger', 'Timesheet', 'SOGo');
    my @fpc_external_name = ('imap', 'smtp', 'vtiger', 'timesheet', 'webmail');
    my @fpc_ssl = ('f', 'f', 'f', 'f', 'f');
    `./firewallproxy_config.pl --network_name "$org_domain" --capability "@fpc_capability" --external_name "@fpc_external_name" --ssl "@fpc_ssl" >> /var/log/c4/firewallproxy_config.log 2>&1`;
    if ($? != 0){
	print " -- Failed to perform firewallproxy_config.\n";
	exit 1;
    }	
}

sub cloudcapability_config_defaults{
    # This method needs to be executed after the firewallproxy_config_defaults has done its bit.
    my $caps = $db_conn->prepare("SELECT capid, name FROM packages.capabilities WHERE default_install = ? AND ccc_install = ?")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $caps->bind_param(1, "t", PG_BOOL);
    $caps->bind_param(2, "t", PG_BOOL);
    $caps->execute()
	or die "Couldn't execute statement: " . $caps->errstr;

    print " -- Capabilities to install and enable via cloud capability config scripts\n";
    my $capid='';
    while ($capid = $caps->fetchrow_arrayref){
	$capabilities{$capid->[1]} = 1;
	$capabilities_enable{$capid->[1]} = 1;
	print " --- " . $capid->[1] . "\n";
    }

    print " -- Configuring above listed apps via cloud capability config scripts.\n";
    my @ccc_capability = ();
    my @ccc_enable = ();
    for my $key (keys %capabilities_enable){
	push(@ccc_capability, $key);
	push(@ccc_enable, 't');
    }
    
    `./cloudcapability_config.pl --network_name "$org_domain" --capability "@ccc_capability" --enable "@ccc_enable" >> /var/log/c4/cloudcapability_config.log 2>&1`;
    if ($? != 0){
	print " -- Failed to perform cloudcapability_config.\n";
	exit 1;
    }	
}

sub enter_server{
	my ($host) = @_;
	#First, ensure that host isn't already in the database
	my $db_st = $db_conn->prepare("SELECT COUNT(*) FROM network.server WHERE hostname = ? AND organization = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$db_st->bind_param(1, $host);
	$db_st->bind_param(2, $org_id, SQL_INTEGER);
	$db_st->execute()
	    or die "Couldn't execute statement: " . $db_st->errstr;
	my ($server_count) = $db_st->fetchrow();
	$db_st->finish;
	if ($server_count == 0){
		$db_st = $db_conn->prepare("INSERT INTO network.server (hostname, hardware_host, organization, veid) VALUES (?, ?, ?, ?) RETURNING id")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$db_st->bind_param(1, $host);
		$db_st->bind_param(2, $hwh_id);
		$db_st->bind_param(3, $org_id);
		$db_st->bind_param(4, $veids{$host} + $veid_base);
		$db_st->execute()
		    or die "Couldn't execute statement: " . $db_st->errstr;
		my ($server_id) = $db_st->fetchrow();
		print " --- Added server $host on hardware host $hwh_id in organization $org_id with ID $server_id\n";
		$db_st->finish;
	}
}

sub determine_capabilities{
	my ($xpc) = @_;
	print " -- Determining capabilities\n";
	my $caps = $db_conn->prepare("SELECT capid, name FROM packages.capabilities WHERE default_install = ? AND ccc_install = ?")
	        or die "Couldn't prepare statement: " . $db_conn->errstr;
	$caps->bind_param(1, "t", PG_BOOL);
	$caps->bind_param(2, "f", PG_BOOL);
	$caps->execute()
	        or die "Couldn't execute statement: " . $caps->errstr;

	print " -- Capabilities to install and enable\n";
	my $capid='';
        while ($capid = $caps->fetchrow_arrayref){
		my $insert_organizationcapability = $db_conn->prepare("INSERT INTO packages.organizationcapabilities (organization, capability, enabled) VALUES (?,?,?)")
                        or die "Couldn't prepare statement: " . $db_conn->errstr;
                $insert_organizationcapability->bind_param(1, $org_id, SQL_INTEGER);
                $insert_organizationcapability->bind_param(2, $capid->[0], SQL_INTEGER);
                $insert_organizationcapability->bind_param(3, "t", PG_BOOL);		
		$insert_organizationcapability->execute()
			or die "Couldn't execute statement: " . $insert_organizationcapability->errstr;
		$capabilities{$capid->[1]} = 1;
		$capabilities_enable{$capid->[1]} = 1;
		print " --- " . $capid->[1] . "\n";
	}

	my $all_caps = $db_conn->prepare("SELECT name FROM packages.capabilities")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	$all_caps->execute()
                or die "Couldn't execute statement: " . $all_caps->errstr;
	my $ac='';
	while ($ac = $all_caps->fetchrow_arrayref){
		push (@all_capabilities, $ac->[0]);
	}	
}

sub determine_vps_list{
    print " -- Determining VPS list\n";

    # VPS List for VPS1_Create.
    # The the firewall container (3) controls the in/out of packets and comes before the dns container (2). This order only applies for VPS1_Create.
    push(@vps1_list, "3");
    push(@vps1_list, "2");
    
    # VPS List for VPS2_Create.
    # Normal asc order.
    (exists $capabilities{"Duplicity"}) ? (push(@vps2_list, "4")) : ();    
    push(@vps2_list, "10");
    push(@vps2_list, "11");
    push(@vps2_list, "30");
    (exists $capabilities{"Email"}) ? (push(@vps2_list, "31")) : ();
    push(@vps2_list, "32");
    (exists $capabilities{"Nuxeo"}) ? (push(@vps2_list, "33")) : ();
    (exists $capabilities{"WebConferencing"}) ? (push(@vps2_list, "34")) :();
    (exists $capabilities{"InstantMessaging"}) ? (push(@vps2_list, "35")) : ();
    (exists $capabilities{"Smartphone"}) ? (push(@vps2_list, "36")) : ();
    (exists $capabilities{"SOGo"}) ? (push(@vps2_list, "37")) : ();
    push(@vps2_list, "39");
    (exists $capabilities{"Desktop"}) ? (push(@vps2_list, "50")) : ();

    # Container List
    foreach my $veid ((@vps1_list, @vps2_list)){
        while ( my ($key, $value) = each %veids) {
	    if ($value eq $veid){
		push(@container_list, $key);
	    }
        }
    }
}

sub record_bridge{
	my ($xpc) = @_;
	print " -- Adding bridge name to record\n";
	my @contents;
	tie @contents, 'Tie::File', "$c4_root/cache/$short_name/Network/result/log.txt";
	my $bridge_name;
	foreach my $line (@contents){
		if ($line =~ m/^Bridge name is: (br[A-Z0-9]+)/m){
			$bridge_name = $1;
			last;
		}
	}
	unless ($bridge_name){
		print "ERROR: Could not determine bridge name\n";
		exit(1);
	}
	#Now, add bridge name to the database
	my $db_st = $db_conn->prepare("UPDATE network.organization SET bridge = ?, network = ? WHERE id = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$db_st->bind_param(1, $bridge_name);
	$db_st->bind_param(2, $org_network);
	$db_st->bind_param(3, $org_id, SQL_INTEGER);
	my $ret = $db_st->execute()
	    or die "Couldn't execute statement: " . $db_st->errstr;
	$db_st->finish;
	print " -- Bridge recorded as $bridge_name\n";
	$bridge = $bridge_name;
}

sub choose_network{
	my ($xpc) = @_;
	print " -- Determining private network, public IP settings\n";
	my $get_ip = $db_conn->prepare("SELECT address, netmask FROM network.address_pool WHERE organization = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$get_ip->bind_param(1, $org_id, SQL_INTEGER);
	$get_ip->execute()
	    or die "Couldn't execute statement: " . $get_ip->errstr;
	($wan_ip, $wan_netmask) = $get_ip->fetchrow_array();
	$get_ip->finish;

	$wan_netmask =~ s|/32$||; #Trim trailing /32 from the netmask
	unless ($wan_ip){
		print " -- ERROR: Public IP not set correctly\n";
		exit 1;
	}    

	my $db_st = $db_conn->prepare("SELECT id, network, status FROM network.organization WHERE (network_name = ? or email_domain = ?) and status = 'ARCHIVED' ORDER BY creation DESC LIMIT 1")
                or die "Couldn't prepare statement: " . $db_conn->errstr;
        $db_st->bind_param(1, $org_domain);
	$db_st->bind_param(2, $email_domain);
        $db_st->execute()
                or die "Couldn't execute statement: " . $db_st->errstr;
        ($previous_org_id, $previous_org_network, $previous_org_status) = $db_st->fetchrow_array();  #zzzz
        $db_st->finish;

	unless($previous_org_status){
		$previous_org_status = "NULL";
                ($cidr_network) = $db_conn->selectrow_array("SELECT network FROM network.free_networks ORDER BY network ASC LIMIT 1");
                unless ($cidr_network){
                        print " -- ERROR: No more private networks available\n";
                        exit 1;
                }
	}
	elsif($previous_org_status eq 'ARCHIVED'){
		$cidr_network = $previous_org_network;
	}

	#Trim network value
	$org_network = $cidr_network;
	$org_network =~ s|\.0/24$||;
	print " -- Network: $org_network\n -- Wan IP: $wan_ip/$wan_netmask\n";
}

sub choose_veid{
	my ($xpc) = @_;
	print " -- Determining base VEID\n";
	my ($max_veid) = $db_conn->selectrow_array("SELECT MAX(veid) FROM network.server");
# zzz You should check $sth->err afterwards (or use the RaiseError attribute) to discover if the data is complete or was truncated due to an error.

	$veid_base = (floor($max_veid / 500) * 500) + 500;
	print " -- Base VEID is now $veid_base\n";
}

sub read_db{
	my ($xpc) = @_;
	print " -- Loading values from database\n";
	if ($org_id == -1) {
	    die "Org ID not defined";
	}
	my $get_data = $db_conn->prepare("SELECT full_name, short_name, network_name, email_domain, status FROM network.organization WHERE id = ?")
		or die "Couldn't prepare statement: " . $db_conn->errstr;
	$get_data->bind_param(1, $org_id, SQL_INTEGER);
	$get_data->execute()
		or die "Couldn't execute statement: " . $get_data->errstr;
	($org_full, $short_name, $org_domain, $email_domain, $org_status) = $get_data->fetchrow_array();

	unless($org_status){
		die "Org $org_id does not have a status";
	}
	if($org_status ne "PROCESSING"){
		die "Org $org_id does not have PROCESSING status";
	}
	print " -- Data loaded: $org_id: $org_full ($short_name), $org_domain / $email_domain\n for $system_anchor_domain";

	# Also, set the vz base path and short_domain.
	$vz_base_path = "/var/lib/vz-$short_name";
	$short_domain = @{ [ split(/\.$system_anchor_domain/, $org_domain) ]}[0];

	# Also get backup server from database.
        my $db_st = $db_conn->prepare("SELECT backup_server FROM network.organization where id = ?")
	        or die "Couldn't prepare statement: " . $db_conn->errstr;
        $db_st->bind_param(1, $org_id);
        $db_st->execute()
        	or die "Couldn't execute statement: " . $db_st->errstr;
	($backup_server) = $db_st->fetchrow();
        $db_st->finish;

	$backup_server .= ".$system_anchor_domain";
	$backup_target_url="sftp://backup-$short_domain\@$backup_server/www/profile1";

	$db_st = $db_conn->prepare("SELECT address FROM network.address_pool WHERE organization = ?")
	        or die "Couldn't prepare statement: " . $db_conn->errstr;
        $db_st->bind_param(1, 1, SQL_INTEGER);
        $db_st->execute()
        	or die "Couldn't execute statement: " . $db_st->errstr;
	($system_anchor_ip) = $db_st->fetchrow();
        $db_st->finish;
}

sub make_cleanup{
	my ($xpc) = @_;
	print " -- Preparing to make cleanup script\n";

	my $res = Net::DNS::Resolver->new;
	my $hardware_host_ip = "lookupo failed";
	my $query = $res->search( $hardware_host);
	if ($query) {
	    foreach my $rr ($query->answer) {
		next unless $rr->type eq "A";
		print $rr->address, "\n";
		$hardware_host_ip = $rr->address;
	    }
	} else {
	    warn "query failed: ", $res->errorstring, "\n";
	}
	`mkdir -p ./cleanup`;
	my $cleanupScrName = "./cleanup/clean${short_name}.sh";
	copy("cleanup_parms.template", $cleanupScrName);
	chmod 0755, $cleanupScrName;
	print " -- Template copied\n";
	my @contents;
	tie @contents, 'Tie::File', $cleanupScrName;
	for (@contents) {   
		s/\[-VEID_BASE-\]/$veid_base/;
		s/\[-SHORT_NAME-\]/$short_name/;
		s/\[-NETWORK_NAME-\]/$org_domain/;
		s/\[-SHORT_DOMAIN-\]/$short_domain/;
		s/\[-NETWORK-\]/$org_network/;
		s/\[-IP-\]/$wan_ip/;	
		s/\[-VZ_BASE_PATH-\]/$vz_base_path/;
		s/\[-BRIDGE-\]/br$org_id/;
		s/\[-HWHOST-\]/$hardware_hostname/;
		s/\[-HWHSTIP-\]/$hardware_host_ip/;
		s/\[-BACKUP_SERVER-\]/$backup_server/
        };
	untie @contents;
	print " -- Made cleanup file\n";
}	

sub update_cleanup{
        my ($xpc) = @_;
        print " -- Preparing to update cleanup script\n";

	# this needs to be the same var as in sub make_cleanup. add a global or rewrite c4 OO?
	my $cleanupScrName = "./cleanup/clean${short_name}.sh";
        my @contents;
	tie @contents, 'Tie::File', $cleanupScrName;
        for (@contents) {
                s/BRIDGE=br$org_id/BRIDGE=$bridge/;
        };
        untie @contents;
        print " -- Made cleanup file\n";
}


sub update_free_space{
	my ($xpc) = @_;
	print " -- Updating database for free space on \n";
	my $hardware_host = $xpc->findvalue('/c4:config/hardware_host');
	$hardware_host =~ m/^([^\.]+)\./;
	my $hw_hostname = $1;
	my $volgroups_out = ssh( $hardware_host, "vgs --noheadings --nosuffix --units g --separator ','");

	my @volgroups = split(/\n/, $volgroups_out);
	my $max_free_space = 0;
	#Look at all volume groups, only record volume group with max free space
	#Ideally, only one volume group per-system, once we start building machines with RAID5 from day 1
	foreach my $group (@volgroups){
		my @data = split(/,/, $group);
		my $free_space = $data[6];
		if ($free_space > $max_free_space){
			$max_free_space = $free_space;
		}
	}
	$max_free_space = floor($max_free_space);
	print " -- Max free space from all volume groups is $max_free_space GiB\n";
	my $update_free_space = $db_conn->prepare("UPDATE network.hardware_hosts SET disk_free_in_gib = ? WHERE id = (SELECT id FROM network.server WHERE hostname = ? AND id IN (SELECT id FROM network.hardware_hosts))")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$update_free_space->bind_param(1, $max_free_space);
	$update_free_space->bind_param(2, $hw_hostname);
	$update_free_space->execute()
	    or die "Couldn't execute statement: " . $update_free_space->errstr;
	$update_free_space->finish;
	print " -- Updated free space on $hw_hostname\n";
}

#Threading variables
my $incomplete_processing_queue = new Thread::Queue();
my $completed_processing_queue = new Thread::Queue();
my @threaded_jobs = ();
my $completion_tracker = 0;
my @thread_array = ();
for (my $i = 0; $i < $number_of_threads; $i++){
	my $thread = threads->create(\&processFunction);
	push(@thread_array, $thread);
	$thread->detach();
}

#Thread subroutine
sub processFunction{
	while(1){
		my $process = $incomplete_processing_queue->dequeue();
		if ($process->{'name'} eq "TERMINATE_THREADS"){
			close(STDOUT);
			return;
		}
		`$process->{'command'}`;
		if ($? != 0){
			my $failed_name :shared = "FAIL";
			$completed_processing_queue->enqueue($failed_name);
		}
		else{ 
			my $completed_name :shared = $process->{'name'};
			$completed_processing_queue->enqueue($completed_name);
		}
	}
}

#Utility function to "fill in the blanks" for things like short_domain
#Now used to return values that aren't placed in the XML file any more
sub get_c4_inferred_value{
	my ( $c4_ref, $arg ) = @_;
	if ($arg eq 'system_anchor_domain'){
   	        return $system_anchor_domain;
	}
	elsif ($arg eq 'system_anchor_ip'){
   	        return $system_anchor_ip;
	}
	elsif ($arg eq 'short_domain'){
   	        return $short_domain;
	}
	elsif ($arg eq 'network'){
		return $org_network;
	}
	elsif ($arg eq 'wan_ip'){
		return $wan_ip;
	}
	elsif ($arg eq 'wan_netmask'){
		return $wan_netmask;
	}
	elsif ($arg eq 'shortname'){
		return $short_name;
	}
	elsif ($arg eq 'longname'){
		return $org_full;
	}
	elsif ($arg eq 'vz_base_path'){
		return $vz_base_path;
	}
	elsif ($arg eq 'veid_base'){
		return $veid_base;
	}
	elsif ($arg eq 'domain'){
		return $org_domain;
	}
	elsif ($arg eq 'bridge'){
		return $bridge;
	}
	elsif ($arg eq 'email_domain'){
		return $email_domain;
	}
	elsif ($arg eq 'hwhgateway'){
		return $hwgateway;
	}
	elsif ($arg eq 'lc_shortname'){
		return lc($short_name);
	}
        elsif ($arg eq 'hardware_hostname'){
		return $hardware_hostname;
        }
	elsif ($arg eq 'backup_server'){
		return $backup_server;
	}
	elsif ($arg eq 'volume_size'){
		return $cloud_volume_size;
	}
	elsif ($arg eq 'vps1_list'){
	    return join(' ', @vps1_list);
	}
	elsif ($arg eq 'vps2_list'){
	    return join(' ', @vps2_list);
	}
	elsif ($arg eq 'vps_list'){
	    return join(' ', (@vps1_list, @vps2_list));
	}
	elsif ($arg eq 'container_list'){
	    return join(' ', @container_list);
	}
	elsif ($arg eq 'boot_action'){
	    return "reboot";
	}
	elsif ($arg eq 'backup_target_url'){
	    return $backup_target_url;	    
	}
	return '';
}

#Certificate cache functions
sub createRootCertificate{
	my ($xpc) = @_;
	
	my $org = $short_name;
	my $state = $xpc->findvalue('/c4:config/province');
	my $country = $xpc->findvalue('/c4:config/country');
	my $email = 'hostmaster@'.$system_anchor_domain;
	my $full_org_name = $org_full;
        my $query = "SELECT COUNT(*) FROM vault.certificate_details WHERE organization=?";
        my $query_statement = $db_conn->prepare($query)
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
        my @execution_params = ($org_id);
        my $rv = $query_statement->execute(@execution_params)
	    or die "Couldn't execute statement: " . $query_statement->errstr;
        my $count = $query_statement->fetchrow_array;
	$query_statement->finish;
        if ($count > 0){
		return;
        }
        #This will be the passphrase we use for the Root CA
        my $password = &getPassword('', 'Root CA Passphrase', "system");
        #Remember where we were run from so we can go back once the Root CA is made
        my $cwd = &Cwd::cwd();
        mkpath("$c4_root/certs/$org/signedcerts");
        mkpath("$c4_root/certs/$org/private");
        chdir("$c4_root/certs/$org");
        open (SERIAL, ">serial");
        print SERIAL "01";
        close (SERIAL);
        #Touch equivalent
        open (INDEX, ">index.txt") && close(INDEX);
	# To have 2 certs with same commonName - in case of XMPP.
        open (INDEX_ATTR, ">index.txt.attr");
        print INDEX_ATTR "unique_subject = no";
        close (INDEX_ATTR);	
        open (CACONFIG, ">caconfig.txt");
        print CACONFIG <<"EOF";
#
# OpenSSL configuration file. 
#

HOME                    = .
RANDFILE                = \$ENV::HOME/.rnd

[ ca ]
default_ca      = local_ca
##
##
## Default location of directories and files needed to generate certificates.
##
[ local_ca ]
dir                     = . 
certificate             = \$dir/cacert.pem
database                = \$dir/index.txt
new_certs_dir           = \$dir/signedcerts
private_key             = \$dir/private/cakey.pem
serial                  = \$dir/serial
#
#
# Default expiration and encryption policies for certificates.
#
default_crl_days        = 365
default_days            = 1825
default_md              = sha256

policy                  = local_ca_policy
x509_extensions         = local_ca_extensions

RANDFILE                = \$dir/private/.rand

#       
#
# Default policy to use when generating server certificates.  The following
# fields must be defined in the server certificate.
#
[ local_ca_policy ]
commonName              = supplied
stateOrProvinceName     = match
countryName             = match
emailAddress            = optional
organizationName        = match
organizationalUnitName  = optional
#       
#
# x509 extensions to use when generating server certificates.
#
[ local_ca_extensions ]
basicConstraints        = CA:false
nsCertType              = server
#
#
# The default root certificate generation policy.
#
[ req ]
default_bits            = 4096
default_keyfile         = ./private/cakey.pem
default_md              = sha256
#
prompt                  = no
distinguished_name      = root_ca_distinguished_name
x509_extensions         = root_ca_extensions
#
#
# Root Certificate Authority distinguished name.  Change these fields to match
# your local environment!
#
[ root_ca_distinguished_name ]
commonName              = $org Internal Root Certificate Authority
stateOrProvinceName     = $state
countryName             = $country
emailAddress            = $email
organizationName        = $full_org_name
#
[ root_ca_extensions ]
basicConstraints        = CA:true
EOF

        close(CACONFIG);
        `openssl req -x509 -newkey rsa:4096 -out cacert.pem -outform PEM -days 1825 -passout "pass:$password" -config ./caconfig.txt 2>&1 > /dev/null`;
        `openssl dsaparam -out dsaparam.pem 4096 2>&1 > /dev/null`;

	sub wanted{
		return if -d $_;
		my $contents = read_file($_);
		my $file_ins_query = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES (?, ?, ?)")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		my @exec_params = ($org_id, "$c4_root/certs/$short_name/" . $File::Find::name, $contents);
		$file_ins_query->execute(@exec_params)
		    or die "Couldn't execute statement: " . $file_ins_query->errstr;
		$file_ins_query->finish;
	};
	find(\&wanted, ".");	
	#Go back to whence we came, otherwise bad things happen next time we chdir
        chdir($cwd);

        $query = "INSERT INTO vault.certificate_details (organization, state, country, email, name) VALUES (?, ?, ?, ?, ?)";
        $query_statement = $db_conn->prepare($query)
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
        @execution_params = ($org_id, $state, $country, $email, $full_org_name);
        $rv = $query_statement->execute(@execution_params)
	    or die "Couldn't execute statement: " . $query_statement->errstr;
        $query_statement->finish;
	`mkdir -p $c4_root/cache/$org/CA/result/`;
	`cp $c4_root/certs/$org/cacert.pem $c4_root/cache/$org/CA/result/`;
	
        return;
}

sub getCertificate{
        my ($org, $host, $type) = @_;
        my $search_key = ""; my $search_crt = "";
        #If we've already made the cert, just find it and retrieve it
        if (-d "$c4_root/certs/$org"){
                #Are we trying to retrieve the root certificate (for /usr/share/ca-certificates)?
                if ($host eq "ROOT"){
                        if (-f "$c4_root/certs/$org/cacert.pem"){
                                my $cert = read_file("$c4_root/certs/$org/cacert.pem");
				my @ret = ($cert);
                                return \@ret;
                        }
                        else{
				my $array_ref = $db_conn->selectall_arrayref("SELECT contents FROM vault.certificate_files WHERE organization = ? AND file = ?", {}, $org_id);
# zzz You should check $sth->err afterwards (or use the RaiseError attribute) to discover if the data is complete or was truncated due to an error.
				return $array_ref->[0];
                        }

                }
                if ($type eq "RSA"){
                        $search_key = "$c4_root/certs/$org/${host}_key.pem";
                        $search_crt = "$c4_root/certs/$org/${host}_crt.pem";
                }
                else{
                        $search_key = "$c4_root/certs/$org/${host}_dsa_key.pem";
                        $search_crt = "$c4_root/certs/$org/${host}_dsa_crt.pem";
                }
                if (-f "$search_key" && -f "$search_crt"){
                        my $res_key = read_file($search_key);
                        my $res_cert = read_file($search_crt);
			my @ret = ($res_key, $res_cert);
			# print " -- FOUND: key and crt in files $search_key $search_crt =====================\n";
			return \@ret;
		}
        }
	else {
		if ($type eq "RSA"){
                        $search_key = "$c4_root/certs/$org/${host}_key.pem";
                        $search_crt = "$c4_root/certs/$org/${host}_crt.pem";
                }
                else{
                        $search_key = "$c4_root/certs/$org/${host}_dsa_key.pem";
                        $search_crt = "$c4_root/certs/$org/${host}_dsa_crt.pem";
                }
		my $array_ref = $db_conn->selectall_arrayref("SELECT contents FROM vault.certificate_files WHERE organization = ? AND file = ?", {}, ($org_id, $search_key));
# zzz You should check $sth->err afterwards (or use the RaiseError attribute) to discover if the data is complete or was truncated due to an error.
		if ( scalar @{ $array_ref } == 1 ){
			my $key = $array_ref->[0]->[0];
			my $cert = $db_conn->selectall_arrayref("SELECT contents FROM vault.certificate_files WHERE organization = ? and file = ?", {}, ($org_id, $search_crt));
# zzz You should check $sth->err afterwards (or use the RaiseError attribute) to discover if the data is complete or was truncated due to an error.
			my @ret = ($key, $cert);
			# print " -- FOUND: key and crt in vault $search_key $search_crt =====================\n";
			return \@ret;
		}
	}

        my $query = "SELECT state, country, email, name FROM vault.certificate_details WHERE organization=?";
        my $query_statement1 = $db_conn->prepare($query)
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
        $query_statement1->bind_param(1, $org_id);
	$query_statement1->execute()
       	    or die "Couldn't execute statement: " . $query_statement1->errstr;
        my ($state, $country, $email, $name) = $query_statement1->fetchrow_array;
        $query_statement1->finish;

        $query = "SELECT password FROM vault.passwords WHERE organization=? AND entity='Root CA Passphrase'";
        my $query_statement2 = $db_conn->prepare($query)
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	if($previous_org_status eq 'ARCHIVED'){
		$query_statement2->bind_param(1, $previous_org_id);	
        }
	else{
		$query_statement2->bind_param(1, $org_id);
	}
	$query_statement2->execute() 
	    or die "Couldn't execute statement: " . $query_statement2->errstr;
        my ($password) = $query_statement2->fetchrow_array;
        $query_statement2->finish;

        #Remember where we were
        my $cwd = &Cwd::cwd();
        chdir("$c4_root/certs/$org");
        open(CONFFILE, ">$host.cnf");
        print CONFFILE <<"EOF";
#
# $host.cnf
#

[ req ]
prompt                  = no
distinguished_name      = $host

[ $host ]
commonName              = $host
stateOrProvinceName     = $state
countryName             = $country
emailAddress            = $email
organizationName        = $name
organizationalUnitName  = IT Department
EOF

        close(CONFFILE);
        my $keyfilename = ""; my $crtfilename = "";
        my $key = "", my $crt = "";
	if ($type eq "RSA"){
                # Set 1024 key size for dkim, since bind9 does not accept > 255 characters for a TXT pointer.
	        if ($host =~ m/^dkim./){
		    `openssl req -newkey rsa:1024 -nodes -keyout ${host}_key.pem -keyform PEM -out ${host}_req.pem -outform PEM -config ./${host}.cnf`;
		}
		else{
		    `openssl req -newkey rsa:4096 -nodes -keyout ${host}_key.pem -keyform PEM -out ${host}_req.pem -outform PEM -config ./${host}.cnf`;
		}
                `openssl ca -batch -in ${host}_req.pem -out ${host}_crt.pem -config ./caconfig.txt -passin "pass:$password"`;
                unlink("${host}_req.pem");
                $keyfilename = "${host}_key.pem";
                $crtfilename = "${host}_crt.pem";
        }
        else{
                `openssl req -newkey dsa:dsaparam.pem -nodes -keyout ${host}_dsa_key.pem -keyform PEM -out ${host}_dsa_req.pem -outform PEM -config ./${host}.cnf`;
                `openssl ca -batch -in ${host}_dsa_req.pem -out ${host}_dsa_crt.pem -config ./caconfig.txt -passin "pass:$password"`;
                unlink("${host}_dsa_req.pem");
                $keyfilename = "${host}_dsa_key.pem";
                $crtfilename = "${host}_dsa_crt.pem";
        }
	my $key_contents = read_file($keyfilename);
	my $crt_contents = read_file($crtfilename);
	my $key_ins = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES (?, ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$key_ins->bind_param(1, $org_id);
	$key_ins->bind_param(2, "$c4_root/certs/$org/$keyfilename");
	$key_ins->bind_param(3, $key_contents);
	$key_ins->execute()
	    or die "Couldn't execute statement: " . $key_ins->errstr;
        $key_ins->finish;

	my $crt_ins = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES (?, ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$crt_ins->bind_param(1, $org_id);
	$crt_ins->bind_param(2, "$c4_root/certs/$org/$crtfilename");
	$crt_ins->bind_param(3, $crt_contents);
	$crt_ins->execute()
	    or die "Couldn't execute statement: " . $crt_ins->errstr;
        $crt_ins->finish;
	chdir($cwd);
	my @ret = ( $key_contents, $crt_contents );
	return \@ret;
}


#Replacement subroutine for old vault command
sub getPassword{
        my ($host, $entity, $type) = @_;
        my $db_st = $db_conn->prepare("SELECT password FROM vault.passwords WHERE organization = ? AND host = ? AND entity = ?")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	if($previous_org_status eq 'ARCHIVED'){
                $db_st->bind_param(1, $previous_org_id);
        }
        else{
		$db_st->bind_param(1, $org_id);
	}
	$db_st->bind_param(2, $host);
	$db_st->bind_param(3, $entity);
	$db_st->execute()
	    or die "Couldn't execute statement: " . $db_st->errstr;
        my @result_array = $db_st->fetchrow_array;
        $db_st->finish;

        my $password = "";
        if (scalar(@result_array) == 0){
                $password = &genPassword($type);
                $db_st = $db_conn->prepare("INSERT INTO vault.passwords (organization, host, entity, password) VALUES (?, ?, ?, ?)")
		    or die "Couldn't prepare statement: " . $db_conn->errstr;
		$db_st->bind_param(1, $org_id);
		$db_st->bind_param(2, $host);
		$db_st->bind_param(3, $entity);
		$db_st->bind_param(4, $password);
                $db_st->execute()
		    or die "Couldn't execute statement: " . $db_st->errstr;
		$db_st->finish;
        }
        else{
                $password = $result_array[0];
        }
        return $password;
}

#Password generation function
sub genPassword{
        my ($type) = @_;
        if ($type eq "system"){
                my @char_pool = split(" ", "a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"); 
		my $password = ""; 
		srand;
                for (my $i=0; $i < 25; $i++){
                        $password .= $char_pool[int(rand (scalar(@char_pool) - 1))];
                }
                return $password;
        }
        elsif ($type eq "user"){
                my @char_pool = ("a" .. "z");
                push (@char_pool, ("A" .. "Z"));
                push (@char_pool, (0 .. 9));
                my $password = "";
                srand;
                while ( ! ($password =~ m/[A-Z]/ && $password =~ m/[a-z]/ && $password =~ m/[0-9]/) ){
                        $password = "";
                        for (my $i=0; $i < 8; $i++){
                                $password .= $char_pool[int(rand (scalar(@char_pool) - 1))];
                        }
                }
                return $password;
        }
}

sub get_full_hostname{
    my ($host, $c4_ref, $method) = @_;
    my $full_hostname;
    if ($host eq "HWHOST"){
	$full_hostname = $c4_ref->findvalue('/c4:config/hardware_host');
    }
    elsif ($host eq "GATEWAYHOST"){
	$full_hostname = $gateway_hostname;
    }
    elsif ($host eq "BACKUPSERVER"){
	$full_hostname = $backup_server;
    }
    elsif ($host =~ m/SYSTEM_ANCHOR_DOMAIN/){
	$full_hostname = $host;
	$full_hostname =~ s/SYSTEM_ANCHOR_DOMAIN/$system_anchor_domain/g;
    }
    elsif ($host =~ m/^IP:/){
	$full_hostname = $org_network . '.' . @{[split(/:/, $host)]}[1];
	if ($method eq 'get_deploy_command'){
	    # Add zeus to network.server table
	    if ($full_hostname =~ m/\.2$/){
		&enter_server('zeus');
	    }
	}
    }
    elsif ($host =~ m/\./){
	$full_hostname = $host;
    }
    else {
	$full_hostname = $host . '.' . $org_domain;
	if ($method eq 'get_deploy_command'){	    
	    #We should enter this server into the database
	    &enter_server($host);
	}
    }
    return $full_hostname;
}

#Deploy script commandline generation routine
sub get_deploy_command{
	my ($block_ref, $c4_ref, $block_cmd_ref) = @_;
	# print " -- Creating FQDN of target host\n";
	my $host = $block_ref->findvalue('/c4:boot/host');
	my $name = $block_ref->findvalue( '/c4:boot/name' );
	my $command = "";
	my $display_command = "";
	my $deployment_file = "$c4_root/cache/$short_name/$name/result/deployment";
	my $full_hostname = get_full_hostname($host, $c4_ref, 'get_deploy_command');
	`ping -c 1 $full_hostname`;
	$command =         "ssh root\@$full_hostname \"bash /root/deploy$short_name/deploy.sh ";
	$display_command = "ssh root\@$full_hostname \"bash /root/deploy$short_name/deploy.sh ";
	`mkdir -p $c4_root/cache/$short_name/$name/result`;
	open (DEPLOY, ">$deployment_file") || die "Could not open deployment $deployment_file file for writing";
	# print " -- Writing capabilities to deployment file\n";
	print DEPLOY join(' ', @all_capabilities) . "\n";
	for my $cap (keys %capabilities){
		print DEPLOY "CAPABILITY:$cap\n";
	}
	for my $cap_e (keys %capabilities_enable){
                print DEPLOY "CAPABILITY_ENABLE:$cap_e\n";
        }
	# print " -- Adding deployment arguments\n";
	my @deploy_nodes = $block_ref->findnodes('/c4:boot/deploy/arg');
	foreach my $deploy_node (@deploy_nodes){
		my $arg = $deploy_node->textContent();
		my $arg_value = $c4_ref->findvalue( '/c4:config/' . $arg);
		if ( $arg_value eq '' ){
			$arg_value = &get_c4_inferred_value( $c4_ref, $arg );
		}
		if ( $arg_value eq '' ){
			print " -- ERROR: argument for $arg missing =====================\n";
		}
		print DEPLOY "PARAMETER:$arg:$arg_value\n";
	}

	my @password_nodes = $block_ref->findnodes('/c4:boot/passwords/password');
	PASSWORD: foreach my $password_node (@password_nodes){
		#Check to see if password is still needed
		my @cap_nodes = $password_node->getChildNodes();
		foreach my $cap (@cap_nodes) {
			last if $cap->getLocalName() eq "always";
			#Node must be a 'required' node now
			my $cap_name = $cap->textContent();
			next if exists $capabilities{$cap_name};
			print " -- Skipping password " . $block_ref->findvalue('@name', $password_node) . " because capability $cap_name is not in package\n";
			next PASSWORD;
		}
		my $name = $block_ref->findvalue('@name', $password_node);
		#Handle hardcoded passwords in the config XML
		if ($block_ref->findvalue('@value', $password_node)){
			my $pw = $block_ref->findvalue('@value', $password_node);
			print DEPLOY "PASSWORD:$name:$pw\n";
			next;
		}
		my $password_type = $block_ref->findvalue('@type', $password_node);
		if (! $password_type || $password_type eq '') { $password_type = "system" };
		my $password_host = $block_ref->findvalue('@host', $password_node);
		my $password_entity = $block_ref->findvalue('@entity', $password_node);
		print " -- Getting password for $password_entity at $password_host ($password_type) from Prime\n";
		my $password = &getPassword($password_host, $password_entity, $password_type);
		print DEPLOY "PASSWORD:$name:$password\n";
	}

	$command .=         " > /root/deploy$short_name/result/log.txt 2>&1\"";
	$display_command .= " > /root/deploy$short_name/result/log.txt 2>&1\"";
	
	print " -- Commandline is: $display_command\n";
	#Return value by setting ref we were passed
	$$block_cmd_ref = $command;
}

#Do post-processing
sub post_process{
	my ($block_ref, $c4_ref) = @_;
	my $host 		= $block_ref->findvalue('/c4:boot/host');
	my $name 		= $block_ref->findvalue('/c4:boot/name');
	my $full_hostname = get_full_hostname($host, $c4_ref, 'post_process');
#	my $commandline = "scp -r root\@$full_hostname:/root/deploy$short_name/result/ $c4_root/cache/$short_name/${name}/";
#	$commandline .= " && ssh root\@$full_hostname \"rm -rf /root/deploy$short_name/\"";
#	`$commandline`;

	scp( "root\@$full_hostname:/root/deploy$short_name/result/", "$c4_root/cache/$short_name/${name}/");
	`ssh root\@$full_hostname "rm -rf /root/deploy$short_name/"`;
}
#Prepare cache for deploy command
sub prepare_cache{
	my ($block_ref, $c4_ref ) = @_;
	my $name = $block_ref->findvalue( '/c4:boot/name' );
	my $host = $block_ref->findvalue( '/c4:boot/host' );
	my $domain = $org_domain;
	my $full_hostname = get_full_hostname($host, $c4_ref, 'prepare_cache');
	# print " -- Making cache directory\n";
	`mkdir -p $c4_root/cache/$short_name/$name`;
	# print " -- Populating cache from storage\n";
	`cp -R --dereference $c4_root/storage/${name}_Create/* $c4_root/cache/$short_name/${name}`;

	my @certificates = $block_ref->findnodes( '/c4:boot/certificates/cert' );
	foreach my $cert (@certificates){
		my $cert_host = $block_ref->findvalue( './@host', $cert);
		my $cert_type = $block_ref->findvalue( './@type', $cert);
		if ($cert_host ne "ROOT"){
			$cert_host .= '.' . $domain;
		}
		my $res = &getCertificate($short_name, $cert_host, $cert_type);
		if ($cert_host eq "ROOT"){
			write_file("$c4_root/cache/$short_name/${name}/archive/CA.crt", ($res->[0]));
		}
		else{
			if ($cert_type eq "RSA"){
				write_file("$c4_root/cache/$short_name/$name/archive/${cert_host}_key.pem", ($res->[0]));
				write_file("$c4_root/cache/$short_name/$name/archive/${cert_host}_cert.pem", ($res->[1]));
			}
			else{
				write_file("$c4_root/cache/$short_name/$name/archive/${cert_host}_dsa_key.pem", ($res->[0]));
				write_file("$c4_root/cache/$short_name/$name/archive/${cert_host}_dsa_cert.pem", ($res->[1]));
			}
		}
		print " -- Added $cert_type certificate for $cert_host to cache\n";
	}

	#Prep for kerberos keys
	my @keys = $block_ref->findnodes( '/c4:boot/kerberos_keys/service' );
	foreach my $key (@keys){
		my $key_name = $key->textContent();
		`cp $c4_root/cache/$short_name/Kerberos/result/$host.$key_name.keytab $c4_root/cache/$short_name/$name/archive/`;
		print " -- Added Kerberos keytab for $key_name\n";
	}

	#Prep for deployment files
	my @files = $block_ref->findnodes( '/c4:boot/deployment_files/file' );
	foreach my $file (@files) {
		my $file_task = $block_ref->findvalue( './@service', $file );
		my $file_file = $block_ref->findvalue( './@file', $file );
		`cp $c4_root/cache/$short_name/$file_task/result/$file_file $c4_root/cache/$short_name/$name/archive/`;
		print " -- Added deployment file $file_file from service $file_task\n";
	}

	# Waiting for network to go live on target host.
	# Wait forever. The VPN might be down temporarily, and when it recovers we can continue.
	my $sleep_seconds = 10;
	my $ping_count = 0;
	do {
	    $ping_count = 0;
	    do {
		`ping -c 1 $full_hostname`;
	    } while ($? != 0 && $ping_count++ < 3);

	    if ($ping_count >= 3){
		print "Failed to get valid ping to target host, $full_hostname\n";
	    }
	    sleep $sleep_seconds;
	    # $sleep_seconds += $sleep_seconds;
	} while ( $ping_count >= 3);
  
	ssh( $full_hostname, "mkdir -p /root/deploy$short_name/result");

	my $fh = File::Temp->new(SUFFIX => '.tar');
	my $tmpname = $fh->filename;

	`chmod a+x $c4_root/cache/$short_name/$name/deploy.sh; /bin/tar -C $c4_root/cache/$short_name/$name/ -cf $tmpname archive deploy.sh result template`;
	print `wc $tmpname ` . "\n";

	# Transfer archive, template and deploy script to target host
	ssh_key($full_hostname);  
	scp( "$tmpname", "root\@$full_hostname:/root/deploy$short_name/tarfile.tar");

	ssh( $full_hostname, "cd /root/deploy$short_name/; tar xf tarfile.tar; ");
}

#Execution algorithm - actual work happens here
if (! -d "$c4_root/cache/$short_name") {
	`mkdir $c4_root/cache/$short_name`
};
`touch $c4_root/cache/$short_name/log.txt`;
open (STDOUT, "| tee $c4_root/cache/$short_name/log.txt");
my $block_cmd = "";
my $t = DateTime->now;

BLOCK: foreach my $block (@flow){
	my $block_xml;
	my $block_xpc;
	if (exists($block->{'function'})){
		print "==================================\n";
		print "PROCESSING $block->{name}\n";
		# print "==================================\n";
		print " - MARK: " . $t->datetime() . "\n";
		print " - Running block function:\n";

		# function may access db_conn
		$block->{'function'}->($xpc);
		print " - Block function complete\n";
	}
	else{
		if (scalar(@threaded_jobs) > 0 && $block->{'thread'} ne "yes"){
			print " --- MARK: " . $t->datetime() . "\n";
			print " --- All bootstraps for threaded job group have been prepared. Switching to threaded operation\n";
			$completion_tracker = scalar(@threaded_jobs);
			foreach my $job (@threaded_jobs){
				$incomplete_processing_queue->enqueue($job);
			}
			while ($completion_tracker > 0){
				my $completed_name = $completed_processing_queue->dequeue();
				$completion_tracker--;
				if ( $completed_name ne "FAIL" ){
					print " --- Thread processing job $completed_name has finished\n";
				} else {
					print " --- Thread processing job FAILED, exiting\n";
					close(STDOUT);
					exit(1);
				}
			}
			$t = DateTime->now;
			print " - MARK: " . $t->datetime() . "\n";
			print " - All threaded jobs have finished processing, beginning post installs\n";
			foreach my $job (@threaded_jobs){
				if (! -f "postinst/$job->{name}.pl"){
					print " - No postinst found (expected post/$block->{name}.pl)\n\n";
					next;
				}
				print " --- Running post installation for $job->{name}\n";
				my $post_cmd = "";
				run( ["postinst/$job->{name}.pl", '--short_name', $short_name, '--domain', $org_domain, '--hardware_host', $hardware_host, '--network', $org_network ], '3>', \$post_cmd);
				`$post_cmd`;
				
				print " - Block processed successfully\n";
			}
			@threaded_jobs = ();
		}
		$t = DateTime->now;
		print "==================================\n";
		print "PROCESSING $block->{name}\n";
		print " - " . $t->datetime() . "\n";
		if (! -f "task_config/$block->{'name'}.xml"){
			print " - No XML config file found (expected task_config/$block->{name}.xml)\n\n";
			next;
		}

		print " - configuration file: " . "task_config/$block->{'name'}.xml" . "\n";
		$block_xml = $parser->load_xml( location => "task_config/$block->{'name'}.xml" );
		$block_xpc = XML::LibXML::XPathContext->new( $block_xml );
		$xmlschema = XML::LibXML::Schema->new( location => $block_xpc->findvalue( '//@xsi:schemaLocation' ) );
		eval{ $xmlschema->validate( $block_xml ); };
		die $@ if $@; #If validation failed, stop
		#Check to ensure that the block should be run, based on conditions
		my @conditions = $block_xpc->findnodes('/c4:boot/conditions/*');
		foreach my $condition (@conditions) {
			if ($condition->textContent eq "Requires_gateway"){
				#We need to have the gateway defined
				print " - Checking condition 'Requires_gateway'\n";
				if ($gateway_hostname && $hwgateway){
					print " - Condition cleared\n";
					next;
				} else {
					print " - Condition failed, processing next block\n";
					next BLOCK;
				}
			}
		}
		#Check to ensure that the block should be run, based on capabilities
		my @caps = $block_xpc->findnodes('/c4:boot/package/*');
		foreach my $cap (@caps) {
			last if $cap->getLocalName() eq 'always';
			next if exists $capabilities{$cap->textContent()};
			print " - Capability " . $cap->textContent() . " is not in package, SKIPPING deployment\n";
			next BLOCK;
		}
		&get_deploy_command( $block_xpc, $xpc, \$block_cmd );

		if ($block->{'thread'} eq "yes"){
			print " - Preparing to run $block->{name} as a separate execution thread\n\n";
			my %job :shared = ( command => $block_cmd, name => $block->{'name'} );
			my $job_ref :shared = \%job;
			push(@threaded_jobs, $job_ref);
			next;
		}


		&prepare_cache( $block_xpc, $xpc );
		print " - Running remote deploy script\n";
		`$block_cmd`;
		if ($? != 0){
			print " -- Return code from running $block_cmd is $?\n";
			print " - MARK: " . $t->datetime() . "\n";
			print " - Deploy script FAILED, exiting\n";
			my %term_job :shared = ( command => '', name => "TERMINATE_THREADS" );
			my $term_ref :shared = \%term_job;
			for (my $i = 0; $i < $number_of_threads; $i++){
				$incomplete_processing_queue->enqueue($term_ref);
			}
			sleep(5);
			close(STDOUT);
			exit(1);
		}
		
		#Run post-install stuff here
		&post_process( $block_xpc, $xpc );
		$t = DateTime->now;
		# print " - MARK: " . $t->datetime() . "\n";
		# print " - Block processed successfully\n\n";
	}
}
my %termination_job :shared = ( command => '', name => "TERMINATE_THREADS" );
my $termination_ref :shared = \%termination_job;
for (my $i = 0; $i < $number_of_threads; $i++){
	$incomplete_processing_queue->enqueue($termination_ref);
}
$t = DateTime->now;
print " - MARK: " . $t->datetime() . "\n";
print " - Processing complete. C4 complete.\n\n";

close(STDOUT);

# clean out the cache to save disk space
# unless we are debugging
if( $debug_mode == 0) {
    `rm -rf $c4_root/cache/$short_name/*`;
}

exit(0);
__END__

=head1 NAME

c4 - generate a new organization

=head1 DESCRIPTION

Script for generating entirely new organizations for domainneverused.net. Has preconceptions about the state of affairs before it gets run.

=head1 SYNOPSIS

	perl c4.pl --file input.xml

=head2 OPTIONS

=over 8

=item C<file>

The XML file that will be loaded by C4.

=head1 CAVEATS


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT

Free Open Source Solutions Inc., 2009-2016

=head1 AVAILABILITY

=head1 AUTHOR

Gregory Wolgemuth, Nimesh Jethwa


