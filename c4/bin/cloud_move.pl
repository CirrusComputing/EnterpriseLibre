#!/usr/bin/perl -w
#
# cloud_move.pl - v2.4
#
# This script moves a cloud from one server to another while keeping the network name and internal IP intact.
# The move can be to any specified physical server across any subnet (will have different external IP).
# All services are updated: Nagios, Amanda, ...
# The logs are written to /var/log/c4/cloud_move.log
#
# This script must be called twice. First, with the 'init' parm, to set up a test cloud on the destination server.
# The source cloud is still functional.  The new cloud can be tested by patching the new external IP into the .nxs, and by other tests.
# Second, when the cloud has been tested, the script is called with the 'commit' parm. 
# The source cloud gets removed, and DNS is updated to make the new cloud active.
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
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
use XML::LibXML;
use Cwd;
use Cwd 'abs_path';
use Tie::File;
use File::Copy;
use POSIX qw(floor);
use Getopt::Long;
use Data::Dumper::Simple;
# To get rid of the newline that Dumper prints.
$Data::Dumper::Indent = 0;

use common qw(:cloud_move);

if ((getpwuid($<))[0] ne 'c4'){
    print "Usage: Please run this script as C4\n";
    exit;
}

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
my $new_hwh_short_name;
my $phase;

GetOptions('network_name=s' => \$network_name, 'new_hardware_host=s' => \$new_hwh_short_name, 'phase=s' => \$phase) or die ("Options set incorrectly");

mylog("START $network_name $new_hwh_short_name $phase");
mylog("");

mylog("-- ".Dumper($network_name)) && check_value($network_name);
mylog("-- ".Dumper($new_hwh_short_name)) && check_value($new_hwh_short_name);
mylog("-- ".Dumper($phase)) && check_value($phase);

my $prime_dns="smc-zeus.$system_anchor_domain";
my $cloud_dns="zeus.$network_name";
my $cloud_firewall="hermes.$network_name";
my $dns_config_folder="/etc/bind";
my $apache_config_folder="/etc/apache2";
my $firewall_config_folder="/etc/shorewall";
my $nagios_config_folder="/etc/nagios3";
my $dns_awk_file="db.dns_update_serial.awk";
my $nagios="nagios.$system_anchor_domain";

my $short_name;
my $short_domain;
my $network;
my $current_bridge;
my $backup_server_short_name;
my $backup_server;
my $veid_base;
my $current_hwh_short_name;
my $current_hwh_name;
my $new_hwh_name;
my $current_hwh_ip;
my $new_hwh_ip;
my $current_wan_ip;
my $new_wan_ip;
my $new_wan_netmask;
my $vz_base_path;
my $new_bridge;
my $current_cloud_volume_size;
my $new_hwh_available_size;

my %capabilities;
my @capabilities;
my %containers = (
    Network => [$new_hwh_short_name],
    Storage => [$new_hwh_short_name],
    );
my @container_veids;
my $deployment_name = "cloud_move-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my %script_folder = (
    Network => "$c4_root/storage/Network_Create/",
    Storage => "$c4_root/storage/Storage_Create/",
    );
my @deploy_nodes;
my %password_nodes;

# Execute main function
main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'shortname'){
	return $short_name;
    }
    elsif ($arg eq 'wan_ip'){
        return $new_wan_ip;
    }
    elsif ($arg eq 'wan_netmask'){
        return $new_wan_netmask;
    }
    elsif ($arg eq 'network'){
        return $network;
    }
    elsif($arg eq 'volume_size'){
	return $current_cloud_volume_size;
    }
    elsif($arg eq 'hwhgateway'){
	return $new_hwh_ip;
    }
}

sub generate_deployment{
    my ($arg) = @_;
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;

    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    deploy_capabilities($deployment_file, 'CAPABILITY', \%capabilities);
    get_deployment_xml("task_config/$arg\.xml", \%password_nodes, \@deploy_nodes);

    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }

    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub fail{
    `rm -f c4.lock`;
    mylog("");
    exit(1);
}

sub trim {
    (my $s = $_[0]) =~ s/^\s+|\s+$//g;
    return $s;        
}

sub check_value{
    my ($arg) = @_;
    unless($arg){
        mylog("ERROR: One of the values is NULL.");
        fail();
    }
}

