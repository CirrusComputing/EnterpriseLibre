#!/usr/bin/perl -w
#
# xml_rpc_service_sysman.pl - v1.0
#
# XML RPC Service for system manager requests. Responsible for creation / modification / deletion of clouds, etc
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
#use strict;

use warnings;

use RPC::XML;
use RPC::XML::Server;
use RPC::XML::Procedure;
use RPC::XML::Client;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Sys::Syslog;
use IO::CaptureOutput qw(capture capture_exec);
use threads;
use threads::shared;
use Thread::Queue;
use Config::General;
use MIME::Lite::TT::HTML;
use XML::Simple;
use XML::LibXML;
use Comms qw(get_system_anchor_domain);

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();

my $conf = new Config::General("xml_rpc_sysman.config");
my %config = $conf->getall;
for (values %config) {s|\[-system_anchor_domain-\]|$system_anchor_domain|g};

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};
my $DBKEYTAB = $config{"dbkeytab"};
my $DBPRINCIPAL = $config{"dbprincipal"};
my $MAILTEMPLATEDIR = $config{"mailtemplatedir"};
my $ERROREMAILADDRESS = $config{"erroremailaddress"};
my $FROMEMAILADDRESS = $config{"fromemailaddress"};
my $BCCEMAILADDRESS = $config{"bccemailaddress"};
my $HOSTIP = $config{"hostip"};
my $SYSMANADDRESS = $config{"sysmanaddress"};
my $SYSMANPORT = $config{"sysmanport"};
my $SYSMANPATH = $config{"sysmanpath"};
my $PROCEDURE_PREFIX = $config{"procedure_prefix"};

sub fail{
    my $output = shift;
    print STDERR "Fail: $output\n";
    openlog("System Manager XML RPC Daemon", "pid,perror", "daemon");
    syslog("info", "$output");
    closelog;	
}

sub mylog{
    my $output = shift;
    my $now = localtime;
    print STDERR "$now $output\n";
}

sub sendEmail{
    my ($userrealm, $from, $to, $cc, $bcc, $subject, $tpl_txt, $tpl_html, $params) = @_;

    # Send email
    my %options;
    $options{'INCLUDE_PATH'} = $MAILTEMPLATEDIR;
    my $msg = MIME::Lite::TT::HTML->new(
	From => $from,
	To =>  $to,
	Cc => $cc,
	Bcc => $bcc,
	Subject => $subject,
	Template => {
	    text => $tpl_txt,
	    html => $tpl_html
	},
	TmplOptions => \%options,
	TmplParams => \%$params
	);
    unless ($msg->send()) {
	mylog ("Failed to send e-mail");
    }
}

sub sendMethodFailMail{
        my ($network_name, $error_message) = @_;
        my %params;
        $params{'network_name'} = $network_name;
        $params{'error_message'} = $error_message;	
	sendEmail($network_name,
		  $FROMEMAILADDRESS,
		  $ERROREMAILADDRESS,
		  '',
		  '',
		  'Error with C3',
		  'error_c3_method.txt.tt',
		  'error_c3_method.html.tt',
		  \%params);
}

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link";

#Shared variables, queues and semaphores, etc.
my $cloud_create_queue = new Thread::Queue();
my $cloud_create_processing_thread = threads->create(\&processCloudCreate);
my $cloud_clean_queue = new Thread::Queue();
my $cloud_clean_processing_thread = threads->create(\&processCloudClean);
my $cloud_boot_queue = new Thread::Queue();
my $cloud_boot_processing_thread = threads->create(\&processCloudBoot);
my $cloud_move_queue = new Thread::Queue();
my $cloud_move_processing_thread = threads->create(\&processCloudMove);
my $ip_add_delete_queue = new Thread::Queue();
my $ip_add_delete_processing_thread = threads->create(\&processIPAddDelete);

$cloud_create_processing_thread->detach();
$cloud_clean_processing_thread->detach();
$cloud_boot_processing_thread->detach();
$cloud_move_processing_thread->detach();
$ip_add_delete_processing_thread->detach();

my $server = RPC::XML::Server->new(path => $SYSMANPATH, port => $SYSMANPORT, host => $HOSTIP) || die;

my $cloudCreateMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."cloudCreate",
						   code => \&cloudCreate,
						   signature => [ 'struct array' ] });

$server->add_method($cloudCreateMethod);

