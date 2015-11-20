# common.pm - v3.7
#
# This module has some of the common functions used by C4 scipts.
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

package common;

use strict;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Net::SSH2;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Config::General;

$VERSION     = 3.70;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_all_containers determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_userlist get_domain_config_details get_superuser_details has_capability get_deployment_xml get_db_conn);
%EXPORT_TAGS = ( DEFAULT => [qw(acquire_ssh_fingerprint ssh scp)],
		 userprimaryemail_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_domain_config_details)],
		 userfullname_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script)],
		 domain_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_userlist get_domain_config_details)],
		 firewallproxy_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string deploy_parameters deploy_passwords run_script get_domain_config_details)],
		 cloudcapability_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_userlist get_domain_config_details get_superuser_details has_capability get_deployment_xml)],
		 cloud_boot    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_deployment_xml)],
		 timezone_config => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string determine_capabilities determine_all_containers determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_userlist)],
    		 firewallport_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string deploy_parameters deploy_passwords run_script)],
		 cloud_move    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_deployment_xml)],
		 backup_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_deployment_xml)],
		 systemanchor_config    => [qw(acquire_ssh_fingerprint ssh scp mylog get_random_string get_system_anchor_domain determine_capabilities determine_all_containers determine_entity_password deploy_capabilities deploy_parameters deploy_passwords run_script get_userlist get_superuser_details get_domain_config_details)]);

# Acquires SSH Fingerprint
sub acquire_ssh_fingerprint{
    my ($full_hostname) = @_;
    #mylog(" --- Clearing SSH known hosts for target host");
    # Remove key for host and quad ip
    `ssh-keygen -R $full_hostname 2>/dev/null`;
    `ssh-keygen -R \$(host $full_hostname |  grep 'has address' | awk '{print \$4}') 2>/dev/null`;
    my $fingerprint_done = 0;
    my $sleep_time = 20;
    my $slept = 0;
    #mylog(" --- Acquiring SSH fingerprint for target host");
    do {
	`ssh-keyscan -t rsa -H $full_hostname >> $ENV{HOME}/.ssh/known_hosts 2>/dev/null`;
	my $code1 = $?;
	`ssh-keyscan -t rsa -H \$(host $full_hostname | grep 'has address' | awk '{print \$4}') >> $ENV{HOME}/.ssh/known_hosts 2>/dev/null`;
	my $code2 = $?;
	if ($code1 != 0){
	    mylog(" ---- Return code of ssh-keyscan for $full_hostname is $code1 and $code2");
	    sleep($sleep_time);

	    # Increase slept until it is over 15 mins
	    $slept += $sleep_time;
	    if($slept > 900) {
		mylog(" ---- ERROR: ssh-keyscan failed");
		exit(1);
	    }
	}
	else{
	    $fingerprint_done = 1;
	}
    } while ($fingerprint_done == 0);
}

# Copy files to/from another server, and retry when we fail
sub scp{
    my ($src, $dest) = @_;
    mylog(" --- SCP == $src, $dest");
    my $scp_done = 0;
    my $sleep_time = 20;
    my $slept = 0;
    
    do{
	foreach ($src, $dest){
	    my $full_hostname = `echo "$_" | sed 's|.*@\\(.*\\):.*|\\1|g'`;
	    chomp($full_hostname);
	    `host '$full_hostname'`;
	    if ($? == 0){
                acquire_ssh_fingerprint($full_hostname);
	    }
	}

	`scp -l 50000 -r $src $dest`;
	if ($? != 0){
	    mylog(" ---- Return code of scp from $src to $dest is $?");
	    sleep($sleep_time);

	    # Increase slept until it is over 15 mins
	    $slept += $sleep_time;
	    if($slept > 900){
		mylog(" ---- ERROR: scp failed");
		exit(1);
	    }
	} 
	else{
	    $scp_done = 1;
	}
    } while ($scp_done == 0);
}