sub get_values{
    mylog("- Getting information from database");
    # Cloud details
    my $get_cloud_details = $db_conn->prepare("SELECT short_name, REGEXP_REPLACE(HOST(network)::TEXT,E'\\.0\$','') AS network, bridge, backup_server FROM network.organization WHERE network_name = ?")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_details->bind_param(1, $network_name);
    $get_cloud_details->execute()
        or die "Couldn't execute statement: " . $get_cloud_details->errstr;
    ($short_name, $network, $current_bridge, $backup_server_short_name) = $get_cloud_details->fetchrow_array();
    $get_cloud_details->finish;

    # Cloud's VEID base
    my $get_cloud_veid_base = $db_conn->prepare("SELECT FLOOR(veid/100)*100 AS veid_base FROM network.server WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) GROUP BY veid_base")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_veid_base->bind_param(1, $network_name);
    $get_cloud_veid_base->execute()
        or die "Couldn't execute statement: " . $get_cloud_veid_base->errstr;
    ($veid_base) = $get_cloud_veid_base->fetchrow_array();
    $get_cloud_veid_base->finish;
    
    # Cloud's VEID's
    my $get_cloud_veids = $db_conn->prepare("SELECT veid FROM network.server WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY veid")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_cloud_veids->bind_param(1, $network_name);
    $get_cloud_veids->execute()
        or die "Couldn't execute statement: " . $get_cloud_veids->errstr;

    while (my $container = $get_cloud_veids->fetchrow()){
        push(@container_veids, $container);
    }

    $get_cloud_veids->finish;    

    # Cloud's current HWH shortname
    my $get_current_hwh_name = $db_conn->prepare("SELECT hostname FROM network.server WHERE id = (SELECT hardware_host FROM network.server WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) GROUP BY hardware_host)")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_current_hwh_name->bind_param(1, $network_name);
    $get_current_hwh_name->execute()
        or die "Couldn't execute statement: " . $get_current_hwh_name->errstr;
    ($current_hwh_short_name) = $get_current_hwh_name->fetchrow_array();
    $get_current_hwh_name->finish;

    # Cloud's current HWH name
    $current_hwh_name = $current_hwh_short_name.".$system_anchor_domain";
    
    # Cloud's current HWH IP
    my $get_current_hwh_ip = $db_conn->prepare("SELECT HOST(gateway_ip) FROM network.hardware_hosts WHERE id = (SELECT id FROM network.server WHERE hostname = ?)")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_current_hwh_ip->bind_param(1, $current_hwh_short_name);
    $get_current_hwh_ip->execute()
        or die "Couldn't execute statement: " . $get_current_hwh_ip->errstr;
    ($current_hwh_ip) = $get_current_hwh_ip->fetchrow_array();
    $get_current_hwh_ip->finish;

    # Cloud's current WAN IP. 
    # Get this from hermes. If you try getting this from the db, then you might get the wrong IP, as after init, the database has two WAN IP's associated with the same cloud.
    $current_wan_ip = ssh("$cloud_firewall", "ifconfig venet0:0 | awk '/inet addr/ {split (\\\$2,A,\\\":\\\"); print A[2]}'");
    chomp($current_wan_ip);
 
    # Cloud's new HWH name
    $new_hwh_name = $new_hwh_short_name.".$system_anchor_domain";

    # Cloud's new HWH IP
    my $get_new_hwh_ip = $db_conn->prepare("SELECT HOST(gateway_ip) FROM network.hardware_hosts WHERE id = (SELECT id FROM network.server WHERE hostname = ?)")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_new_hwh_ip->bind_param(1, $new_hwh_short_name);
    $get_new_hwh_ip->execute()
        or die "Couldn't execute statement: " . $get_new_hwh_ip->errstr;
    ($new_hwh_ip) = $get_new_hwh_ip->fetchrow_array();
    $get_new_hwh_ip->finish;

    # Cloud's new WAN IP
    # If init, then get new ip. Otherwise get the new ip mapped to the cloud from the database for commit. Getting new ip from the database could also mean that the sysadmin wants the cloud to get a particular IP. In that case he would map the new ip to the cloud in the database and then run cloud move with phase option 1.
    my $get_new_wan_ip = $db_conn->prepare("SELECT address FROM network.address_pool WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) and address != ?")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_new_wan_ip->bind_param(1, $network_name);
    $get_new_wan_ip->bind_param(2, $current_wan_ip);
    $get_new_wan_ip->execute()
        or die "Couldn't execute statement: " . $get_new_wan_ip->errstr;
    ($new_wan_ip) = $get_new_wan_ip->fetchrow_array();
    $get_new_wan_ip->finish;
    unless($new_wan_ip){
        $get_new_wan_ip = $db_conn->prepare("SELECT address FROM network.free_ips WHERE address IN (SELECT address FROM network.hwh_ips WHERE serverid = (SELECT gatewayid FROM network.server_pool WHERE serverid = (SELECT id FROM network.server WHERE hostname = ?))) ORDER BY address ASC LIMIT 1")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $get_new_wan_ip->bind_param(1, $new_hwh_short_name);
        $get_new_wan_ip->execute()
            or die "Couldn't execute statement: " . $get_new_wan_ip->errstr;
        ($new_wan_ip) = $get_new_wan_ip->fetchrow_array();
        $get_new_wan_ip->finish;
    }

    # Cloud's new WAN IP netmask    
    my $get_new_wan_netmask = $db_conn->prepare("SELECT HOST(netmask) FROM network.address_pool WHERE address = ?")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_new_wan_netmask->bind_param(1, $new_wan_ip);
    $get_new_wan_netmask->execute()
        or die "Couldn't execute statement: " . $get_new_wan_netmask->errstr;
    ($new_wan_netmask) = $get_new_wan_netmask->fetchrow_array();
    $get_new_wan_netmask->finish;

    # Cloud's current Volume Size.
    $current_cloud_volume_size = ssh("$current_hwh_name", "df -h | grep $short_name | awk '{print ".'\$'."(1F)}' | awk NR==2 | sed 's|G||'");
    chomp($current_cloud_volume_size);

    # Get available free space on new hwh.
    my $get_new_hwh_available_size = $db_conn->prepare("SELECT disk_free_in_gib FROM network.capacity WHERE hardware_host = (SELECT id FROM network.server WHERE hostname = ?)")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_new_hwh_available_size->bind_param(1, $new_hwh_short_name);
    $get_new_hwh_available_size->execute()
        or die "Couldn't execute statement: " . $get_new_hwh_available_size->errstr;
    ($new_hwh_available_size) = $get_new_hwh_available_size->fetchrow_array();
    $get_new_hwh_available_size->finish;
    
    ($short_domain = $network_name) =~ s/.$system_anchor_domain//;
    $vz_base_path = "/var/lib/vz-$short_name";    
    $backup_server = $backup_server_short_name.".$system_anchor_domain";
    
    mylog("-- ".Dumper($short_name)) && check_value($short_name);
    mylog("-- ".Dumper($network)) && check_value($network);
    mylog("-- ".Dumper($current_bridge)) && check_value($current_bridge);
    mylog("-- ".Dumper($backup_server_short_name)) && check_value($backup_server_short_name);
    mylog("-- ".Dumper($veid_base)) && check_value($veid_base);
    mylog("-- ".Dumper($current_hwh_short_name)) && check_value($current_hwh_short_name);
    mylog("-- ".Dumper($current_hwh_ip)) && check_value($current_hwh_ip);
    mylog("-- ".Dumper($current_wan_ip)) && check_value($current_wan_ip);
    mylog("-- ".Dumper($new_hwh_ip)) && check_value($new_hwh_ip);
    mylog("-- ".Dumper($new_wan_ip)) && check_value($new_wan_ip);
    mylog("-- ".Dumper($new_wan_netmask)) && check_value($new_wan_netmask);
    mylog("-- ".Dumper($current_cloud_volume_size)) && check_value($current_cloud_volume_size);
    mylog("-- ".Dumper($new_hwh_available_size)) && check_value($new_hwh_available_size);    
}