my $cloudCleanMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."cloudClean",
						  code => \&cloudClean,
						  signature => [ 'struct array' ] });

$server->add_method($cloudCleanMethod);

my $cloudBootMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."cloudBoot",
						  code => \&cloudBoot,
						  signature => [ 'struct array' ] });

$server->add_method($cloudBootMethod);

my $cloudMoveMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."cloudMove",
						  code => \&cloudMove,
						  signature => [ 'struct array' ] });

$server->add_method($cloudMoveMethod);

my $ipAddDeleteMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."ipAddDelete",
						   code => \&ipAddDelete,
						   signature => [ 'struct array' ] });

$server->add_method($ipAddDeleteMethod);

$server->server_loop();

sub processCloudCreate{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    while(1){
	my $cloud_create = $cloud_create_queue->dequeue();
	my $email = $cloud_create->[0];

	my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
	my $root = $doc->createElement("organization");
	my %tags = (
	    full_name => '',
	    domain => '',
	    username => 'superuser',
	    firstname => 'Super',
	    lastname => 'User',
	    email => $email,
	    timezone => 'America/Toronto',
	    );
	
	for my $name (keys %tags) {
	    my $tag = $doc->createElement($name);
	    my $value = $tags{$name};
	    $tag->appendTextNode($value);
	    $root->appendChild($tag);
	}
	
	$doc->setDocumentElement($root);
	
	my $insert_c4_aleph_queue = $tdb_conn->prepare("INSERT INTO loginsite.org_queue (data) VALUES (?)")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	$insert_c4_aleph_queue->bind_param(1, $doc->toString());
	$insert_c4_aleph_queue->execute()
	    or die "Couldn't execute statement: " . $insert_c4_aleph_queue->errstr;
    }
}

sub processCloudClean{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    while(1){
	my $cloud_clean = $cloud_clean_queue->dequeue();
	my $network_name = $cloud_clean->[0];
	
	my ($cloud_short_name) = $tdb_conn->selectall_arrayref("SELECT short_name FROM network.organization WHERE network_name = ?", {}, $network_name)->[0]->[0];
	unless($cloud_short_name){
	    sendMethodFailMail($network_name, "processCloudClean method failed - Cloud record does not exist in db");
	    fail("Cloud record does not exist in db.");
	}	    
	else{
	    `ssh c4\@c4.$system_anchor_domain 'cd bin; echo "yes" | ./cleanup/clean${cloud_short_name}.sh "DELETE" >> /var/log/c4/cleanup.log 2>&1'`;
	    my $exit_code = $?;
	    if ($exit_code != 0){
		sendMethodFailMail($network_name, "processCloudClean method failed - ./clean${cloud_short_name}.sh");
		fail("clean${cloud_short_name}.sh returned $exit_code");
	    }
	}
    }
}

sub processCloudBoot{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    while(1){
	my $cloud_boot = $cloud_boot_queue->dequeue();
	my $network_name = $cloud_boot->[0];
	my $boot_action = $cloud_boot->[1];
	
	`ssh c4\@c4.$system_anchor_domain 'cd bin/; ./cloud_boot.pl --network_name "$network_name" --boot_action "$boot_action" >> /var/log/c4/cloud_boot.log 2>&1'`;
	
	my $exit_code = $?;
	if ($exit_code != 0){
	    sendMethodFailMail($network_name, "processCloudBoot method failed - ./cloud_boot.pl failed");
	    fail("cloud_boot.pl returned $exit_code");
	}
    }
}

sub processCloudMove{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    while(1){
	my $cloud_move = $cloud_move_queue->dequeue();
	my $network_name = $cloud_move->[0];
	my $server = $cloud_move->[1];
	my $phase = $cloud_move->[2];
	
	`ssh c4\@c4.$system_anchor_domain 'cd bin/; ./cloud_move.pl --network_name "$network_name" --new_hardware_host "$server" --phase "$phase" >> /var/log/c4/cloud_move.log 2>&1'`;
	
	my $exit_code = $?;
	if ($exit_code != 0){
	    sendMethodFailMail($network_name, "processCloudMove method failed - ./cloud_move.pl failed");
	    fail("cloud_move.pl returned $exit_code");
	}
    }
}