# Run commands on another server, and retry when ssh fails to connect.
# Assume that a fail code from ssh means the command did not get run.
sub ssh{
    my ($full_hostname, $cmd, $optional_username) = @_;
    $optional_username //= "root"; # Default optional value

    mylog(" --- SSH == $optional_username at $full_hostname, $cmd");

    my $ssh_done = 0;
    my $sleep_time = 20;
    my $slept = 0;
    my $rvalue = ' ';
    do {
	# Do ssh-keyscan first
	acquire_ssh_fingerprint($full_hostname);

	$rvalue = `ssh $optional_username\@$full_hostname "$cmd"`;
	my $rcode = $?;                # Actually should be $? >> 8, then 65280 is 255, see perlvar
	if ($rcode == 0){
	    $ssh_done = 1;
	} 
	else{
	    if ($rcode == 65280 ) {  # 255
		mylog(" ---- Return code from ssh is $rcode 1");
		sleep($sleep_time);
	
		# Increase slept until it is over 15 mins 
		$slept += $sleep_time;
		if($slept > 900) {
		    mylog(" ---- ERROR: ssh to $full_hostname failed");
		    exit(1);
		}
	    } 
	    else{
		mylog(" ---- Return code from ssh is $rcode 1");
		exit(1);
	    }
	}
    } while ($ssh_done == 0);

    return $rvalue;
}

sub mylog{
    my $output = shift;
    my $now = localtime;
    print "$now $output\n";
}

sub get_random_string{
    my ($length) = @_;
    my $random_string = `perl -le 'print map {("a".."z","A".."Z")[rand 52]} 0..($length-1)'`;
    $random_string =~ s/\R//g;
    return $random_string;
}

sub get_system_anchor_domain{
    my ($db_conn) = @_;
    $db_conn //= get_db_conn();
    my $db_result = $db_conn->prepare("SELECT network_name FROM network.organization WHERE id = ?")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $db_result->bind_param(1, 1, SQL_INTEGER);
    $db_result->execute()
	or die "Couldn't execute statement: " . $db_result->errstr;
    my ($system_anchor_domain) = $db_result->fetchrow_array();
    $db_result->finish;
    return $system_anchor_domain;
}

sub determine_all_containers{
    my ($db_conn, $network_name, $containers_array) = @_;
    $db_conn //= get_db_conn();
    undef @$containers_array;
    my $get_container_list = $db_conn->prepare("SELECT hostname FROM network.server WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND hardware_host IS NOT NULL ORDER BY veid")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_container_list->bind_param(1, $network_name);
    $get_container_list->execute()
        or die "Couldn't execute statement: " . $get_container_list->errstr;

    my $container = '';
    my $print_string = " --- ";
    while ($container = $get_container_list->fetchrow()){
        push(@$containers_array, $container);
    }
    $get_container_list->finish;
}