sub check_move{
    mylog("- Checking if move is possible");
    # Check if source and destination is same.
    if ($current_hwh_ip eq $new_hwh_ip){
        mylog("ERROR: Can't move $short_name from $current_hwh_name to $new_hwh_name.");
        fail();
    }

    #Check if init is already complete.
    my $newNetworkUp = ssh("$new_hwh_name", "ifconfig | grep $network | awk '{print}'");
    my $newLVMisUp = ssh("$new_hwh_name", "df -h | grep -w $short_name | awk '{print ".'\$'."(1F)}' | awk NR==2 | sed 's|G||'");
    chomp($newNetworkUp);
    chomp($newLVMisUp);
    
    if(!$newNetworkUp and !$newLVMisUp){
        unless($phase eq 'init'){
	    mylog("ERROR: Init is to be run.");
            fail();
        }
    }
    elsif($newNetworkUp && $newLVMisUp){
        unless($phase eq 'commit'){
	    mylog("ERROR: Commit is to be run.");
	    fail();
	}
    }
    elsif($newNetworkUp && !$newLVMisUp){
	mylog("ERROR: New LVM is not up");
	fail();
    }
    elsif(!$newNetworkUp && $newLVMisUp){
	mylog("ERROR: New network is not up");
	fail();
    }
    else{
        mylog("ERROR: Logic Error");
        fail();
    }    

    # Check is there is enough space to move cloud for init.
    if ($phase eq 'init'){
	mylog("-- Current cloud volume size = $current_cloud_volume_size gigs.");    
	if($current_cloud_volume_size >= $new_hwh_available_size){
	    mylog("ERROR: Not enough space on new server.");
	    fail();
	}
	mylog("-- Free space available on new server.");
    }
    
    #Check is rsync is installed on both the physical servers
    my $new_hwh_rsync =  ssh("$new_hwh_name", "rpm -qa | grep rsync | awk '{print}'");
    unless ($new_hwh_rsync){
        mylog("ERROR: Package rsync not installed on $new_hwh_name.");
        fail();
    }
    my $current_hwh_rsync =  ssh("$current_hwh_name", "rpm -qa | grep rsync | awk '{print}'");
    unless ($current_hwh_rsync){
        mylog("ERROR: Package rsync not installed on $new_hwh_name.");
        fail();
    }
    mylog("-- Rsync installed on both servers.");
}