sub processIPAddDelete{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    while(1){
	my $ip_add_delete = $ip_add_delete_queue->dequeue();
	my $option = $ip_add_delete->[0];
	my $ip_address = $ip_add_delete->[1];
	my $subnet_mask = $ip_add_delete->[2];

	my $add_delete_ip_address_pool;
	my $add_delete_ip_hwh_ips;
		
	if ($option eq 'add'){
	    $add_delete_ip_address_pool = $tdb_conn->prepare("INSERT INTO network.address_pool VALUES (?,?,NULL,NULL)")
		or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	    $add_delete_ip_hwh_ips = $tdb_conn->prepare("INSERT INTO network.hwh_ips VALUES (?,?)")
		or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	}
	elsif ($option eq 'delete'){
	    $add_delete_ip_address_pool = $tdb_conn->prepare("DELETE FROM network.address_pool WHERE address = ? AND netmask = ? AND server IS NULL AND organization IS NULL")
		or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	    $add_delete_ip_hwh_ips = $tdb_conn->prepare("DELETE FROM network.hwh_ips WHERE serverid = ? AND address = ?")
		or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	}

	$add_delete_ip_address_pool->bind_param(1, $ip_address);
	$add_delete_ip_address_pool->bind_param(2, $subnet_mask);
	$add_delete_ip_address_pool->execute()
	    or die "Couldn't execute statement: " . $add_delete_ip_address_pool->errstr;

	$add_delete_ip_hwh_ips->bind_param(1, 1, SQL_INTEGER);
	$add_delete_ip_hwh_ips->bind_param(2, $ip_address);
	$add_delete_ip_hwh_ips->execute()
	    or die "Couldn't execute statement: " . $add_delete_ip_hwh_ips->errstr;
    }
}

sub cloudCreate{
    my ($params) = @_;
    my $email = @$params[0];
    
    mylog("Remote call to create new cloud for ".$email);
    
    my @params_vars :shared;
    $params_vars[0] = "$email";
    my $var_ref :shared;
    $var_ref = \@params_vars;
    $cloud_create_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Create new cloud for ".$email)});
    return $resultRef;
}

sub cloudClean{
    my ($params) = @_;
    my $network_name = @$params[0];
    
    mylog("Remote call to cleanup cloud with cirrus domain ".$network_name);
    
    my @params_vars :shared;
    $params_vars[0] = "$network_name";
    my $var_ref :shared;
    $var_ref = \@params_vars;
    $cloud_clean_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Clean cloud with cirrus domain ".$network_name)});
    return $resultRef;
}

sub cloudBoot{
    my ($params) = @_;
    my $network_name = @$params[0];
    my $boot_action = @$params[1];
    
    mylog("Remote call to *$boot_action* cloud with cirrus domain ".$network_name);
    
    my @params_vars :shared;
    $params_vars[0] = "$network_name";
    $params_vars[1] = "$boot_action";
    my $var_ref :shared;
    $var_ref = \@params_vars;
    $cloud_boot_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Trigger $boot_action for cloud with cirrus domain ".$network_name)});
    return $resultRef;
}

sub cloudMove{
    my ($params) = @_;
    my $network_name = @$params[0];
    my $server = @$params[1];
    my $phase = @$params[2];
    
    mylog("Remote call to move cloud ".$network_name." to server ".$server." with phase ".$phase);
    
    my @params_vars :shared;
    $params_vars[0] = "$network_name";
    $params_vars[1] = "$server";
    $params_vars[2] = "$phase";
    my $var_ref :shared;
    $var_ref = \@params_vars;
    $cloud_move_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Move cloud ".$network_name." to server ".$server. " with phase ".$phase)});
    return $resultRef;
}

sub ipAddDelete{
    my ($params) = @_;
    my $option = @$params[0];
    my $ip_address = @$params[1];
    my $subnet_mask = @$params[2];

    # Removing first character.
    $ip_address =~  s/^.//;
    $subnet_mask =~ s/^.//;

    mylog("Remote call to ".$option." IP Address ".$ip_address. " with subnet mask ".$subnet_mask);
    
    my @params_vars :shared;
    $params_vars[0] = "$option";
    $params_vars[1] = "$ip_address";
    $params_vars[2] = "$subnet_mask";
    my $var_ref :shared;
    $var_ref = \@params_vars;
    $ip_add_delete_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string($option." IP Address ".$ip_address." with subnet_mask".$subnet_mask)});
    return $resultRef;
}