sub determine_capabilities{
    my ($db_conn, $network_name, $option, $caps_hash, $caps_array) = @_;
    mylog(" - Determining $option capabilities");
    undef %$caps_hash;
    undef @$caps_array;
    my $find_caps='';
    if ($option eq 'cloud'){
	$find_caps = $db_conn->prepare("SELECT capid, name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)  ORDER BY capability)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$find_caps->bind_param(1, $network_name);
    }
    elsif ($option eq 'enabled'){
	$find_caps = $db_conn->prepare("SELECT capid, name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)  and enabled = ? ORDER BY capability)")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $find_caps->bind_param(1, $network_name);
	$find_caps->bind_param(2, "t", PG_BOOL);
    }
    
    $find_caps->execute()
        or die "Couldn't execute statement: " . $find_caps->errstr;
    
    my $capid='';
    my $print_string = " --- ";
    while ($capid = $find_caps->fetchrow_arrayref){
        ${$caps_hash}{$capid->[1]} = 1;
        $print_string .= $capid->[1]." ";
    }
    mylog($print_string);
    $find_caps->finish;

    @$caps_array =keys %$caps_hash;
    @$caps_array = map {glob ($_)} @$caps_array;
}

sub determine_entity_password{
    my ($db_conn, $network_name, $host, $entity) = @_;
    my $get_entity_password = $db_conn->prepare("SELECT password FROM vault.passwords WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND host = ? AND entity = ?")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_entity_password->bind_param(1, $network_name);
    $get_entity_password->bind_param(2, $host);
    $get_entity_password->bind_param(3, $entity);
    $get_entity_password->execute()
        or die "Couldn't execute statement: " . $get_entity_password->errstr;
    my @result_array = $get_entity_password->fetchrow_array;
    $get_entity_password->finish;

    my $password = "";
    if (scalar(@result_array) == 0){
        $password = &generate_password('system');
	my $insert_entity_password = $db_conn->prepare("INSERT INTO vault.passwords (organization, host, entity, password) SELECT id, ?, ?, ? FROM network.organization WHERE network_name = ?")
            or die "Couldn't prepare statement: " . $db_conn->errstr;
        $insert_entity_password->bind_param(1, $host);
        $insert_entity_password->bind_param(2, $entity);
        $insert_entity_password->bind_param(3, $password);
        $insert_entity_password->bind_param(4, $network_name);
        $insert_entity_password->execute()
            or die "Couldn't execute statement: " . $insert_entity_password->errstr;
	$insert_entity_password->finish;
    }
    else{
        $password = $result_array[0];
    }
    return $password;
}

sub deploy_capabilities{
    my ($deployment_file, $string_attribute, $caps_hash) = @_;
    open (DEPLOY, ">>$deployment_file") || die "Could not open deployment $deployment_file file for writing";
    for my $cap (keys %$caps_hash){
        print DEPLOY "$string_attribute:$cap\n";
    }
}

sub deploy_parameters{
    my ($deployment_file, $deploy_node, $arg_value) = @_;
    open (DEPLOY, ">>$deployment_file") || die "Could not open deployment $deployment_file file for writing";
    if ( $arg_value eq '' ){
	    mylog(" -- ERROR: argument for $deploy_node missing ");
	}
	print DEPLOY "PARAMETER:$deploy_node:$arg_value\n";
}

sub deploy_passwords{
    my ($db_conn, $network_name, $deployment_file, $password_nodes) = @_;
    open (DEPLOY, ">>$deployment_file") || die "Could not open deployment $deployment_file file for writing";
    while ( my ($password_name, $password_name_value) = each(%$password_nodes) ) {
	while ( my ($password_host, $password_entity) = each(%$password_name_value) ){
	    mylog(" -- Getting password for $password_entity at $password_host from Prime");
	    my $password =  determine_entity_password($db_conn, $network_name, $password_host, $password_entity);
	    print DEPLOY "PASSWORD:$password_name:$password\n";
	}
    }
}

sub run_script{
    my ($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, $containers, $params) = @_;
    $params //= ""; # Default params value
    my $system_anchor_domain = get_system_anchor_domain();
    my @containers;
    determine_all_containers(undef, $network_name, \@containers);
    `cd $script_folder; tar czhf $tar_file archive deploy.sh template`;
    for (my $i=0; $i<scalar @$containers; $i++){
	my $short_name = @$containers[$i];
	my $full_hostname = '';
	(grep{$_ eq $short_name} @containers ) ? ($full_hostname = "$short_name.$network_name") : ($full_hostname = "$short_name.$system_anchor_domain");
	ssh("$full_hostname", "mkdir -p /root/$deployment_name/result");
	scp("$deployment_file","root\@$full_hostname:/root/$deployment_name/result/deployment");
	scp("$tar_file","root\@$full_hostname:/root/$deployment_name/$network_name.tar.gz");
	ssh("$full_hostname", "cd /root/$deployment_name/; tar -C . -zxf $network_name.tar.gz;");
	ssh("$full_hostname", "chmod +x /root/$deployment_name/deploy.sh");
	mylog(" --- Running deploy script"); 
	ssh("$full_hostname", "/root/$deployment_name/deploy.sh $params >&2");
	mylog(" --- Removing files from remote host");
	ssh("$full_hostname", "rm -rf /root/$deployment_name/");
    }
    `rm -f $deployment_file $tar_file`;
}

sub get_userlist{
    my ($db_conn, $network_name, $userlist) = @_;
    undef %$userlist;
    my $db_result = $db_conn->prepare("SELECT status, type, username, email_prefix, first_name, last_name, password, timezone FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY id")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $db_result->bind_param(1, $network_name);
    $db_result->execute()
	or die "Couldn't execute statement: " . $db_result->errstr;
    my $i=0;
    while (my $details = $db_result->fetchrow_hashref){
	while ( my ($key, $value) = each %{$details}) {
	    ${$userlist}{$key}[$i] = $value;
	}
	$i=$i+1;
    }
    $db_result->finish;
}

sub get_domain_config_details{
    my ($db_conn, $network_name, $domain_config_details) = @_;
    $db_conn //= get_db_conn();
    my $db_result = $db_conn->prepare("SELECT config_version, email_domain, imap_server, alias_domain, website_ip FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $db_result->bind_param(1, $network_name);
    $db_result->execute()
	or die "Couldn't execute statement: " . $db_result->errstr;
    my $details = $db_result->fetchrow_hashref;
    while ( my ($key, $value) = each %{$details} ) {
	${$domain_config_details}{$key} = $value;
    }
    $db_result->finish;
}

sub generate_password{
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

sub has_capability{
    my ($capability, $capabilities) = @_;
    #Determine if capability is installed
    foreach my $cap (@$capabilities){
	if ($capability eq $cap){
	    return 1;
	}
    }
    return 0;
}

sub get_superuser_details{
    my ($db_conn, $network_name, $superuser_details) = @_;
    my $db_result = $db_conn->prepare("SELECT username, email_prefix, first_name, last_name, password FROM network.eseri_user WHERE id = (SELECT MIN(id) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?))")
        or die "Couldn't prepare statement: " . $db_conn->errstr;
    $db_result->bind_param(1, $network_name);
    $db_result->execute()
        or die "Couldn't execute statement: " . $db_result->errstr;
    my $details = $db_result->fetchrow_hashref;
    while ( my ($key, $value) = each %{$details} ) {
	${$superuser_details}{$key} = $value;
    }
    $db_result->finish;
}

sub get_deployment_xml{
    my ($xml_file, $password_nodes, $deploy_nodes) = @_;
    my $parser = XML::LibXML->new();
    if (! -f "$xml_file"){
	mylog(" - No XML config file found (expected $xml_file)");
	exit(1);
    }
    my $xml = $parser->load_xml( location => "$xml_file" );
    my $xpc = XML::LibXML::XPathContext->new( $xml );
    my $xmlschema = XML::LibXML::Schema->new( location => $xpc->findvalue( '//@xsi:schemaLocation' ) );
    eval{ $xmlschema->validate( $xml ); };
    die $@ if $@; #If validation failed, stop

    @$deploy_nodes = $xpc->findnodes('/c4:boot/deploy/arg');
    foreach my $deploy_node (@$deploy_nodes){
	$deploy_node = $deploy_node->textContent();
    }

    my @password_nodes_array = $xpc->findnodes('/c4:boot/passwords/password');
    foreach my $password_node (@password_nodes_array){
	my $name = $xpc->findvalue('@name', $password_node);
	my $host = $xpc->findvalue('@host', $password_node);
	my $entity = $xpc->findvalue('@entity', $password_node);
	${$password_nodes}{$name}{$host} = $entity;
    }
}

sub get_db_conn{
    my $conf = new Config::General("$ENV{HOME}/bin/c4.config");
    my %config = $conf->getall;
    my $DBNAME = $config{"dbname"};
    my $DBHOST = $config{"dbhost"};
    my $DBUSER = $config{"dbuser"};
    my $DBPASS = $config{"dbpass"};

    my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS")
	or die "Couldn't connect to database: " . DBI->errstr;
    return $db_conn;
}