sub configure_new_network{
    mylog("-- Configure Network.");
    my $task = 'Network';
    generate_deployment($task);
    run_script($network_name, $script_folder{$task}, $deployment_name, $tar_file, $deployment_file, $containers{$task});
}

sub record_new_bridge{
    $new_bridge = ssh("$new_hwh_name", "grep 'br*' /etc/shorewall/orgs.local/$short_name/interfaces | awk '{print ".'\$'."(2F)}'");
    chomp($new_bridge);
    unless ($new_bridge){
        mylog("ERROR: Could not determine bridge name.");
        fail();
    }
    mylog("-- Recorded new bridge - $new_bridge.");
}
        
sub make_phase_cleanup{
    my ($xpc) = @_;
    my $cleanupScrName = "./cleanup/cleanCloudMove${short_name}.sh";
    copy("cleanup_cloud_move_phase_parms.template", $cleanupScrName);
    chmod 0755, $cleanupScrName;
         
    my @contents;
    tie @contents, 'Tie::File', $cleanupScrName;
    if($phase eq 'init'){
	for (@contents) {
	    s/\[-VEID_BASE-\]/$veid_base/;    
	    s/\[-SHORT_NAME-\]/$short_name/;
	    s/\[-NETWORK-\]/$network/;
	    s/\[-IP-\]/$new_wan_ip/;
	    s/\[-VZ_BASE_PATH-\]/$vz_base_path/;
	    s/\[-BRIDGE-\]/$new_bridge/;
	    s/\[-HWHOST-\]/$new_hwh_short_name/;
	    s/\[-PHASE-\]/$phase/
	};
    }
    else{
	for (@contents) {
	    s/\[-VEID_BASE-\]/$veid_base/;    
	    s/\[-SHORT_NAME-\]/$short_name/;
	    s/\[-NETWORK-\]/$network/;
	    s/\[-IP-\]/$current_wan_ip/;
	    s/\[-VZ_BASE_PATH-\]/$vz_base_path/;
	    s/\[-BRIDGE-\]/$current_bridge/;
	    s/\[-HWHOST-\]/$current_hwh_short_name/;
	    s/\[-PHASE-\]/$phase/
	};
    }
    untie @contents;
    mylog("-- Made *$phase* cleanup file");
}

sub make_cloud_cleanup{
    my ($xpc) = @_;
    
    my $cleanupScrName = "./cleanup/clean${short_name}.sh";
    copy("cleanup_parms.template", $cleanupScrName);
    chmod 0755, $cleanupScrName;
         
    my @contents;
    tie @contents, 'Tie::File', $cleanupScrName;
    for (@contents) {
        s/\[-VEID_BASE-\]/$veid_base/;    
        s/\[-SHORT_NAME-\]/$short_name/;
        s/\[-NETWORK_NAME-\]/$network_name/;    
        s/\[-SHORT_DOMAIN-\]/$short_domain/;
        s/\[-NETWORK-\]/$network/;
        s/\[-IP-\]/$new_wan_ip/;
        s/\[-VZ_BASE_PATH-\]/$vz_base_path/;
        s/\[-BRIDGE-\]/$new_bridge/;
        s/\[-HWHOST-\]/$new_hwh_short_name/;
        s/\[-HWHSTIP-\]/$new_hwh_ip/;
        s/\[-BACKUP_SERVER-\]/$backup_server/
    };
    untie @contents;
    mylog("-- Made new cleanup file");
}

sub configure_new_storage{
    mylog("-- Configuring storage.");
    my $task = 'Storage';
    generate_deployment($task);
    run_script($network_name, $script_folder{$task}, $deployment_name, $tar_file, $deployment_file, $containers{$task});
}

sub update_free_space{
    mylog("-- Updating free space.");
    `./set_free_space.pl $new_hwh_short_name 2>&1`;
}

sub create_remove_rsa_key{
    my ($option, $server_create, $server_add) = @_;
    if($option eq 'CREATE'){
        mylog("--- Create and Add SSH key.");
        # Create new key for host
        ssh("$server_create", "cd ~/.ssh; rm -f id_rsa*; ssh-keygen -f id_rsa -N '' -t rsa -q");
        # Acquire SSH fingerprint on hwh
        ssh("$server_create", "ssh-keygen -R $server_add");
        ssh("$server_create", "ssh-keyscan -t rsa -H $server_add >> ~/.ssh/known_hosts");
        my $hwh_key = ssh("$server_create", "cat ~/.ssh/id_rsa.pub");
        chomp($hwh_key);
        # Add key to authorized_keys file
        ssh("$server_add", "echo '$hwh_key' >> ~/.ssh/authorized_keys");
    }
    elsif($option eq 'REMOVE'){
        mylog("--- Remove SSH key.");
        # Remove ssh fingerprint and key
        ssh("$server_create", "ssh-keygen -R $server_add; cd ~/.ssh; rm -f id_rsa*");
        # Remove host key from authorized_keys file
        ssh("$server_add", "grep -wv '$server_create' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new; mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys");
    }
}

sub perform_rsync{
    mylog("-- Performing Rsync.");
    mylog("--- Syncing containers.");
    `ssh root\@$new_hwh_name "rsync -ar root\@$current_hwh_name:$vz_base_path/private/ $vz_base_path/private/"`;

    mylog("--- Syncing vz conf files, creating vz root directory, dropping existing quota files and starting the containers.");    
    foreach my $veid (@container_veids){
	# Rsync vz conf files and containers - Not using the ssh method in common.sh since rsync never really returns exit code 0, because of files changing continuously at host.
	`ssh root\@$new_hwh_name "rsync -ar root\@$current_hwh_name:/etc/vz/conf/$veid\.conf /etc/vz/conf/"`;
	
	# Change Bridge name if different. If this is commit, then vzmigrate will overwrite this, so we do a sed again later.
	if($current_bridge ne $new_bridge){
	    mylog("---- Changing bridge name in config file.");
	    ssh("$new_hwh_name", "sed -i 's|$current_bridge|$new_bridge|g' /etc/vz/conf/$veid\.conf");
	}

	# Change External IP in vz conf file of firewall container (hermes) If this is commit, then vzmigrate will overwrite this, so we do a sed again later.
	if (substr($veid, length($veid)-2, length($veid)) == 03){
	    mylog("---- Changing External IP in config file for firewall container.");
	    ssh("$new_hwh_name", "sed -i '/IP_ADDRESS=\\\"$current_wan_ip\\\"/s|$current_wan_ip|$new_wan_ip|g' /etc/vz/conf/$veid\.conf");
	}

	# Create vz root directory.
        ssh("$new_hwh_name", "mkdir -p $vz_base_path/root/$veid");
    
	# Drop existing quota files and start the containers.
        my $status = ssh("$new_hwh_name", "vzlist -a | grep $veid | grep running | awk '{print ".'\$'."(3F)}'");
        chomp($status);
        if ($status ne 'running'){
            ssh("$new_hwh_name", "if [ -f /var/vzquota/quota\.$veid ]; then vzquota drop $veid; fi");
            ssh("$new_hwh_name", "[ -f /etc/vz/conf/$veid\.conf ] && vzctl start $veid | awk '{print}'");
        }        
    }
}

sub perform_live_migration{
    mylog("-- Performing Live Migration.");
    foreach my $veid (@container_veids){
        ssh("$new_hwh_name", "[ -f /etc/vz/conf/$veid\.conf ] && vzctl stop $veid --fast | awk '{print}'");
        ssh("$new_hwh_name", "if [ -f /var/vzquota/quota\.$veid ]; then vzquota drop $veid; fi");
        ssh("$new_hwh_name", "[ -f /etc/vz/conf/$veid\.conf ] && rm /etc/vz/conf/$veid\.conf");
	ssh("$current_hwh_name", "vzmigrate -r no --keep-dst --online $new_hwh_ip $veid");
        ssh("$current_hwh_name","mv /etc/vz/conf/$veid\.conf.migrated /etc/vz/conf/$veid\.conf");
	
        # Leave out the Desktop container because we want to the NX sessions to be as they were.
        # If bridge name changed, then we restart all, too bad for the sessions.
        if ((substr($veid, length($veid)-2, length($veid)) != 50) || ($current_bridge ne $new_bridge)){
	    # Change Bridge name if different.
	    if($current_bridge ne $new_bridge){
		mylog("---- Changing bridge name in config file.");
		ssh("$new_hwh_name", "sed -i 's|$current_bridge|$new_bridge|g' /etc/vz/conf/$veid\.conf");
	    }
	    
	    # Change External IP in vz conf file of firewall container (hermes).
	    if (substr($veid, length($veid)-2, length($veid)) == 03){
		mylog("---- Changing External IP in config file for firewall container.");
		ssh("$new_hwh_name", "sed -i '/IP_ADDRESS=\\\"$current_wan_ip\\\"/s|$current_wan_ip|$new_wan_ip|g' /etc/vz/conf/$veid\.conf");
	    }

	    ssh("$new_hwh_name", "[ -f /etc/vz/conf/$veid\.conf ] && vzctl restart $veid | awk '{print}'");
        }
    }
}

sub cleanup_old_instance{
    mylog("-- Cleaning up old instance.");
    `./cleanup/cleanCloudMove${short_name}.sh 2>&1`;
}

sub update_firewall{
    mylog("-- Updating Cloud Firewall.");
    # Firewall needs to be updated before the DNS, because if it's the other way then Prime DNS can't communicate with Cloud DNS because of packets being dropped due to packets not getting in/out or network being unreachable.

    # Update Cloud Firewall shorewall configuration
    ssh("$cloud_firewall", "sed -i 's|$current_wan_ip|$new_wan_ip|' $firewall_config_folder/*");
    ssh("$cloud_firewall", "/etc/init.d/shorewall restart");

    # Update hosts file
    ssh("$cloud_firewall", "sed -i 's|$current_wan_ip|$new_wan_ip|' /etc/hosts");

    # Update Cloud Firewall apache configuration    
    ssh("$cloud_firewall", "sed -i 's|$current_wan_ip|$new_wan_ip|' $apache_config_folder/ports.conf");
    ssh("$cloud_firewall", "sed -i 's|$current_wan_ip|$new_wan_ip|' $apache_config_folder/sites-available/*");
    ssh("$cloud_firewall", "/etc/init.d/apache2 reload");
}

sub update_dns{
    mylog("-- Updating Prime DNS.");
    # Update Prime DNS
    ssh("$prime_dns", "sed -i 's|$current_wan_ip key external-$network_name|$new_wan_ip key external-$network_name|g' $dns_config_folder/orgs/external/*");
    ssh("$prime_dns", "/etc/init.d/bind9 reload");
    
    mylog("-- Updating Cloud DNS.");
    # Update Cloud DNS
    ssh("$cloud_dns", "sed -i 's|$current_wan_ip|$new_wan_ip|' $dns_config_folder/db.*.external");
    scp("$c4_root/storage/$dns_awk_file", "root\@$cloud_dns:/tmp/$dns_awk_file");
    ssh("$cloud_dns", "f=\\\$(find $dns_config_folder -name db.*.external); awk -f /tmp/$dns_awk_file \\\$f > \\\$f\.new; cp \\\$f \\\$f.bak; mv \\\$f\.new \\\$f");
    ssh("$cloud_dns", "/etc/init.d/bind9 reload");
}

sub update_nagios{
    mylog("-- Updating Nagios.");
    ssh("$nagios", "sed -i -e 's|$current_hwh_short_name|$new_hwh_short_name|g;s|$current_wan_ip|$new_wan_ip|g' $nagios_config_folder/organizations/$short_domain\.cfg");
    ssh("$nagios", "/etc/init.d/nagios3 reload");
}

sub update_database{
    mylog("-- Updating database.");
    if($phase eq 'init'){
        my $update_new_wan_ip = $db_conn->prepare("UPDATE network.address_pool SET organization = (SELECT id FROM network.organization WHERE network_name = ?) WHERE address = ?")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $update_new_wan_ip->bind_param(1, $network_name);
        $update_new_wan_ip->bind_param(2, $new_wan_ip);
        $update_new_wan_ip->execute()
            or die "Couldn't execute statement: " . $update_new_wan_ip->errstr;
        $update_new_wan_ip->finish;
    }
    else{
        #Now, add bridge name to the database
        my $update_cloud_bridge = $db_conn->prepare("UPDATE network.organization SET bridge = ? WHERE network_name = ?")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $update_cloud_bridge->bind_param(1, $new_bridge);
        $update_cloud_bridge->bind_param(2, $network_name);
        $update_cloud_bridge->execute()
            or die "Couldn't execute statement: " . $update_cloud_bridge->errstr;
        $update_cloud_bridge->finish;
    
        my $update_cloud_hwh_mapping = $db_conn->prepare("UPDATE network.server SET hardware_host = (SELECT id FROM network.server WHERE hostname = ?) WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $update_cloud_hwh_mapping->bind_param(1, $new_hwh_short_name);
        $update_cloud_hwh_mapping->bind_param(2, $network_name);
        $update_cloud_hwh_mapping->execute()
            or die "Couldn't execute statement: " . $update_cloud_hwh_mapping->errstr;
        $update_cloud_hwh_mapping->finish;
        
        my $insert_move_record = $db_conn->prepare("INSERT INTO network.cloud_move (organization, network_name, source, destination) VALUES ((SELECT id FROM network.organization WHERE network_name = ?),?,?,?)")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $insert_move_record->bind_param(1, $network_name);
        $insert_move_record->bind_param(2, $network_name);
        $insert_move_record->bind_param(3, $current_hwh_name);
        $insert_move_record->bind_param(4, $new_hwh_name);
        $insert_move_record->execute()
            or die "Couldn't execute statement: " . $insert_move_record->errstr;
        $insert_move_record->finish;
    }
}

sub main{
    `lockfile -30 -r-1 c4.lock`;
    
    get_values();
    check_move();
    create_remove_rsa_key('CREATE',$new_hwh_name, $current_hwh_name);
    create_remove_rsa_key('CREATE',$current_hwh_name, $new_hwh_name);
    
    if($phase eq 'init'){
	configure_new_network();
    }
    
    record_new_bridge();
    make_phase_cleanup();    
    
    if($phase eq 'commit'){
	make_cloud_cleanup();    
    }
    
    if($phase eq 'init'){
	configure_new_storage();
	update_free_space();
    }
    
    perform_rsync();
    
    if($phase eq 'commit'){
	perform_live_migration();
	update_firewall();
	update_dns();
	update_nagios();
    }
    
    update_database();

    if($phase eq 'commit'){	
	cleanup_old_instance();
    }

    create_remove_rsa_key('REMOVE',$new_hwh_name, $current_hwh_name);
    create_remove_rsa_key('REMOVE',$current_hwh_name, $new_hwh_name);
    
    mylog("END $network_name $new_hwh_name $phase");
    mylog("");
    `rm -f c4.lock`;
}
