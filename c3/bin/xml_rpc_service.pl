#!/usr/bin/perl -w
#
# xml_rpc_service.pl - v9.3
#
# XML RPC Service for C3 host. Responsible for creation of new users, Changing user passwords, deleting old users, etc
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
use MIME::Lite::TT;
use MIME::Lite::TT::HTML;
use XML::Simple;
use Comms qw(ssh_key get_system_anchor_domain);

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();
my $conf = new Config::General("xml_rpc.config");
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
my $C3ADDRESS = $config{"c3address"};
my $C3PORT = $config{"c3port"};
my $C3PATH = $config{"c3path"};
my $PROCEDURE_PREFIX = $config{"procedure_prefix"};

sub fail{
	my $output = shift;
	print STDERR "Fail: $output\n";
	if ( defined $db_log &&  defined $output){
		$db_log->bind_param(1, $output);
		my $res = $db_log->execute();
	}
	openlog("C3 XML RPC Daemon", "pid,perror", "daemon");
	syslog("info", "$output");
	closelog;	
}

sub mylog{
	my $output = shift;
	my $now = localtime;
	print STDERR "$now $output\n";
	$db_log->bind_param(1, $output);
	my $res = $db_log->execute();
	if (! $res){
		fail("Could not write to DB log: $DBI::errstr");
	}
}

my $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link";
$db_log = $db_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle";

#Shared variables, queues and semaphores, etc.
my $new_user_queue = new Thread::Queue();
my $user_processing_thread = threads->create(\&processNewUsers);
my $change_password_queue = new Thread::Queue();
my $password_processing_thread = threads->create(\&processChangeUserPasswords);
my $delete_user_queue = new Thread::Queue();
my $delete_user_processing_thread = threads->create(\&processDeleteUsers);
my $archive_user_queue = new Thread::Queue();
my $archive_user_processing_thread = threads->create(\&processArchiveUsers);
my $restore_user_queue = new Thread::Queue();
my $restore_user_processing_thread = threads->create(\&processRestoreUsers);
my $reset_user_queue = new Thread::Queue();
my $reset_user_processing_thread = threads->create(\&processResetUsers);
my $change_externalemail_queue = new Thread::Queue();
my $externalemail_processing_thread = threads->create(\&processChangeExternalEmail);
my $change_dloption_queue = new Thread::Queue();
my $dloption_processing_thread = threads->create(\&processChangeDLOption);
my $domain_config_queue = new Thread::Queue();
my $domainconfig_processing_thread = threads->create(\&processDomainConfig);
my $cloudcapabilityconfig_queue = new Thread::Queue();
my $cloudcapabilityconfig_processing_thread = threads->create(\&processCloudCapabilityConfig);
my $insert_cloud_manager_req_queue = new Thread::Queue();
my $insertcloudmanagerreq_processing_thread = threads->create(\&processInsertCloudManagerReq);
my $process_cloud_manager_req_queue = new Thread::Queue();
my $processcloudmanagerreq_processing_thread = threads->create(\&processProcessCloudManagerReq);
my $timezone_config_queue = new Thread::Queue();
my $timezoneconfig_processing_thread = threads->create(\&processTimezoneConfig);
my $firewallproxy_config_queue = new Thread::Queue();
my $firewallproxyconfig_processing_thread = threads->create(\&processFirewallProxyConfig);
my $cloudreboot_queue = new Thread::Queue();
my $cloudreboot_processing_thread = threads->create(\&processCloudReboot);
my $useraliasconfig_queue = new Thread::Queue();
my $useraliasconfig_processing_thread = threads->create(\&processUserAliasConfig);
my $userprimaryemailconfig_queue = new Thread::Queue();
my $userprimaryemailconfig_processing_thread = threads->create(\&processUserPrimaryEmailConfig);
my $userfullnameconfig_queue = new Thread::Queue();
my $userfullnameconfig_processing_thread = threads->create(\&processUserFullnameConfig);
my $changeusertype_queue = new Thread::Queue();
my $changeusertype_processing_thread = threads->create(\&processChangeUserType);
my $firewallportconfig_queue = new Thread::Queue();
my $firewallportconfig_processing_thread = threads->create(\&processFirewallPortConfig);
my $backupconfig_queue = new Thread::Queue();
my $backupconfig_processing_thread = threads->create(\&processBackupConfig);
my $restorefilepath_queue = new Thread::Queue();
my $restorefilepath_processing_thread = threads->create(\&processRestoreFilePath);
my $system_anchor_config_queue = new Thread::Queue();
my $systemanchorconfig_processing_thread = threads->create(\&processSystemAnchorConfig);

$user_processing_thread->detach();
$password_processing_thread->detach();
$delete_user_processing_thread->detach();
$archive_user_processing_thread->detach();
$restore_user_processing_thread->detach();
$reset_user_processing_thread->detach();
$externalemail_processing_thread->detach();
$dloption_processing_thread->detach();
$domainconfig_processing_thread->detach();
$cloudcapabilityconfig_processing_thread->detach();
$insertcloudmanagerreq_processing_thread->detach();
$processcloudmanagerreq_processing_thread->detach();
$timezoneconfig_processing_thread->detach();
$firewallproxyconfig_processing_thread->detach();
$cloudreboot_processing_thread->detach();
$useraliasconfig_processing_thread->detach();
$userfullnameconfig_processing_thread->detach();
$changeusertype_processing_thread->detach();
$firewallportconfig_processing_thread->detach();
$backupconfig_processing_thread->detach();
$restorefilepath_processing_thread->detach();
$systemanchorconfig_processing_thread->detach();

my $server = RPC::XML::Server->new(path => $C3PATH, port => $C3PORT, host => $HOSTIP) || die;

my $createNewUserMethod = RPC::XML::Procedure->new({ name => $PROCEDURE_PREFIX."createNewUser",
	code => \&createNewUser,
	signature => [ 'struct string string string string string string string' ] });

$server->add_method($createNewUserMethod);

my $changeUserPasswordMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeUserPassword",
	code => \&changeUserPassword,
	signature => [ 'struct string string string' ]});

$server->add_method($changeUserPasswordMethod);

my $deleteUserMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."deleteUser",
	code => \&deleteUser,
	signature => [ 'struct string string' ]});

$server->add_method($deleteUserMethod);

my $archiveUserMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."archiveUser",
	code => \&archiveUser,
	signature => [ 'struct string string' ]});

$server->add_method($archiveUserMethod);

my $restoreUserMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."restoreUser",
	code => \&restoreUser,
	signature => [ 'struct string string' ]});

$server->add_method($restoreUserMethod);

my $resetUserMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."resetDesktop",
	code => \&resetUser,
	signature => [ 'struct string string' ]});

$server->add_method($resetUserMethod);

my $changeExternalEmailMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeExternalEmail",
        code => \&changeExternalEmail,
        signature => [ 'struct string string string' ]});

$server->add_method($changeExternalEmailMethod);

my $changeDLOptionMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeDLOption",
        code => \&changeDLOption,
        signature => [ 'struct string string string' ]});

$server->add_method($changeDLOptionMethod);

my $changeDomainConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeDomainConfig",
        code => \&changeDomainConfig,
        signature => [ 'struct string string array' ]});

$server->add_method($changeDomainConfigMethod);

my $changeCloudCapabilityConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeCloudCapabilityConfig",
        code => \&changeCloudCapabilityConfig,
        signature => [ 'struct string array array' ]});

$server->add_method($changeCloudCapabilityConfigMethod);

my $insertCloudManagerReqMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."insertCloudManagerReq",
        code => \&insertCloudManagerReq,
        signature => [ 'struct string string string string double' ]});

$server->add_method($insertCloudManagerReqMethod);

my $processCloudManagerReqMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."processCloudManagerReq",
        code => \&processCloudManagerReq,
	signature => [ 'struct string string' ]});

$server->add_method($processCloudManagerReqMethod);

my $changeTimezoneConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeTimezoneConfig",
        code => \&changeTimezoneConfig,
        signature => [ 'struct string string string string' ]});

$server->add_method($changeTimezoneConfigMethod);

my $changeFirewallProxyConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeFirewallProxyConfig",
        code => \&changeFirewallProxyConfig,
        signature => [ 'struct string array array array' ]});

$server->add_method($changeFirewallProxyConfigMethod);

my $cloudRebootMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."cloudReboot",
	code => \&cloudReboot,
	signature => [ 'struct string' ]});

$server->add_method($cloudRebootMethod);

my $changeUserAliasConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeUserAliasConfig",
	code => \&changeUserAliasConfig,
	signature => [ 'struct string string string string' ]});

$server->add_method($changeUserAliasConfigMethod);

my $changeUserPrimaryEmailConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeUserPrimaryEmailConfig",
	code => \&changeUserPrimaryEmailConfig,
	signature => [ 'struct string array array array' ]});

$server->add_method($changeUserPrimaryEmailConfigMethod);

my $changeUserFullnameConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeUserFullnameConfig",
	code => \&changeUserFullnameConfig,
	signature => [ 'struct string array array array array array' ]});

$server->add_method($changeUserFullnameConfigMethod);

my $changeUserTypeMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeUserType",
	code => \&changeUserType,
	signature => [ 'struct string array' ]});

$server->add_method($changeUserTypeMethod);

my $changeFirewallPortConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeFirewallPortConfig",
	code => \&changeFirewallPortConfig,
	signature => [ 'struct string array' ]});

$server->add_method($changeFirewallPortConfigMethod);

my $changeBackupConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeBackupConfig",
	code => \&changeBackupConfig,
	signature => [ 'struct string array' ]});

$server->add_method($changeBackupConfigMethod);

my $restoreFilePathMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."restoreFilePath",
	code => \&restoreFilePath,
	signature => [ 'struct string array' ]});

$server->add_method($restoreFilePathMethod);

my $changeSystemAnchorConfigMethod = RPC::XML::Procedure->new({name => $PROCEDURE_PREFIX."changeSystemAnchorConfig",
        code => \&changeSystemAnchorConfig,
        signature => [ 'struct string array' ]});

$server->add_method($changeSystemAnchorConfigMethod);

$server->server_loop();

sub makePassword{
	#Code is copied verbatim from c4.pl, which was copied from old vault system
	#Added on 19 Sept 2012 to avoid confusiong between characters ("0","1","o","O","l","I")
	my @char_pool = ("a" .. "k");
	push (@char_pool, ("m" .. "n"));
	push (@char_pool, ("p" .. "z"));
	push (@char_pool, ("A" .. "H"));
	push (@char_pool, ("J" .. "N"));
	push (@char_pool, ("P" .. "Z"));
	push (@char_pool, (2 .. 9));

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

sub makeUsername{
	my ($eprefix, $urealm) = @_ ;
	#Only allow characters in char_pool
	my @char_pool = ("a" .. "z");
	push (@char_pool, (0 .. 9));
	my $username = "";
	my $character = "";
	for (my $i=0; $i < length($eprefix); $i++){
	        $character = substr($eprefix, $i, 1);
	        if (grep $_ eq $character, @char_pool){
        	        $username .= $character;
	        }
	}

	#Limit username to only 32 characters
	$username = substr($username, 0 , 32);

	#Check for conflict
	my $db_st = $db_conn->prepare("SELECT COUNT(id) FROM network.eseri_user WHERE organization = (select id from network.organization where network_name = ?) and username = ?");
        $db_st->bind_param(1, lc($urealm));
        $db_st->bind_param(2, lc($username));
        my $res = $db_st->execute();

        my $counter = 1;
        my $temp = $username;
	#If username exists in the database, then keep adding numbers from 1-99, but also limit no of characters to 32
        while ($db_st->fetchrow_array ne '0'){
                $temp = $username;
                        if ($counter == 99){
                                return '';
                        }
                        if (length($temp) > 30){
                      		$temp = substr($temp, 0, (32-length($counter)));
                        }
                        $temp .=$counter;
                        $counter += 1;
                        $db_st->bind_param(1, lc($urealm));
                        $db_st->bind_param(2, lc($temp));
                        $res = $db_st->execute();
                }
        $username = $temp;
	return $username;
}

sub realToAddress{
    my ($to) = @_;
    # Additional code to make sure that email is not sent to the superuser's cloud address incase domain version is 2.11 or 2.12
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my ($domain_config_version) = $tdb_conn->selectall_arrayref("SELECT config_version FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];

    if ( defined $domain_config_version and ( $domain_config_version eq '2.11' or $domain_config_version eq '2.12' )){
	my ($admin_details) = getUserDetails($userrealm, 'admin');
	my ($email_prefix, $domain) = split(/@/, $to);
	if ($email_prefix eq $admin_details->{'email_prefix'} and $domain eq $admin_details->{'email_domain'}){
	    mylog("Since domain config version for $userrealm is $domain_config_version, sending email to the superuser notify address instead");
	    my ($admin_details) = getUserDetails($userrealm, 'admin');
	    $to = $admin_details->{'real_email'};
	}
    }
    return $to;
}

sub sendEmail{
    my ($userrealm, $from, $to, $cc, $bcc, $subject, $tpl_txt, $tpl_html, $params) = @_;
    $to = realToAddress($to);
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

sub sendEmailAttachment{
    my ($userrealm, $from, $to, $cc, $bcc, $subject, $tpl_html, $content_type, $att_type, $att_path, $att_name, $params) = @_;
    $to = realToAddress($to);
    # Send email
    my %options;
    $options{'INCLUDE_PATH'} = $MAILTEMPLATEDIR;
    my $msg;
    $msg = MIME::Lite::TT->new(
	From => $from,
	To =>  $to,
	Cc => $cc,
	Bcc => $bcc,
	Subject => $subject,
	Template => $tpl_html,
	TmplOptions => \%options,
	TmplParams => \%$params
	);
    $msg->attr('content-type', $content_type);
    $msg->attach (
	Encoding => 'base64',
	Type => $att_type,
	Path => "$att_path/$att_name",
	Filename => $att_name,
	Id => $att_name,
	Disposition => 'inline'
	) or die "Error adding : $!\n";

    unless ($msg->send()) {
	mylog ("Failed to send e-mail");
    }

    ($att_path eq '/tmp') ? (`rm -f "$att_path/$att_name"`) : ();
}

sub sendUserFailMail{
	my ($username, $email_prefix, $userrealm, $error_message) = @_;
	my %params;
	$params{'username'} = $username;
	$params{'email_prefix'} = $email_prefix;
	$params{'network_name'} = $userrealm;
	$params{'error_message'} = $error_message;
	sendEmail($userrealm,
		  $FROMEMAILADDRESS,
		  $ERROREMAILADDRESS,
		  '',
		  '',
		  'Error creating user',
		  'error_user_creation.txt.tt',
		  'error_user_creation.html.tt',
		  \%params);
	if ( -f "/tmp/failure.JPG" ) {
		unlink("/tmp/failure.JPG");
	}
}

sub sendMethodFailMail{
        my ($userrealm, $error_message) = @_;
        my %params;
        $params{'network_name'} = $userrealm;
        $params{'error_message'} = $error_message;	
	sendEmail($userrealm,
		  $FROMEMAILADDRESS,
		  $ERROREMAILADDRESS,
		  '',
		  '',
		  'Error with C3',
		  'error_c3_method.txt.tt',
		  'error_c3_method.html.tt',
		  \%params);
}

sub getUserDetails{
    my ($userrealm, $user, $username) = @_;
    $username //= '';
    my $info;
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    if ($user eq 'admin'){
	#Getting the Super User details from the database.
	my $admin_info = $tdb_conn->prepare("SELECT a.username, a.email_prefix, a.first_name, a.last_name, a.real_email, a.timezone, b.email_domain FROM network.eseri_user_public AS a, network.organization AS b WHERE a.id = (SELECT MIN(id) FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)) AND b.network_name = ?")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
        $admin_info->bind_param(1, $userrealm);
	$admin_info->bind_param(2, $userrealm);
        $admin_info->execute()
	    or die "Couldn't prepare statement: " . $admin_info->errstr;
	my $admin_details = $admin_info->fetchrow_hashref();
	$admin_info->finish;
	return $admin_details;
    }
    elsif ($user eq 'user'){
	#Getting the User details from the database.
	my $user_info = $tdb_conn->prepare("SELECT a.username, a.email_prefix, a.first_name, a.last_name, a.real_email, a.timezone, b.email_domain FROM network.eseri_user_public AS a, network.organization AS b WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?) and b.network_name = ?")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
        $user_info->bind_param(1, $username);
        $user_info->bind_param(2, $userrealm);
        $user_info->bind_param(3, $userrealm);
        $user_info->execute()
	    or die "Couldn't prepare statement: " . $user_info->errstr;
	my $user_details = $user_info->fetchrow_hashref();
	$user_info->finish;
	return $user_details;
    }
}

sub sendCloudCapabilityMail{
	my ($userrealm) = @_;
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";

	my %params;
	my $subject = '';
	my $template = '';

	my $cap_result = $tdb_conn->selectall_arrayref("SELECT name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id from network.organization WHERE network_name=?) and enabled = ?)", {}, $userrealm, "t");
	
	my $uses_orangehrm = 0;
	my $uses_mailman = 0;
	my $uses_nuxeo = 0;
	my $uses_wiki = 0;
	my $uses_timesheet = 0;
	my $uses_trac = 0;
	my $uses_vtiger = 0;
	my $uses_sqlledger = 0;
	my $uses_churchinfo = 0;
	my $uses_civicrm = 0;
	my $uses_moodle = 0;
	my $uses_openerp = 0;
	mylog("Iterating capabilities");
	foreach my $cap (@{ $cap_result }){
	    if ($cap->[0] eq 'MailingLists'){$uses_mailman = 1;}
	    if ($cap->[0] eq 'OrangeHRM'){$uses_orangehrm = 1;}
	    if ($cap->[0] eq 'Trac'){$uses_trac = 1;}
	    if ($cap->[0] eq 'Wiki'){$uses_wiki = 1;}
	    if ($cap->[0] eq 'Vtiger'){$uses_vtiger = 1;}
	    if ($cap->[0] eq 'Nuxeo'){$uses_nuxeo = 1;}
	    if ($cap->[0] eq 'Timesheet'){$uses_timesheet = 1;}
	    if ($cap->[0] eq 'SQLLedger'){$uses_sqlledger = 1;}
	    if ($cap->[0] eq 'ChurchInfo'){$uses_churchinfo = 1;}
	    if ($cap->[0] eq 'CiviCRM'){$uses_civicrm = 1;}
	    if ($cap->[0] eq 'Moodle'){$uses_moodle = 1;}
	    if ($cap->[0] eq 'OpenERP'){$uses_openerp = 1;}
	}
	mylog("Preparing e-mail parameters");
	$params{'mailman'} = $uses_mailman;
	$params{'orangehrm'} = $uses_orangehrm;
	$params{'vtiger'} = $uses_vtiger;
	$params{'wiki'} = $uses_wiki;
	$params{'trac'} = $uses_trac;
	$params{'timesheet'} = $uses_timesheet;
	$params{'nuxeo'} = $uses_nuxeo;
	$params{'sqlledger'} = $uses_sqlledger;
	$params{'churchinfo'} = $uses_churchinfo;
	$params{'civicrm'} = $uses_civicrm;
	$params{'moodle'} = $uses_moodle;
	$params{'openerp'} = $uses_openerp;
	if ($uses_mailman) {
	    my $mman_create_pw_sql = << 'END_SQL2';
	    SELECT password 
		FROM vault.passwords 
		WHERE host = 'mailman' 
		AND entity = ?
		AND organization = (
		    SELECT id 
		    FROM network.organization 
		    WHERE network_name = ?
		)
END_SQL2
		my $vault_entity = 'listcreate';
	    my $mman_pw = $tdb_conn->selectall_arrayref( $mman_create_pw_sql, {}, $vault_entity, $userrealm)->[0]->[0];
	    $params{'mailman_create_password'} = $mman_pw;
	    
	    $vault_entity = 'mailman';
	    $mman_pw    = $tdb_conn->selectall_arrayref( $mman_create_pw_sql, {}, $vault_entity, $userrealm)->[0]->[0];
	    $params{'mailman_password'} = $mman_pw;
	}
	if ($uses_orangehrm) {
	    my $orangehrm_pw = $tdb_conn->selectall_arrayref("SELECT password FROM vault.passwords WHERE host = 'poseidon' AND entity = 'OrangeHRM Admin' AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
	    $params{'orangehrm_password'} = $orangehrm_pw;
	}
	if ($uses_sqlledger) {
	    my $sqlledger_pw = $tdb_conn->selectall_arrayref("SELECT password FROM vault.passwords WHERE host = 'sqlledger' AND entity = 'admin' AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
	    $params{'sqlledger_password'} = $sqlledger_pw;
	}
	if ($uses_openerp) {
	    my $openerp_master_pw = $tdb_conn->selectall_arrayref("SELECT password FROM vault.passwords WHERE host = 'openerp' AND entity = 'master' AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
	    $params{'openerp_master_password'} = $openerp_master_pw;
	}

	$subject = 'Your cloud in EnterpriseLibre';
	$template = 'cloudcapability_config_message_itman';
	
	#Getting the Super User details from the database.
        my ($admin_details) = getUserDetails($userrealm, 'admin');	
        $params{'first_name'} = $admin_details->{'first_name'};
        $params{'last_name'} = $admin_details->{'last_name'};
        $params{'username'} = $admin_details->{'username'};

	sendEmail($userrealm,
		  $FROMEMAILADDRESS,
                  $admin_details->{'email_prefix'} . "@" . $admin_details->{'email_domain'},
                  '',
                  $BCCEMAILADDRESS,
                  $subject,
                  "$template" . '.txt.tt',
                  "$template" . '.html.tt',
                  \%params);
}

sub getUserStatus{
	my ($userrealm) = @_;
	my $processing = 0;
	my $get_user_status = $db_conn->prepare("SELECT status FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY id DESC")
               or die "Couldn't prepare statement: " . $db_conn->errstr;
        $get_user_status->bind_param(1, $userrealm);
        $get_user_status->execute()
                or die "Couldn't prepare statement: " . $get_user_status->errstr;
	while (my ($user_status) = $get_user_status->fetchrow_array()){
		if($user_status eq 'PROCESSING'){
			$processing = 1;	
		}
	}
	return $processing;
}

sub getCloudStatus{
	my ($userrealm, $exclude) = @_;
	$exclude //= '';
        my $processing = 0;
	my $get_cloud_config_status = $db_conn->prepare("SELECT dc, ccc, tzc, fpc, bc FROM network.organization_config_status WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
               or die "Couldn't prepare statement: " . $db_conn->errstr;
        $get_cloud_config_status->bind_param(1, $userrealm);
        $get_cloud_config_status->execute()
                or die "Couldn't prepare statement: " . $get_cloud_config_status->errstr;
	my ($dc_status, $ccc_status, $tzc_status, $fpc_status) = $get_cloud_config_status->fetchrow_array();
        $get_cloud_config_status->finish;

	if((defined $dc_status and $dc_status ne 'ACTIVE' and $exclude ne 'dc') or (defined $pcc_status and $pcc_status ne 'ACTIVE' and $exclude ne 'pcc')){
		$processing = 1;
	}
	
	return $processing;
}

sub sendAdminProcessingMail{
	my ($userrealm, $error_message) = @_;
        my %params;
	my ($admin_details) = getUserDetails($userrealm, 'admin');
        $params{'first_name'} = $admin_details->{'first_name'};
        $params{'last_name'} = $admin_details->{'last_name'};
	$params{'error_message'} = $error_message;
	sendEmail($userrealm,
		  $FROMEMAILADDRESS,
		  $admin_details->{'email_prefix'} . "@" . $admin_details->{'email_domain'},
                  '',
                  $ERROREMAILADDRESS,
                  'Cloud Information',
                  'cloud_processing_message.txt.tt',
		  'cloud_processing_message.html.tt',
                  \%params);
}

sub eseriArchiveAccountExecute{
    my ($tdb_conn, $userrealm, $username, $method) = @_;
    my $host = "chaos.$userrealm";
    ssh_key($host);
    `ssh eseriman\@$host ./bin/eseriArchiveAccount "$username"`;
    my $archive_exit_code = $?;
    if ($archive_exit_code != 0){
	my $archive_failed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'ARCHIVING_FAILED' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
	$archive_failed->bind_param(1, $username);
	$archive_failed->bind_param(2, $userrealm);
	$archive_failed->execute();
	sendMethodFailMail($userrealm, "$method method failed - ./bin/eseriArchiveAccount failed");
	fail("eseriArchiveAccount returned $archive_exit_code");
    }
    mylog("Successfully archived user $username in realm $userrealm");
    #Now reboot their desktop to let archiving take effect
    eseriKillNXSessionExecute($userrealm, $username, $method);
}

sub eseriKillNXSessionExecute{
    my ($userrealm, $username, $method) = @_;
    my $host = "chaos.$userrealm";
    mylog("About to call eseriKillNXSession");
    ssh_key($host);
    `ssh eseriman\@$host sudo ./bin/eseriKillNXSession "$username" --killall`;
    my $killnxsession_exit_code = $?;
    if ($killnxsession_exit_code != 0){
	sendMethodFailMail($userrealm, "$method method failed - ./bin/eseriKillNXSession");
	fail("eseriKillNXSession returned $killnxsession_exit_code");
    }
}

sub eseriRestoreAccountExecute{
    my ($tdb_conn, $userrealm, $username, $method) = @_;
    my $host = "chaos.$userrealm";
    ssh_key($host);
    `ssh eseriman\@$host ./bin/eseriRestoreAccount "$username"`;
    my $restore_exit_code = $?;
    if ($restore_exit_code != 0){
	my $restore_failed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'ACTIVATING_FAILED' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
	$restore_failed->bind_param(1, $username);
	$restore_failed->bind_param(2, $userrealm);
	$restore_failed->execute();
	sendMethodFailMail($userrealm, "$method method failed - ./bin/eseriRestoreAccount failed");
	fail("eseriRestoreAccount returned $restore_exit_code");
    }
    mylog("Successfully restored user $username in realm $userrealm");
}    

sub eseriUpdateDovecotPassDBFileExecute{
    my ($userrealm, $username, $password, $new_user_type, $status, $method) = @_;
    my $host = "chaos.$userrealm";
    mylog("Update Dovecot PassDB File at $userrealm");
    ssh_key($host);
    `ssh eseriman\@$host sudo ./bin/eseriUpdateDovecotPassDBFile "$username" "$password" "$new_user_type" "$status"`;
    my $updatedovecotpassdbfile_exit_code = $?;
    if ($updatedovecotpassdbfile_exit_code != 0){
	sendMethodFailMail($userrealm, "$method method failed for $new_user_type");
	fail("eseriUpdateDovecotPassDBFile failed with exit code $updatedovecotpassdbfile_exit_code");
    }
}

sub processNewUsers{
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
	my $tdb_log; 
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		my $newUser = $new_user_queue->dequeue();
		my $username = $newUser->[0];
		my $email_prefix = $newUser->[1];
		my $userrealm = $newUser->[2];
		my $first_name = $newUser->[3];
		my $last_name = $newUser->[4];
		my $user_email = $newUser->[5];
		my $user_type = $newUser->[6];
		our $db_log = $tdb_log;
		#Find out the user id of the user inserted for us
		my $userid = $tdb_conn->selectall_arrayref("SELECT id FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND username = ?", {}, $userrealm, $username)->[0]->[0];
		my $num_users = $tdb_conn->prepare("SELECT count(*) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
		$num_users->bind_param(1, $userrealm);
		$num_users->execute();
		my ($number_of_users) = $num_users->fetchrow();
		#Getting the Super User details from the database.
		my ($admin_details) = getUserDetails($userrealm, 'admin');

		my $cloud_domain = $admin_details->{'email_domain'};
		system("./personalize_desktop.pl", "--username", "$username", "--desired_email_prefix", "$email_prefix", "--network_name", "$userrealm", "--verbose");
		my $user_status = $tdb_conn->selectall_arrayref("SELECT status FROM network.eseri_user WHERE id = ?", {}, $userid)->[0]->[0];
		if ($user_status ne "ACTIVE"){
			mylog("personalize_desktop failed, status was $user_status");
			my $set_failed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'PROCESSING_FAILED' WHERE id = ?");
			$set_failed->bind_param(1, $userid);
			$set_failed->execute();
			sendUserFailMail($username, $email_prefix, $userrealm, "personalize_desktop failed, status was PROCESSING_FAILED");
			fail("fail user is $username $userrealm"); # fail("Exit code is $exit_code");
		}
		else{
		        my $password_query = $tdb_conn->prepare("SELECT password FROM network.eseri_user WHERE id = ?");
			$password_query->bind_param(1, $userid);
			$password_query->execute();
			my ($password) = $password_query->fetchrow();

        	        my $host = "chaos.$userrealm";
			mylog("Calling eseriman script to create new pam_obc.conf file for $host");
			ssh_key($host);
			`ssh eseriman\@$host sudo ./bin/eseriCreatePamObcConf 1`;
			my $exit_code = $?;
			if ($exit_code != 0){
			    sendMethodFailMail($userrealm, "processNewUsers method failed - ./bin/eseriCreatePamObcConf failed");
			    fail("eseriNewUsers returned $exit_code");
			}

			# Change Dovecot PassDB file which resides at hera
			if ($user_type eq 'email_only'){
			    eseriUpdateDovecotPassDBFileExecute($userrealm, $username, $password, $user_type, $user_status, 'processNewUsers');
			}

			if ($number_of_users == 1){
			    mylog("Setting up postmaster alias for super user");
			    ssh_key($host);
			    `ssh eseriman\@$host sudo ./bin/eseriAddAlternateEmail "$username" "postmaster\@$userrealm"`;
			    
			    mylog("Expanding 'On This Computer' tree in evolution for super user");
			    ssh_key($host);
			    `sshpass -p "$password" ssh $username\@$host "sed -i 's|<node name=\\\"local\\\" expand=\\\"false\\\"/>|<node name=\\\"local\\\" expand=\\\"true\\\"/>|' /home/$username/.evolution/mail/config/folder-tree-expand-state.xml"`;

			    # Sending email to admin with new password details
			    sendCloudCapabilityMail($userrealm);
			}

			my $caps = $tdb_conn->selectall_arrayref("SELECT name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id from network.organization WHERE network_name=?) and enabled = ?)", {}, $userrealm, "t");
			my $uses_x2go = 0;
			my $uses_nomachine = 0;
			foreach my $cap (@{ $caps }){
			    if ($cap->[0] eq 'X2Go'){$uses_x2go = 1;}
			    if ($cap->[0] eq 'NoMachine'){$uses_nomachine = 1;}
			}
			
			#Send success e-mail to the user
			my %params;
			($number_of_users == 1) ? ($params{'full_name'} = "Superuser") : ($params{'full_name'} = "$first_name $last_name");
			$params{'username'} = $username;
			$params{'password'} = $password;
			$params{'email_prefix'} = $email_prefix;
			$params{'domain'} = $admin_details->{'email_domain'};
			$params{'system_anchor_domain'} = $system_anchor_domain;
			$params{'x2go'} = $uses_x2go;
			$params{'nomachine'} = $uses_nomachine;

			if ($uses_x2go == 1){
			    my $short_domain = `DOMAIN=$admin_details->{'email_domain'}; echo \${DOMAIN%%.*}`;
			    chomp($short_domain);
			    my ($alias_domain) = $tdb_conn->selectall_arrayref("SELECT alias_domain FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
			    my $session_id = `date +"%Y%m%d%H%M%S000"`;
			    chomp($session_id);
			    my $session_name = "$username-$short_domain";
			    my $server_host = "desktop.$alias_domain";
			    my $server_port = '80';
			    my $proxy_enabled = 'true';
			    my $proxy_host = "desktop.$alias_domain";
			    my $proxy_port = '80';
			    my $fullscreen = 'false';
			    my $resolution_width = '800';
			    my $resolution_height = '600';
			    my $connection_speed = '2';
			    `mkdir -p /tmp/$session_name`;
			    `cat $ENV{'HOME'}/bin/nx_templates/x2go_windows.template | sed -e "s|\\[-SESSION_ID-\\]|$session_id|;s|\\[-SESSION_NAME-\\]|$session_name|;s|\\[-USERNAME-\\]|$username|;s|\\[-SERVER_HOST-\\]|$server_host|;s|\\[-SERVER_PORT-\\]|$server_port|;s|\\[-PROXY_ENABLED-\\]|$proxy_enabled|;s|\\[-PROXY_HOST-\\]|$proxy_host|;s|\\[-PROXY_PORT-\\]|$proxy_port|;s|\\[-RESOLUTION_WIDTH-\\]|$resolution_width|;s|\\[-RESOLUTION_HEIGHT-\\]|$resolution_height|;s|\\[-FULLSCREEN-\\]|$fullscreen|;s|\\[-CONNECTION_SPEED-\\]|$connection_speed|" > /tmp/$session_name/$session_name-windows.bat`;
			    `cat $ENV{'HOME'}/bin/nx_templates/x2go_linux.template | sed -e "s|\\[-SESSION_ID-\\]|$session_id|;s|\\[-SESSION_NAME-\\]|$session_name|;s|\\[-USERNAME-\\]|$username|;s|\\[-SERVER_HOST-\\]|$server_host|;s|\\[-SERVER_PORT-\\]|$server_port|;s|\\[-PROXY_ENABLED-\\]|$proxy_enabled|;s|\\[-PROXY_HOST-\\]|$proxy_host|;s|\\[-PROXY_PORT-\\]|$proxy_port|;s|\\[-RESOLUTION_WIDTH-\\]|$resolution_width|;s|\\[-RESOLUTION_HEIGHT-\\]|$resolution_height|;s|\\[-FULLSCREEN-\\]|$fullscreen|;s|\\[-CONNECTION_SPEED-\\]|$connection_speed|" > /tmp/$session_name/$session_name-linux.sh`;
			    `mkdir -p /tmp/$session_name/$session_name-mac.app/Contents/MacOS`;
			    `cat $ENV{'HOME'}/bin/nx_templates/x2go_osx.template | sed -e "s|\\[-SESSION_ID-\\]|$session_id|;s|\\[-SESSION_NAME-\\]|$session_name|;s|\\[-USERNAME-\\]|$username|;s|\\[-SERVER_HOST-\\]|$server_host|;s|\\[-SERVER_PORT-\\]|$server_port|;s|\\[-PROXY_ENABLED-\\]|$proxy_enabled|;s|\\[-PROXY_HOST-\\]|$proxy_host|;s|\\[-PROXY_PORT-\\]|$proxy_port|;s|\\[-RESOLUTION_WIDTH-\\]|$resolution_width|;s|\\[-RESOLUTION_HEIGHT-\\]|$resolution_height|;s|\\[-FULLSCREEN-\\]|$fullscreen|;s|\\[-CONNECTION_SPEED-\\]|$connection_speed|" > /tmp/$session_name/$session_name-mac.app/Contents/MacOS/$session_name-mac`;
			    `chmod -R a+x /tmp/$session_name/*`;
			    `cd /tmp/$session_name; zip -r ../$session_name.zip *`;

			    sendEmailAttachment($userrealm,
				      $FROMEMAILADDRESS,
				      $params{'email_prefix'} . "@" . $admin_details->{'email_domain'},
				      $user_email,
				      $BCCEMAILADDRESS,
				      'Welcome to EnterpriseLibre',
				      'welcome_message_user.html.tt',
				      'text/html',
				      'application/zip',
				      "/tmp",
				      "$session_name.zip",
				      \%params);		       			    
			}
			else{
			    sendEmail($userrealm,
				      $FROMEMAILADDRESS,
				      $params{'email_prefix'} . "@" . $admin_details->{'email_domain'},
				      $user_email,
				      $BCCEMAILADDRESS,
				      'Welcome to EnterpriseLibre',
				      'welcome_message_user.txt.tt',
				      'welcome_message_user.html.tt',
				      \%params);
			}
			    
			#Don't send redundant welcome message for first user
			unless ($number_of_users == 1){
				mylog("Sending welcome message copy to admin");
				my %admin_params;
				$admin_params{'first_name'} = $first_name;
				$admin_params{'last_name'} = $last_name;
				$admin_params{'external_email'} = $user_email;
				$admin_params{'email_prefix'} = $email_prefix;
				$admin_params{'domain'} = $admin_details->{'email_domain'};
				$admin_params{'username'} = $username;
				$admin_params{'password'} = $password;
				sendEmail($userrealm,
					  $FROMEMAILADDRESS,
					  $admin_details->{'email_prefix'} . "@" . $admin_details->{'email_domain'},
					  '',
					  '',
					  'Welcome to EnterpriseLibre',
					  'welcome_message_itman.txt.tt',
					  'welcome_message_itman.html.tt',
					  \%admin_params);
			}
		}
	}
}

sub processArchiveUsers{
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from secondary thread";
	my $tdb_log; 
	my $find_chaos;
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		our $db_log = $tdb_log;
		my $archiveUser = $archive_user_queue->dequeue();
		my $username = $archiveUser->[0];
		my $userrealm = $archiveUser->[1];

		my ($user_type) = $tdb_conn->selectall_arrayref("SELECT type FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		if ($user_type eq 'email_only'){
		    my ($password) = $tdb_conn->selectall_arrayref("SELECT password FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		    # Change Dovecot PassDB file which resides at hera.
		    eseriUpdateDovecotPassDBFileExecute($userrealm, $username, $password, $user_type, 'ARCHIVED', 'processArchiveUsers');
		}
		else{
		    eseriArchiveAccountExecute($tdb_conn, $userrealm, $username, 'processArchiveUsers');
		}

		my $archive_passed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'ARCHIVED' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)")
		    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
		$archive_passed->bind_param(1, $username);
		$archive_passed->bind_param(2, $userrealm);
		$archive_passed->execute()
		    or die "Couldn't prepare statement: " . $archive_passed->errstr;
	}
}

sub processRestoreUsers{
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from secondary thread";
	my $tdb_log; 
	my $find_chaos;
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		our $db_log = $tdb_log;
		my $restoreUser = $restore_user_queue->dequeue();
		my $username = $restoreUser->[0];
		my $userrealm = $restoreUser->[1];

		my ($user_type) = $tdb_conn->selectall_arrayref("SELECT type FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		if ($user_type eq 'email_only'){
		    my ($password) = $tdb_conn->selectall_arrayref("SELECT password FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		    # Change Dovecot PassDB file which resides at hera.
		    eseriUpdateDovecotPassDBFileExecute($userrealm, $username, $password, $user_type, 'ACTIVE', 'processRestoreUsers');
		}
		else{
		    eseriRestoreAccountExecute($tdb_conn, $userrealm, $username, 'processRestoreUsers');
		}
		
		my $restore_passed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'ACTIVE' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)")
		    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
		$restore_passed->bind_param(1, $username);
		$restore_passed->bind_param(2, $userrealm);
		$restore_passed->execute()
		    or die "Couldn't prepare statement: " . $restore_passed->errstr;
	}
}

sub processChangeUserPasswords{
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
	my $tdb_log; 
	my $find_chaos;
	my $change_pw;
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		our $db_log = $tdb_log;
		mylog("Change user password thread started");
		my $passwordArray = $change_password_queue->dequeue();
		mylog("Change user password thread dequeued array");
		my $username = $passwordArray->[0];
		my $userrealm = $passwordArray->[1];
		my $newPassword = ($passwordArray->[2] eq '') ? &makePassword() : $passwordArray->[2];
		my $isReset = ($passwordArray->[2] eq '') ? 1 : 0;
		mylog("Changing password for $username at $userrealm to $newPassword");
		my ($emailPrefix) = $tdb_conn->selectall_arrayref("SELECT email_prefix FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		my ($oldPassword) = $tdb_conn->selectall_arrayref("SELECT password FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		my ($domain_config_version) = $tdb_conn->selectall_arrayref("SELECT config_version FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
		my ($alias_domain) = $tdb_conn->selectall_arrayref("SELECT alias_domain FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
		my ($user_type) = $tdb_conn->selectall_arrayref("SELECT type FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		my ($user_status) = $tdb_conn->selectall_arrayref("SELECT status FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		my $num_users = $tdb_conn->prepare("SELECT count(*) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
		$num_users->bind_param(1, $userrealm);
		$num_users->execute();
		my ($number_of_users) = $num_users->fetchrow();
		my $host = "chaos.$userrealm";
		ssh_key($host);
		`ssh eseriman\@$host ./bin/eseriChangePassword "$username" "$newPassword"`;
		my $exit_code = $?;
		if ($exit_code != 0){
			sendMethodFailMail($userrealm, "processChangeUserPasswords method failed - ./bin/eseriChangePassword failed");
			fail("eseriChangePassword returned $exit_code");
		}
		
		# Change Dovecot PassDB file which resides at hera
		if ($user_type eq 'email_only'){
		    eseriUpdateDovecotPassDBFileExecute($userrealm, $username, $newPassword, $user_type, $user_status, 'processChangeUserPasswords');
		}

		#Determine user's capabilities
		my $caps = $tdb_conn->selectall_arrayref("SELECT name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id from network.organization WHERE network_name=?))", {}, $userrealm);
		my $funambol = 'NO';
		my $vtiger = 'NO';
		my $webhuddle = 'NO';
		my $nuxeo = 'NO';
		my $churchinfo = 'NO';
		my $syncthing = 'NO';
		foreach $cap (@{$caps}){
			if ($cap->[0] eq 'Smartphone') {$funambol = 'YES'};
			if ($cap->[0] eq 'WebConferencing') {$webhuddle = 'YES'};
			if ($cap->[0] eq 'Vtiger') {$vtiger = 'YES'};
			if ($cap->[0] eq 'Nuxeo') {$nuxeo = 'YES'};
			if ($cap->[0] eq 'ChurchInfo') {$churchinfo = 'YES'};
			if ($cap->[0] eq 'Syncthing') {$syncthing = 'YES'};
		}
		my ($cloud_domain) = $tdb_conn->selectall_arrayref("SELECT email_domain FROM network.organization WHERE network_name = ?", {}, $userrealm)->[0]->[0];

		# Restore an email only user first.
		if ($user_type eq 'email_only'){
		    eseriRestoreAccountExecute($tdb_conn, $userrealm, $username, 'processChangeUserPasswords');
		}

		mylog("Calling change_user_password.pl with --username $username --old_password $oldPassword --new_password $newPassword --email_prefix $emailPrefix --cloud_domain $cloud_domain --alias_domain $alias_domain --domain_config_version $domain_config_version --network_name $userrealm --funambol $funambol --vtiger $vtiger --webhuddle $webhuddle --nuxeo $nuxeo --churchinfo $churchinfo --syncthing $syncthing >&2");
                `./change_user_password.pl --username "$username" --old_password "$oldPassword" --new_password "$newPassword" --email_prefix "$emailPrefix" --cloud_domain "$cloud_domain" --alias_domain "$alias_domain" --domain_config_version "$domain_config_version" --network_name "$userrealm" --funambol $funambol --vtiger $vtiger --webhuddle $webhuddle --nuxeo $nuxeo --churchinfo $churchinfo --syncthing $syncthing >&2`;
		my $second_exit_code = $?;

		# Archive back the email only user.
		if ($user_type eq 'email_only'){
                    eseriArchiveAccountExecute($tdb_conn, $userrealm, $username, 'processChangeUserPasswords');
		}

		if ($second_exit_code != 0){
			sendMethodFailMail($userrealm, "processChangeUserPasswords method failed - change_user_password.pl failed");
			fail("change_user_password.pl returned $second_exit_code");
		}
		else{
			my $change_pw = $tdb_conn->prepare("UPDATE network.eseri_user SET password = ? WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
			$change_pw->bind_param(1, "$newPassword");
			$change_pw->bind_param(2, "$username");
			$change_pw->bind_param(3, "$userrealm");
			$change_pw->execute();
			mylog("Successfully changed user password for $username in $userrealm");
			#Send e-mails for password change
			my ($admin_details) = getUserDetails($userrealm, 'admin');
                        my ($user_details) = getUserDetails($userrealm, 'user', $username);
			my %admin_params;
			$admin_params{'email_prefix'} = $user_details->{'email_prefix'};
			$admin_params{'first_name'} = $user_details->{'first_name'};
			$admin_params{'last_name'} = $user_details->{'last_name'};
			$admin_params{'domain'} = $admin_details->{'email_domain'};
			$admin_params{'password'} = $newPassword;
			$admin_params{'username'} = $username;
			sendEmail($userrealm,
				  $FROMEMAILADDRESS,
				  $admin_details->{'email_prefix'} . "@" . $admin_details->{'email_domain'},
				  '',
				  '',
				  'User password change notification',
				  'password_change_message_itman.txt.tt',
				  'password_change_message_itman.html.tt',
				  \%admin_params);
			mylog("Sent e-mail to admin");
			#Send e-mail to the user themselves
			my %params;
			$params{'email_prefix'} = $user_details->{'email_prefix'};
			($number_of_users == 1) ? ($params{'full_name'} = "Superuser") : ($params{'full_name'} = $user_details->{'first_name'}.' '.$user_details->{'last_name'});
			$params{'password'} = $newPassword;
			$params{'is_reset'} = $isReset;
			$params{'system_anchor_domain'} = $system_anchor_domain;
			my $to_address;
			if (! $isReset){
			    $to_address = $user_details->{'email_prefix'} . "@" . $user_details->{'email_domain'};
			}
			else{
			    $to_address = $user_details->{'real_email'};
			}
			sendEmail($userrealm,
				  $FROMEMAILADDRESS,
				  $to_address,
				  '',
				  '',
				  'Password change succeeded',
				  'password_change_message_user.txt.tt',
				  'password_change_message_user.html.tt',
				  \%params);
			mylog("Sent e-mail to user at $to_address");
		}
	}
}

sub processDeleteUsers{
        # This thread is currently not is use.
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
	my $tdb_log; 
	my $find_chaos;
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		my $userArray = $delete_user_queue->dequeue();
		my $username = $userArray->[0];
		my $userrealm = $userArray->[1];
		my $returnURL = $userArray->[2];
		my $host = "chaos.$userrealm";
		ssh_key($host);
		`ssh eseriman\@$host ./bin/eseriChangePassword "$username" "$userrealm"`;
		my $exit_code = $?;
		if ($exit_code != 0){
			our $db_log = $tdb_log;
			sendMethodFailMail($userrealm, "processDeleteUsers method failed - ./bin/eseriChangePassword failed");
			fail("eseriChangePassword returned $exit_code");
		}
	}
}

sub processResetUsers{
	my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
	my $tdb_log; 
	my $find_chaos;
	if (! defined $DBI::err){
		$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
	}
	while(1){
		my $userArray = $reset_user_queue->dequeue();
		my $username = $userArray->[0];
		my $userrealm = $userArray->[1];
		my $num_users = $tdb_conn->prepare("SELECT count(*) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
		$num_users->bind_param(1, $userrealm);
		$num_users->execute();
		my ($number_of_users) = $num_users->fetchrow();
		my $host = "chaos.$userrealm";
		our $db_log = $tdb_log;
		eseriKillNXSessionExecute($userrealm, $username, 'processResetUsers');
		mylog("Successful call to reset user desktop for $username at $userrealm");
		my ($admin_details) = getUserDetails($userrealm, 'admin');
		my ($user_details) = getUserDetails($userrealm, 'user', $username);
		my $user_email = $user_details->{'real_email'};
		my %params;
		$params{'username'} = $username;
		$params{'domain'} = $user_details->{'email_domain'};
		($number_of_users == 1) ? ($params{'full_name'} = "Superuser") : ($params{'full_name'} = $user_details->{'first_name'}.' '.$user_details->{'last_name'});
		sendEmail($userrealm,
			  $FROMEMAILADDRESS,
			  $user_email,
			  '',
			  '',
			  'Your EnterpriseLibre desktop has been rebooted',
			  'reboot_desktop_message.txt.tt',
			  'reboot_desktop_message.html.tt',
			  \%params);
	}
}

sub processChangeExternalEmail{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        my $find_chaos;
        my $change_externalemail;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Change user real email thread started");
                my $externalemailArray = $change_externalemail_queue->dequeue();
                mylog("Change user real email thread dequeued array");
                my $username = $externalemailArray->[0];
                my $userrealm = $externalemailArray->[1];
                my $newExternalEmail = $externalemailArray->[2];
		my $num_users = $tdb_conn->prepare("SELECT count(*) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
		$num_users->bind_param(1, $userrealm);
		$num_users->execute();
		my ($number_of_users) = $num_users->fetchrow();
                mylog("Changing real email for $username at $userrealm to $newExternalEmail");
		my $host = "chaos.$userrealm";
                $change_externalemail = $tdb_conn->prepare("UPDATE network.eseri_user SET real_email = ? WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
                $change_externalemail->bind_param(1, "$newExternalEmail");
                $change_externalemail->bind_param(2, "$username");
                $change_externalemail->bind_param(3, "$userrealm");
                $change_externalemail->execute();
                mylog("Successfully changed user real email for $username in $userrealm");
                #Send e-mails for password change
		my ($admin_details) = getUserDetails($userrealm, 'admin');
		my ($user_details) = getUserDetails($userrealm, 'user', $username);
		mylog("Calling eseriman script to create new pam_obc.conf file for $host");
		ssh_key($host);
                `ssh eseriman\@$host sudo ./bin/eseriCreatePamObcConf 2`;
                my $exit_code = $?;
                if ($exit_code != 0){
		    sendMethodFailMail($userrealm, "processChangeExternalEmail method failed - ./bin/eseriCreatePamObcConf failed");
		    fail("eseriChangeExternalEmail returned $exit_code");
                }
                my %admin_params;
		$admin_params{'email_prefix'} = $user_details->{'email_prefix'};
                $admin_params{'first_name'} = $user_details->{'first_name'};
                $admin_params{'last_name'} = $user_details->{'last_name'};
                $admin_params{'domain'} = $admin_details->{'email_domain'};
                $admin_params{'username'} = $username;
                $admin_params{'real_email'} = $user_details->{'real_email'};
		sendEmail($userrealm,
			  $FROMEMAILADDRESS,
			  $admin_details->{'email_prefix'} . "@" . $admin_details->{'email_domain'},
			  '',
			  '',
			  'User External E-mail change notification',
			  'externalemail_change_message_itman.txt.tt',
			  'externalemail_change_message_itman.html.tt',
			  \%admin_params);
                mylog("Sent e-mail to admin");
                #Send e-mail to the user themselves
                my %params;
		$params{'email_prefix'} = $user_details->{'email_prefix'};
		($number_of_users == 1) ? ($params{'full_name'} = "Superuser") : ($params{'full_name'} = $user_details->{'first_name'}.' '.$user_details->{'last_name'});
                $params{'real_email'} = $user_details->{'real_email'};
		sendEmail($userrealm,
			  $FROMEMAILADDRESS,
			  $user_details->{'email_prefix'} . "@" . $user_details->{'email_domain'},
                          '',
                          '',
			  'External E-mail change succeeded',
                          'externalemail_change_message_user.txt.tt',
                          'externalemail_change_message_user.html.tt',
                          \%params);
                mylog("Sent e-mail to user");
        }
}

sub processChangeDLOption{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        my $find_chaos;
        my $change_dloption;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Change user double lock option thread started");
                my $dloptionArray = $change_dloption_queue->dequeue();
                mylog("Change user double lock option thread dequeued array");
                my $username = $dloptionArray->[0];
                my $userrealm = $dloptionArray->[1];
                my $newDLOption = $dloptionArray->[2];
                mylog("Changing double lock option for $username at $userrealm to $newDLOption");
		my $host = "chaos.$userrealm";
                $change_dloption = $tdb_conn->prepare("UPDATE network.eseri_user SET double_lock_option = ? WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
                $change_dloption->bind_param(1, "$newDLOption");
                $change_dloption->bind_param(2, "$username");
                $change_dloption->bind_param(3, "$userrealm");
                $change_dloption->execute();
                mylog("Successfully changed user double lock option for $username in $userrealm");
                mylog("Calling eseriman script to apply changes for $host");
		ssh_key($host);
                `ssh eseriman\@$host sudo ./bin/eseriCreatePamObcConf 3`;
        }
}

sub processDomainConfig{	
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log;	
    if (! defined $DBI::err){	
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";	
        }
    while(1){
	our $db_log = $tdb_log;
	mylog("Domain Configuration thread started");
	my $domain_config_dequeue = $domain_config_queue->dequeue();
	mylog("Domain Configuration thread dequeued array");
	my $userrealm = $domain_config_dequeue->[0];
	my $new_config_version = $domain_config_dequeue->[1];
	my $new_email_domain = $domain_config_dequeue->[2];
	my $new_imap_server = $domain_config_dequeue->[3];
	my $new_alias_domain = $domain_config_dequeue->[4];
	my $new_website_ip = $domain_config_dequeue->[5];
	
	# Getting the Super User details from the database.
	my ($admin_details) = getUserDetails($userrealm, 'admin');
	my $admin_first_name = $admin_details->{'first_name'};
	my $admin_last_name = $admin_details->{'last_name'};
	my $admin_username = $admin_details->{'username'};
	my $admin_email_prefix = $admin_details->{'email_prefix'};	
	my $admin_real_email = $admin_details->{'real_email'};	
	
	# Setting the Mail parameters.
	my %params;
	$params{'config_version'} = $new_config_version;
	$params{'email_domain'} = $new_email_domain;
	$params{'imap_server'} = $new_imap_server;
	($new_config_version eq '2.3') ? ($params{'smtp_server'} = 'smtp.'.$new_email_domain) : ($params{'smtp_server'} = 'smtp.'.$userrealm);
	$params{'website_ip'} = $new_website_ip;
	$params{'ns1_server'} = "ns1.".$new_email_domain;
	$params{'ns2_server'} = "ns2.".$new_email_domain;
	chomp($params{'mx1_server'} = `dig +short MX $userrealm | sort | awk \'NR==1{print \$2}\' | sed \'s|.\$||\'`);
	chomp($params{'mx2_server'} = `dig +short MX $userrealm | sort | awk \'NR==2{print \$2}\' | sed \'s|.\$||\'`);
	my $subject = 'Domain Name and Email Setup details';
	my $template_text = 'domain_config_message_itman.txt.tt';
	my $template_html = 'domain_config_message_itman.html.tt';
	
	# Checking if no other organization has the same email domain or network name as newEmailDomain.
	my $count = $tdb_conn->prepare("SELECT COUNT(id) FROM network.organization WHERE email_domain = ? and network_name != ?")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	$count->bind_param(1, lc($new_email_domain));
	$count->bind_param(2, lc($userrealm));
	$count->execute()
	    or die "Couldn't prepare statement: " . $count->errstr;
	my $substr = ".$system_anchor_domain";
	
	# If another organization has the same email domain or network name as newEmailDomain and new config version is 2.3, then set mail parameters, else continue with the configuration.
	if ( ((index($new_email_domain, $substr) != -1) and ($new_config_version ne '1.1')) or (($count->fetchrow_array ne '0') and ($new_config_version eq '2.3')) ){
	    mylog("Domain already in use by another organization");
	    $params{'email_domain'} = $new_email_domain;
	    $subject = 'Email Domain is already taken';
	    $template_text = 'domain_config_exists_message_itman.txt.tt';
	    $template_html = 'domain_config_exists_message_itman.html.tt';
	}
	else{
	    # Sending initial email to the super user's real email address if domain to be configured is equal to email address or if new domain is not equal to network name.
	    if ($new_config_version eq '2.2' and (substr($admin_real_email, index($admin_real_email, '@')+1, length($admin_real_email)-1) eq $new_email_domain or $new_email_domain ne $userrealm)){
		sendEmail($userrealm,
			  $FROMEMAILADDRESS,
			  $admin_email_prefix . '@' . $userrealm,
			  $admin_real_email,
			  $BCCEMAILADDRESS,
			  $subject,
			  'domain_config_confirmation_itman.txt.tt',
			  'domain_config_confirmation_itman.html.tt',
			  \%params);
		mylog("Sent initial e-mail to Admin: $admin_username");
	    }
	    mylog("Configuring the Domain at $userrealm to $new_config_version");
	    ssh_key("c4.$system_anchor_domain");
	    `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./domain_config.pl --network_name "$userrealm" --new_config_version "$new_config_version" --new_email_domain "$new_email_domain" --new_imap_server "$new_imap_server" --new_alias_domain "$new_alias_domain" --new_website_ip "$new_website_ip" >> /var/log/c4/domain_config.log 2>&1'`;
	    my $exit_code = $?;
	    if ($exit_code != 0){
		updateCloudConfigStatus($tdb_conn, $userrealm, 'dc', 'PROCESSING_FAILED');
		sendMethodFailMail($userrealm, "processDomainConfig method failed - ./domain_config.pl failed");
		fail("domain_config.pl returned $exit_code");
		next;
	    }
	}

	# Update status to ACTIVE.
	updateCloudConfigStatus($tdb_conn, $userrealm, 'dc', 'ACTIVE');
	
	# Sending the final email to the super user.
	sendEmail($userrealm,
		  $FROMEMAILADDRESS,
		  $admin_email_prefix . '@' . $new_email_domain,
		  $admin_real_email,
		  $BCCEMAILADDRESS,
		  $subject,
		  $template_text,
		  $template_html,
		  \%params);
	mylog("Sent final e-mail to Admin: $admin_username");
    }
}

sub updateCloudConfigStatus{
    my ($tdb_conn, $userrealm, $column, $status) = @_;
    my $change_cloud_config_status = $tdb_conn->prepare("UPDATE network.organization_config_status SET $column = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $tdb_conn->errstr;
    $change_cloud_config_status->bind_param(1, uc($status));
    $change_cloud_config_status->bind_param(2, lc($userrealm));
    $change_cloud_config_status->execute()
	or die "Couldn't execute statement: " . $change_cloud_config_status->errstr;
    $change_cloud_config_status->finish;
}

sub processCloudCapabilityConfig{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log;
    if (! defined $DBI::err){
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
    }
    while(1){
	our $db_log = $tdb_log;
	mylog("Cloud Capability Configuration thread started");
	my $cloudcapabilityconfigArray = $cloudcapabilityconfig_queue->dequeue();
	mylog("Cloud Capability Configuration thread dequeued array");
	my $userrealm = $cloudcapabilityconfigArray->[0];
	my @capability = $cloudcapabilityconfigArray->[1];
	my @enable = $cloudcapabilityconfigArray->[2];
	
	mylog("Configuring Cloud Capability at $userrealm");
	ssh_key("c4.$system_anchor_domain");
	`ssh c4\@c4.$system_anchor_domain 'cd bin/; ./cloudcapability_config.pl --network_name "$userrealm" --capability "@capability" --enable "@enable" >> /var/log/c4/cloudcapability_config.log 2>&1'`;
	my $exit_code = $?;
	if ($exit_code != 0){
	    updateCloudConfigStatus($tdb_conn, $userrealm, 'ccc', 'PROCESSING_FAILED');
	    sendMethodFailMail($userrealm, "processCloudCapabilityConfig method failed - ./cloudcapability_config.pl failed");
	    fail("cloudcapability_config.pl returned $exit_code");
	}
	else{
	    updateCloudConfigStatus($tdb_conn, $userrealm, 'ccc', 'ACTIVE');
	    #Sending email to admin with new password details
	    sendCloudCapabilityMail($userrealm);	
	}
    }
}

sub processInsertCloudManagerReq{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
	    $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
	    our $db_log = $tdb_log;
	    mylog("Insert Cloud Manager Request thread started");
	    my $insertcloudmanagerreqArray = $insert_cloud_manager_req_queue->dequeue();
	    mylog("Insert Cloud Manager Request thread dequeued array");
	    my $userrealm = $insertcloudmanagerreqArray->[0];
	    my $hash = $insertcloudmanagerreqArray->[1];
	    my $data = $insertcloudmanagerreqArray->[2];
	    my $new_string = $insertcloudmanagerreqArray->[3];
	    my $amount = $insertcloudmanagerreqArray->[4];
	    
	    my $insert_cloud_manager_request = $tdb_conn->prepare("INSERT INTO network.cloud_manager_req (organization, hash, data, new_string, amount) SELECT id, ?,?,?,? FROM network.organization WHERE network_name = ?")
		or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	    $insert_cloud_manager_request->bind_param(1, $hash);
	    $insert_cloud_manager_request->bind_param(2, $data);
	    $insert_cloud_manager_request->bind_param(3, $new_string);
	    $insert_cloud_manager_request->bind_param(4, $amount, SQL_DOUBLE);
	    $insert_cloud_manager_request->bind_param(5, lc($userrealm));
	    $insert_cloud_manager_request->execute()
		or die "Couldn't execute statement: " . $insert_cloud_manager_request->errstr;
	}
}

sub processProcessCloudManagerReq{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log;
    if (! defined $DBI::err){
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
    }
    while(1){
	our $db_log = $tdb_log;
	mylog("Process Cloud Manager Request thread started");
	my $processcloudmanagerreqArray = $process_cloud_manager_req_queue->dequeue();
	mylog("Process Cloud Manager Request thread dequeued array");
	my $userrealm = $processcloudmanagerreqArray->[0];
	my $hash = $processcloudmanagerreqArray->[1];

        my $get_cloud_manager_req = $tdb_conn->prepare("SELECT data, completed FROM network.cloud_manager_req WHERE hash = ? and organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	$get_cloud_manager_req->bind_param(1, $hash);
	$get_cloud_manager_req->bind_param(2, lc($userrealm));
	$get_cloud_manager_req->execute()
	    or die "Couldn't execute statement: " . $get_cloud_manager_req->errstr;
	my ($data, $completed) = $get_cloud_manager_req->fetchrow_array();
	$get_cloud_manager_req->finish;

	if ($completed == 1){
	    mylog("Already processed hash $hash for $userrealm");
	    last;
	}

	my $xml = new XML::Simple;
	$data = $xml->XMLin($data, ForceArray=>1);
	if ($data->{'msg'}){
	    my $count = scalar @{$data->{'msg'}};
	    my $client = RPC::XML::Client->new($C3ADDRESS);
	    mylog("Created client for address: $C3ADDRESS");
	    for (my $i=0; $i<$count; $i++){
		my @key =  keys %{$data->{'msg'}[$i]};
		my $response;
		if ($key[0] eq 'changeCloudCapabilityConfig') {
		    my @capability;
		    my @enable;
		    my $j = 0;
		    while (1){
			if (defined $data->{'msg'}[$i]->{'changeCloudCapabilityConfig'}[0]->{'detail'}[$j]->{'capability'}[0]){
			    push (@capability, $data->{'msg'}[$i]->{'changeCloudCapabilityConfig'}[0]->{'detail'}[$j]->{'capability'}[0]);
			    push (@enable, $data->{'msg'}[$i]->{'changeCloudCapabilityConfig'}[0]->{'detail'}[$j]->{'enable'}[0]);
			    $j++;
			}
			else{
			    last;
			}
		    }
		    
		    mylog("Preparing XML RPC call for $userrealm to configure cloud capability - capability: @capability - enable: @enable");
		    $response = $client->send_request($PROCEDURE_PREFIX."changeCloudCapabilityConfig", $userrealm, \@capability, \@enable);
		    my $loop_count = 0;
		    while($loop_count<=20){
			sleep(30);
			my ($ccc_status) = $tdb_conn->selectall_arrayref("SELECT ccc FROM network.organization_config_status WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
			
			($ccc_status eq 'PROCESSING') ? ($loop_count += 1) : (last);
		    }
		    if ($loop_count >=20){
			sendAdminProcessingMail($userrealm, "Process Cloud Manager Request");
			fail("Cloud is still processing - Counldn't process the cloud manager request any further");
			last;
		    }
		}
		elsif ($key[0] eq 'addUser') {
		    my $username = $data->{'msg'}[$i]->{'addUser'}[0]->{'username'}[0];
		    my $desired_email_prefix = $data->{'msg'}[$i]->{'addUser'}[0]->{'desired_email_prefix'}[0];
		    my $firstname = $data->{'msg'}[$i]->{'addUser'}[0]->{'firstname'}[0];
		    my $lastname = $data->{'msg'}[$i]->{'addUser'}[0]->{'lastname'}[0];
		    my $email = $data->{'msg'}[$i]->{'addUser'}[0]->{'email'}[0];
		    mylog("Preparing XML RPC call for $userrealm to add new user: $username $desired_email_prefix $firstname $lastname $email");
		    $response = $client->send_request($PROCEDURE_PREFIX."createNewUser", $username, $desired_email_prefix, $userrealm, $firstname, $lastname, $email, "full");
		}
		elsif ($key[0] eq 'activateUser') {
		    my $username = $data->{'msg'}[$i]->{'activateUser'}[0]->{'username'}[0];
		    mylog("Preparing XML RPC call for $userrealm to restore user: $username");
		    $response = $client->send_request($PROCEDURE_PREFIX."restoreUser", $username, $userrealm);
		}
		elsif ($key[0] eq 'changeUserType') {
		    my $username = $data->{'msg'}[$i]->{'changeUserType'}[0]->{'username'}[0];
		    my $new_user_type = $data->{'msg'}[$i]->{'changeUserType'}[0]->{'new_utype'}[0];
		    my @params;
		    push (@params, $username);
		    push (@params, $new_user_type);
		    mylog("Preparing XML RPC call for $userrealm to change user type to $new_user_type");
		    $response = $client->send_request($PROCEDURE_PREFIX."changeUserType", $userrealm, \@params);
		}
	    }
	}
	
	mylog("Sleeping for 10 secs");
	sleep(10);
	my $update_cloud_manager_req = $tdb_conn->prepare("UPDATE network.cloud_manager_req SET completed = ? WHERE hash = ? and organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
	$update_cloud_manager_req->bind_param(1, "1");
	$update_cloud_manager_req->bind_param(2, $hash);
	$update_cloud_manager_req->bind_param(3, lc($userrealm));
	$update_cloud_manager_req->execute()
	    or die "Couldn't execute statement: " . $update_cloud_manager_req->errstr;
	mylog("Cloud Manager request completed");
    }
}

sub processTimezoneConfig{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log;
    if (! defined $DBI::err){
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
    }
    while(1){
	our $db_log = $tdb_log;
	mylog("Timezone Configuration thread started");
	my $timezoneconfigArray = $timezone_config_queue->dequeue();
	mylog("Timezone Configuration thread dequeued array");
	my $userrealm = $timezoneconfigArray->[0];
	my $new_timezone = $timezoneconfigArray->[1];
	my $server_user = $timezoneconfigArray->[2];
	my $username = $timezoneconfigArray->[3];
	my $num_users = $tdb_conn->prepare("SELECT count(*) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
	$num_users->bind_param(1, $userrealm);
	$num_users->execute();
	my ($number_of_users) = $num_users->fetchrow();
	
	mylog("Configuring Timezone at $userrealm to $new_timezone - $server_user - $username");
	ssh_key("c4.$system_anchor_domain");
	`ssh c4\@c4.$system_anchor_domain 'cd bin/; ./timezone_config.pl --network_name "$userrealm" --new_timezone "$new_timezone" --server_user "$server_user" --username "$username" >> /var/log/c4/timezone_config.log 2>&1'`;
	my $exit_code = $?;
	if ($exit_code != 0){
	    ($server_user eq 'server') ? (updateCloudConfigStatus($tdb_conn, $userrealm, 'tzc', 'PROCESSING_FAILED')) : ();
	    sendMethodFailMail($userrealm, "processTimezoneConfig method failed - ./timezone_config.pl failed");
	    fail("timezone_config.pl returned $exit_code");
	}
	else{
	    ($server_user eq 'server') ? (updateCloudConfigStatus($tdb_conn, $userrealm, 'tzc', 'ACTIVE')) : ();
	    my ($admin_details) = getUserDetails($userrealm, 'admin');
	    my ($user_details) = getUserDetails($userrealm, 'user', $username);
	    
	    my %params;
	    $params{'new_timezone'} = $new_timezone;
	    $params{'username'} = $username;
	    ($number_of_users == 1) ? ($params{'full_name'} = "Superuser") : ($params{'full_name'} = $user_details->{'first_name'}.' '.$user_details->{'last_name'});
	    my $subject;
	    if ($server_user eq 'server'){
		$subject = 'Default Timezone Change';
		$params{'server'} = 1;
		$params{'user'} = 0;
	    }
	    elsif ($server_user eq 'user'){
		$subject = 'User Timezone Change';
		$params{'server'} = 0;
		$params{'user'} = 1;
		sendEmail($userrealm,
			  $FROMEMAILADDRESS,
			  $user_details->{'email_prefix'} . '@' . $user_details->{'email_domain'},
			  '',
			  '',
			  $subject,
			  'timezone_message_user.txt.tt',
			  'timezone_message_user.html.tt',
			  \%params);
	    }
	    sendEmail($userrealm,
		      $FROMEMAILADDRESS,
		      $admin_details->{'email_prefix'} . '@' . $admin_details->{'email_domain'},
		      '',
		      $BCCEMAILADDRESS,
		      $subject,
		      'timezone_message_itman.txt.tt',
		      'timezone_message_itman.html.tt',
		      \%params);
	}
    }
}

sub processFirewallProxyConfig{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Firewall/Proxy Configuration thread started");
                my $firewallproxyconfigArray = $firewallproxy_config_queue->dequeue();
                mylog("Firewall/Proxy Configuration thread dequeued array");
                my $userrealm = $firewallproxyconfigArray->[0];
		my @capability = $firewallproxyconfigArray->[1];
		my @external_name = $firewallproxyconfigArray->[2];
		my @ssl = $firewallproxyconfigArray->[3];

		mylog("Capability: @capability - External_name: @external_name - SSL: @ssl");
		
		mylog("Configuring Firewall/Proxy at $userrealm");
		ssh_key("c4.$system_anchor_domain");
                `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./firewallproxy_config.pl --network_name "$userrealm" --capability "@capability" --external_name "@external_name" --ssl "@ssl" >> /var/log/c4/firewallproxy_config.log 2>&1'`;

		my $exit_code = $?;
                if ($exit_code != 0){
		    updateCloudConfigStatus($tdb_conn, $userrealm, 'fpc', 'PROCESSING_FAILED');
		    sendMethodFailMail($userrealm, "processFirewallProxyConfig method failed - ./firewallproxy_config.pl failed");
		    fail("firewallproxy_config.pl returned $exit_code");
                }
		else{
		    updateCloudConfigStatus($tdb_conn, $userrealm, 'fpc', 'ACTIVE');
		}
	}
}

sub processCloudReboot{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log; 
    my $find_chaos;
    if (! defined $DBI::err){
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
    }
    while(1){
	our $db_log = $tdb_log;
	my $cloudrebootArray = $cloudreboot_queue->dequeue();
	my $userrealm = $cloudrebootArray->[0];
	ssh_key("c4.$system_anchor_domain");
	`ssh c4\@c4.$system_anchor_domain 'cd bin/; ./cloud_boot.pl --network_name "$userrealm" --boot_action "reboot" >> /var/log/c4/cloud_boot.log 2>&1'`;
	
	my $exit_code = $?;
	if ($exit_code != 0){
	    sendMethodFailMail($userrealm, "processCloudReboot method failed - ./cloud_boot.pl failed");
	    fail("cloud_boot.pl returned $exit_code");
	}
	else{
	    my ($admin_details) = getUserDetails($userrealm, 'admin');
	    my %params;
	    sendEmail($userrealm,
		      $FROMEMAILADDRESS,
		      $admin_details->{'email_prefix'} . '@' . $admin_details->{'email_domain'},
		      $admin_details->{'real_email'},
		      $BCCEMAILADDRESS,
		      'Cloud Reboot',
		      'cloudreboot_message.txt.tt',
		      'cloudreboot_message.html.tt',
		      \%params);
	}
    }
}

sub processUserAliasConfig{
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log; 
    my $find_chaos;
    if (! defined $DBI::err){
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
    }
    while(1){
	our $db_log = $tdb_log;
	my $useraliasconfigArray = $useraliasconfig_queue->dequeue();
	my $userrealm = $useraliasconfigArray->[0];
	my $option = $useraliasconfigArray->[1];
	my $username = $useraliasconfigArray->[2];
	my $alias = $useraliasconfigArray->[3];

	my $host = "chaos.$userrealm";
	mylog("Calling eseriman script to $option alias $alias for username $username at $host");
	ssh_key($host);
	if ($option eq 'add'){
	    `ssh eseriman\@$host ./bin/eseriAddAlternateEmail "$username" "$alias"`;
	}
	elsif ($option eq 'delete'){
	    `ssh eseriman\@$host ./bin/eseriDeleteAlternateEmail "$username" "$alias"`;
	}

	my $exit_code = $?;
	if ($exit_code != 0){
	    sendMethodFailMail($userrealm, "processUserAliasConfig method failed - ./bin/eseri*AlternateEmail failed");
	    fail("eseri*AlternateEmail returned $exit_code");
	}
    }
}

sub processUserPrimaryEmailConfig{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("User Primary Email Configuration thread started");
                my $userprimaryemailconfigArray = $userprimaryemailconfig_queue->dequeue();
                mylog("User Primary Email Configuration thread dequeued array");
                my $userrealm = $userprimaryemailconfigArray->[0];
		my @username = $userprimaryemailconfigArray->[1];
		my @old_email = $userprimaryemailconfigArray->[2];
		my @new_email = $userprimaryemailconfigArray->[3];

		mylog("Username: @username - Old Email: @old_email - New Email: @new_email");
		
		mylog("Configuring User Primary Email at $userrealm");
		ssh_key("c4.$system_anchor_domain");
                `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./userprimaryemail_config.pl --network_name "$userrealm" --username "@username" --old_email "@old_email" --new_email "@new_email" >> /var/log/c4/userprimaryemail_config.log 2>&1'`;

		my $exit_code = $?;
                if ($exit_code != 0){
		    sendMethodFailMail($userrealm, "processUserPrimaryEmailConfig method failed - ./userprimaryemail_config.pl failed");
		    fail("userprimaryemail_config.pl returned $exit_code");
                }
	}
}

sub processUserFullnameConfig{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("User Fullname Configuration thread started");
                my $userfullnameconfigArray = $userfullnameconfig_queue->dequeue();
                mylog("User Fullname Configuration thread dequeued array");
                my $userrealm = $userfullnameconfigArray->[0];
		my @username = $userfullnameconfigArray->[1];
		my @old_firstname = $userfullnameconfigArray->[2];
		my @old_lastname = $userfullnameconfigArray->[3];
		my @new_firstname = $userfullnameconfigArray->[4];
		my @new_lastname = $userfullnameconfigArray->[5];

		mylog("Username: @username - Old Firstname: @old_firstname - Old Lastname: @old_lastname - New Firstname: @new_firstname - New Lastname: @new_lastname");
		
		mylog("Configuring User Primary Email at $userrealm");
		ssh_key("c4.$system_anchor_domain");		
                `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./userfullname_config.pl --network_name "$userrealm" --username "@username" --old_firstname "@old_firstname" --old_lastname "@old_lastname" --new_firstname "@new_firstname" --new_lastname "@new_lastname" >> /var/log/c4/userfullname_config.log 2>&1'`;

		my $exit_code = $?;
                if ($exit_code != 0){
		    sendMethodFailMail($userrealm, "processUserFullnameConfig method failed - ./userfullname_config.pl failed");
		    fail("userfullname_config.pl returned $exit_code");
                }
	}
}

sub processChangeUserType{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("User Type Change thread started");
                my $changeusertypeArray = $changeusertype_queue->dequeue();
                mylog("User Type Change thread dequeued array");
                my $userrealm = $changeusertypeArray->[0];
		my $username = $changeusertypeArray->[1];
		my $new_user_type = $changeusertypeArray->[2];

		my ($password) = $tdb_conn->selectall_arrayref("SELECT password FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		my ($user_status) = $tdb_conn->selectall_arrayref("SELECT status FROM network.eseri_user WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $username, $userrealm)->[0]->[0];
		if ($new_user_type eq 'full'){
		    eseriRestoreAccountExecute($tdb_conn, $userrealm, $username, 'processChangeUserType');
		}
		elsif ($new_user_type eq 'email_only'){
		    eseriArchiveAccountExecute($tdb_conn, $userrealm, $username, 'processChangeUserType');
		}

		eseriUpdateDovecotPassDBFileExecute($userrealm, $username, $password, $new_user_type, $user_status, 'processChangeUserType');

		my $change_usertype = $tdb_conn->prepare("UPDATE network.eseri_user SET type = ? WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)")
		    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
		$change_usertype->bind_param(1, $new_user_type);
		$change_usertype->bind_param(2, $username);
		$change_usertype->bind_param(3, $userrealm);
		$change_usertype->execute()
		    or die "Couldn't execute statement: " . $change_usertype->errstr;

		my $change_usertype_passed = $tdb_conn->prepare("UPDATE network.eseri_user SET status = 'ACTIVE' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)")
		    or die "Couldn't prepare statement: " . $tdb_conn->errstr;
		$change_usertype_passed->bind_param(1, $username);
		$change_usertype_passed->bind_param(2, $userrealm);
		$change_usertype_passed->execute()
		    or die "Couldn't execute statement: " . $change_usertype_passed->errstr;

	}
}

sub processFirewallPortConfig{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Firewall Port Config thread started");
                my $firewallportconfigArray = $firewallportconfig_queue->dequeue();
                mylog("Firewal Port Config thread dequeued array");
                my $userrealm = $firewallportconfigArray->[0];
		my $username = $firewallportconfigArray->[1];
		my $port = $firewallportconfigArray->[2];

		mylog("Configuring firewall ports at $userrealm - $username $port");
		ssh_key("c4.$system_anchor_domain");
                `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./firewallport_config.pl --network_name "$userrealm" --username "$username" --port "$port" >> /var/log/c4/firewallport_config.log 2>&1'`;

		my $exit_code = $?;
                if ($exit_code != 0){
		    sendMethodFailMail($userrealm, "processFirewallPortConfig method failed - ./firewallport_config.pl failed");
		    fail("firewallport_config.pl returned $exit_code");
                }
	}
}

sub processBackupConfig{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Backup Config thread started");
                my $backupconfigArray = $backupconfig_queue->dequeue();
                mylog("Backup Config thread dequeued array");
                my $userrealm = $backupconfigArray->[0];
                my $option = $backupconfigArray->[1];
                my $profile_id = $backupconfigArray->[2];
                my $name = $backupconfigArray->[3];
                my $frequency_number = $backupconfigArray->[4];
                my $frequency_duration = $backupconfigArray->[5];
                my $time = $backupconfigArray->[6];
                my $target_url = $backupconfigArray->[7];
                my $enabled = $backupconfigArray->[8];
                my $snapshot = $backupconfigArray->[9];

		mylog("Configuring backup at $userrealm");
		ssh_key("c4.$system_anchor_domain");
                `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./backup_config.pl --network_name "$userrealm" --option "$option" --profile_id "$profile_id" --name "$name" --frequency_number "$frequency_number" --frequency_duration "$frequency_duration" --time "$time" --target_url "$target_url" --enabled "$enabled" --snapshot "$snapshot" >> /var/log/c4/backup_config.log 2>&1'`;

		my $exit_code = $?;
                if ($exit_code != 0){
		    updateCloudConfigStatus($tdb_conn, $userrealm, 'bc', 'PROCESSING_FAILED');
		    sendMethodFailMail($userrealm, "processBackupConfig method failed - ./backup_config.pl failed");
		    fail("backup_config.pl returned $exit_code");
                }
		else{
		    ($option ne 'snapshot') ? (updateCloudConfigStatus($tdb_conn, $userrealm, 'bc', 'ACTIVE')) : ();
		}
	}
}

sub processRestoreFilePath{
        my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
        my $tdb_log;
        if (! defined $DBI::err){
                $tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";
        }
        while(1){
                our $db_log = $tdb_log;
                mylog("Restore File Path thread started");
                my $restorefilepathArray = $restorefilepath_queue->dequeue();
                mylog("Restore File Path thread dequeued array");
                my $userrealm = $restorefilepathArray->[0];
                my $username = $restorefilepathArray->[1];
                my $profile_id = $restorefilepathArray->[2];
                my $time = $restorefilepathArray->[3];
                my $source = $restorefilepathArray->[4];
                my $destination = $restorefilepathArray->[5];
		
		my $host = "apollo.$userrealm";
		mylog("Restoring File Path at $userrealm");
		ssh_key($host);
                `ssh root\@$host "su - -c \\\"./bin/restore_file_path.sh '$username' '$profile_id' '$time' '$source' '$destination' >> /var/log/duply/profile$profile_id-restore.log 2>&1 &\\\" backup"`;

		my $exit_code = $?;
		if ($exit_code != 0){
		    sendMethodFailMail($userrealm, "processRestoreFilePath method failed");
		    fail("restore_file_path.sh failed with exit code $exit_code");
		}       	
	}
}

sub processSystemAnchorConfig{	
    my $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link from second thread";
    my $tdb_log;	
    if (! defined $DBI::err){	
	$tdb_log = $tdb_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle from secondary thread";	
        }
    while(1){
	our $db_log = $tdb_log;
	mylog("System Anchor Configuration thread started");
	my $system_anchor_config_dequeue = $system_anchor_config_queue->dequeue();
	mylog("System Anchor Configuration thread dequeued array");
	my $userrealm = $system_anchor_config_dequeue->[0];
	my $new_system_anchor_domain = $system_anchor_config_dequeue->[1];
	my $new_system_anchor_ip = $system_anchor_config_dequeue->[2];
	my $new_system_anchor_netmask = $system_anchor_config_dequeue->[3];

	# One way to know if this request is from the system manager cloud is to see if the userrealm from where the request has come matches to the system_anchor_domain value in the database.
	if ($userrealm eq $system_anchor_domain){
	    mylog("Configuring the System Anchor at $userrealm");
	    ssh_key("c4.$system_anchor_domain");
	    `ssh c4\@c4.$system_anchor_domain 'cd bin/; ./systemanchor_config.pl --network_name "$userrealm" --new_system_anchor_domain "$new_system_anchor_domain" --new_system_anchor_ip "$new_system_anchor_ip" --new_system_anchor_netmask "$new_system_anchor_netmask" >> /var/log/c4/systemanchor_config.log 2>&1'`;
	    # Since we restarted the postgres server on the system manager cloud, connection is lost. So establish a new one.
	    # The below code is not executed anyway since this container is restarted at the end of the system anchor config script.
	    $tdb_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");
	    my $exit_code = $?;
	    if ($exit_code != 0){
		updateCloudConfigStatus($tdb_conn, $userrealm, 'dc', 'PROCESSING_FAILED');
		sendMethodFailMail($userrealm, "processSystemAnchorConfig method failed - ./systemanchor_config.pl failed");
		fail("systemanchor_config.pl returned $exit_code");
		next;
	    }
	}

	# Update status to ACTIVE.
	updateCloudConfigStatus($tdb_conn, $userrealm, 'dc', 'ACTIVE');
    }
}

sub createNewUser{
	my ($username, $email_prefix, $userrealm, $fname, $lname, $email, $type) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Create New User");
                fail("Cloud is still processing - createNewUser $username $email_prefix $userrealm $fname $lname $email $type");
                next;
        }
	my $command_output = "";
	mylog("Remote call to create new user (username = $username, $email_prefix @ $userrealm, $fname $lname at $email with type $type)");

	my $db_st = $db_conn->prepare("SELECT COUNT(id) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND email_prefix = ?");
        $db_st->bind_param(1, lc($userrealm));
        $db_st->bind_param(2, lc($email_prefix));
        my $res = $db_st->execute();
	
	if ($db_st->fetchrow_array ne '0'){
		sendUserFailMail($username, $email_prefix, $userrealm, "Email prefix already exists in the database");
		fail("Email prefix already exists in the database - $email_prefix");
		next;
	}

	if ($email_prefix =~ m/[^a-z0-9\#\^\*\~\.\-\_]/) {
		sendUserFailMail($username, $email_prefix, $userrealm, "Email prefix contains not allowed characters");
	        fail("Email prefix contains not allowed characters - $email_prefix");
		next;
	}

	$db_st = $db_conn->prepare("SELECT COUNT(id) FROM network.eseri_user WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND username = ?");
	$db_st->bind_param(1, lc($userrealm));
	$db_st->bind_param(2, lc($username));
	$res = $db_st->execute();

	if ($username eq '' or $db_st->fetchrow_array ne '0'){
	    #Make username based on the email_prefix
	    $username = makeUsername($email_prefix, $userrealm);
	    if ($username eq ''){
		sendUserFailMail($username, $email_prefix, $userrealm, "Could not come up with a username");	
		fail("Could not come up with a username - $username");
                next;
	    }
	}
	
	#Get cloud timezone
	my $timezone = $db_conn->selectall_arrayref("SELECT timezone FROM network.timezone_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, $userrealm)->[0]->[0];
	
	#Insert the user into the DB immediately so system manager sees it show up as 'in progress'
	mylog("Inserting $username, $email_prefix at $userrealm, $fname $lname from $email with type $type");
	my $insert_user = $db_conn->prepare("INSERT INTO network.eseri_user (username, password, email_prefix, organization, real_email, first_name, last_name, status, type, double_lock_option, timezone) VALUES (?, ?, ?, (SELECT DISTINCT id FROM network.organization WHERE network_name = ?), ?, ?, ?, 'PROCESSING', ?, 'OFF', ?) RETURNING id");
	$insert_user->bind_param(1, lc($username));
	$insert_user->bind_param(2, &makePassword);
	$insert_user->bind_param(3, lc($email_prefix));
	$insert_user->bind_param(4, $userrealm);
	$insert_user->bind_param(5, lc($email));
	$insert_user->bind_param(6, $fname);
	$insert_user->bind_param(7, $lname);
	$insert_user->bind_param(8, $type);
	$insert_user->bind_param(9, $timezone);
	my $insert_res = $insert_user->execute();
	if (! $insert_res){
		fail("Could not insert user: $DBI::errstr");
		next;
	}

	my @new_user_vars :shared;
	$new_user_vars[0] = "$username";
	$new_user_vars[1] = "$email_prefix";
	$new_user_vars[2] = "$userrealm";
	$new_user_vars[3] = "$fname";
	$new_user_vars[4] = "$lname";
	$new_user_vars[5] = "$email";
	$new_user_vars[6] = "$type";
	my $var_ref :shared;
	$var_ref = \@new_user_vars;
	$new_user_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been enqueued for creation processing")});
	return $resultRef;
}

sub changeUserPassword{
	my ($username, $userrealm, $newPassword) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Change User Password");
                fail("Cloud is still processing - changeUserPassword $username $userrealm $newPassword");
                next;
        }
	mylog("Remote call to change user password ($username @ $userrealm) to $newPassword");
	my @change_password_vars :shared;
	$change_password_vars[0] = "$username";
	$change_password_vars[1] = "$userrealm";
	$change_password_vars[2] = "$newPassword";
	my $var_ref :shared;
	$var_ref = \@change_password_vars;
	$change_password_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been enqueued for password change")});
	return $resultRef;
}

sub deleteUser{
	my ($username, $userrealm) = @_;
	mylog("Remote call to delete user ($username @ $userrealm)");
	my @delete_user_vars :shared;
	$delete_user_vars[0] = "$username";
	$delete_user_vars[1] = "$userrealm";
	my $var_ref :shared;
	$var_ref = \@delete_user_vars;
	$delete_user_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been been enqueued for deletion")});
	return $resultRef;
}

sub archiveUser{
	my ($username, $userrealm) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Archive User");
                fail("Cloud is still processing - archiveUser $username $userrealm");
                next;
        }
	mylog("Remote call to archive user ($username @ $userrealm)");
	my $user_status = $db_conn->selectall_arrayref("SELECT status FROM network.eseri_user_public WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, ($username, $userrealm))->[0]->[0];
	if ($user_status ne "ACTIVE"){
		my $resultRef = new RPC::XML::struct({
			Success => new RPC::XML::boolean("false"),
			Reason => new RPC::XML::string("User state is $user_status and must be ACTIVE")});
		return $resultRef;
	}

	my $archive_user = $db_conn->prepare("UPDATE network.eseri_user SET status = 'ARCHIVING' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
	$archive_user->bind_param(1, $username);
	$archive_user->bind_param(2, $userrealm);
	$archive_user->execute();

	my @archive_user_vars :shared;
	$archive_user_vars[0] = "$username";
	$archive_user_vars[1] = "$userrealm";
	my $var_ref :shared;
	$var_ref = \@archive_user_vars;
	$archive_user_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been been enqueued for archiving")});
	return $resultRef;
}

sub restoreUser{
	my ($username, $userrealm) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Restore User");
                fail("Cloud is still processing - restoreUser $username $userrealm");
                next;
        }
	mylog("Remote call to restore user ($username @ $userrealm)");
	my $user_status = $db_conn->selectall_arrayref("SELECT status FROM network.eseri_user_public WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, ($username, $userrealm))->[0]->[0];
	if ($user_status ne "ARCHIVED"){
		my $resultRef = new RPC::XML::struct({
			Success => new RPC::XML::boolean("false"),
			Reason => new RPC::XML::string("User state is $user_status and must be ARCHIVED")});
		return $resultRef;
	}
	my $archive_user = $db_conn->prepare("UPDATE network.eseri_user SET status = 'ACTIVATING' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
	$archive_user->bind_param(1, $username);
	$archive_user->bind_param(2, $userrealm);
	$archive_user->execute();

	my @restore_user_vars :shared;
	$restore_user_vars[0] = "$username";
	$restore_user_vars[1] = "$userrealm";
	my $var_ref :shared;
	$var_ref = \@restore_user_vars;
	$restore_user_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been been enqueued for restoration")});
	return $resultRef;
}

sub resetUser{
	my ($username, $userrealm) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Reboot User");
                fail("Cloud is still processing - resetUser $username $userrealm");
                next;
        }
	mylog("Remote call to reset user ($username @ $userrealm)");
	my @reset_user_vars :shared;
	$reset_user_vars[0] = "$username";
	$reset_user_vars[1] = "$userrealm";
	my $var_ref :shared;
	$var_ref = \@reset_user_vars;
	$reset_user_queue->enqueue($var_ref);
	my $resultRef = new RPC::XML::struct({
		Success => new RPC::XML::boolean("true"),
		Reason => new RPC::XML::string("User $username from organization $userrealm has been been enqueued to have their desktop reset")});
	return $resultRef;
}

sub changeExternalEmail{
        my ($username, $userrealm, $newExternalEmail) = @_;
	if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Change User External Email");
                fail("Cloud is still processing - changeExternalEmail $username $userrealm $newExternalEmail");
                next;
        }
        mylog("Remote call to change user External E-mail ($username @ $userrealm) to $newExternalEmail");
        my @change_externalemail_vars :shared;
        $change_externalemail_vars[0] = "$username";
        $change_externalemail_vars[1] = "$userrealm";
        $change_externalemail_vars[2] = "$newExternalEmail";
        my $var_ref :shared;
        $var_ref = \@change_externalemail_vars;
        $change_externalemail_queue->enqueue($var_ref);
        my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("User $username from organization $userrealm has been enqueued for External E-mail change")});
        return $resultRef;
}

sub changeDLOption{
        my ($username, $userrealm, $newDLOption) = @_;
        if (getCloudStatus($userrealm)==1) {
                sendAdminProcessingMail($userrealm, "Change User Double-Lock Option");
                fail("Cloud is still processing - changeDLOption $username $userrealm $newDLOption");
                next;
        }
	mylog("Remote call to change user Double-Lock Option ($username @ $userrealm) to $newDLOption");
        my @change_dloption_vars :shared;
        $change_dloption_vars[0] = "$username";
        $change_dloption_vars[1] = "$userrealm";
        $change_dloption_vars[2] = "$newDLOption";
        my $var_ref :shared;
        $var_ref = \@change_dloption_vars;
        $change_dloption_queue->enqueue($var_ref);
        my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("User $username from organization $userrealm has been enqueued for Double-Lock option change")});
        return $resultRef;
}

sub changeDomainConfig{
	my ($userrealm, $new_config_version, $domain_config_array) = @_;

	my $new_email_domain = @$domain_config_array[0];
	my $new_imap_server = @$domain_config_array[1];
	my $new_alias_domain = @$domain_config_array[2];
	my $new_website_ip = @$domain_config_array[3];

	# Removing first character.
	$new_config_version =~  s/^.//;
	$new_website_ip =~ s/^.//;

	if (getUserStatus($userrealm)==1 or getCloudStatus($userrealm, 'dc')==1) {
                sendAdminProcessingMail($userrealm, "Change Cloud Domain");
                fail("Cloud is still processing - changeDomainConfig $userrealm $new_config_version $new_email_domain $new_imap_server $new_alias_domain $new_website_ip");
                next;
        }

	updateCloudConfigStatus($db_conn, $userrealm, 'dc', 'PROCESSING');

	mylog("Remote call to change the Domain Configuration for $userrealm with params $new_config_version $new_email_domain $new_imap_server $new_alias_domain $new_website_ip");
	my @domain_config_vars :shared;
        $domain_config_vars[0] = "$userrealm";
	$domain_config_vars[1] = "$new_config_version";
        $domain_config_vars[2] = "$new_email_domain";
	$domain_config_vars[3] = "$new_imap_server";
	$domain_config_vars[4] = "$new_alias_domain";
	$domain_config_vars[5] = "$new_website_ip";
        my $var_ref :shared;
        $var_ref = \@domain_config_vars;
        $domain_config_queue->enqueue($var_ref);
        my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Domain Configuration to option $new_config_version")});
        return $resultRef;
}

sub changeCloudCapabilityConfig{
    my ($userrealm, $capability, $enable) = @_;
    
    if (getUserStatus($userrealm)==1 or getCloudStatus($userrealm, 'ccc')==1) {
	sendAdminProcessingMail($userrealm, "Change Cloud Capability Config");
	fail("Cloud is still processing - changeCloudCapabilityConfig $userrealm");
	next;
    }
 
    updateCloudConfigStatus($db_conn, $userrealm, 'ccc', 'PROCESSING');
    
    mylog("Remote call to change the Cloud Capability Configuration for $userrealm");
    my @cloudcapabilityconfig_vars :shared;
    $cloudcapabilityconfig_vars[0] = "$userrealm";
    $cloudcapabilityconfig_vars[1] = "@$capability";
    $cloudcapabilityconfig_vars[2] = "@$enable";
    my $var_ref :shared;
    $var_ref = \@cloudcapabilityconfig_vars;
    $cloudcapabilityconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for  CloudCapability Configuration")});
    return $resultRef;
}

sub insertCloudManagerReq{
	my ($userrealm, $hash, $data, $new_string, $amount) = @_;
	$amount = sprintf ("%.2f", $amount);
	mylog("Remote call to insert the Cloud Manager Request for $userrealm with amount: $amount and new string: $new_string");
        my @insert_cloud_manager_req_vars :shared;
        $insert_cloud_manager_req_vars[0] = "$userrealm";
        $insert_cloud_manager_req_vars[1] = "$hash";
        $insert_cloud_manager_req_vars[2] = "$data";
	$insert_cloud_manager_req_vars[3] = "$new_string";
	$insert_cloud_manager_req_vars[4] = "$amount";
        my $var_ref :shared;
        $var_ref = \@insert_cloud_manager_req_vars;
        $insert_cloud_manager_req_queue->enqueue($var_ref);
        my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Insert Cloud Manager Request")});
        return $resultRef;
}

sub processCloudManagerReq{
    my ($userrealm, $hash) = @_;
    mylog("Remote call to process the Cloud Manager Request for $userrealm with hash: $hash");
    my @process_cloud_manager_req_vars :shared;
    $process_cloud_manager_req_vars[0] = "$userrealm";
    $process_cloud_manager_req_vars[1] = "$hash";
    my $var_ref :shared;
    $var_ref = \@process_cloud_manager_req_vars;
    $process_cloud_manager_req_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Process Cloud Manager Request")});
    return $resultRef;
}

sub changeTimezoneConfig{
    my ($userrealm, $new_timezone, $server_user, $username) = @_;

    if ($server_user eq 'server'){
	if (getUserStatus($userrealm)==1) {
	    sendAdminProcessingMail($userrealm, "Change Cloud Timezone");
	    fail("Cloud is still processing - changeTimezoneConfig $userrealm $new_timezone, $server_user, $username");
	    next;
	}
	updateCloudConfigStatus($db_conn, $userrealm, 'tzc', 'PROCESSING');
    }

    mylog("Remote call to change the Timezone Configuration for $userrealm to $new_timezone- $server_user - $username");
    my @timezone_config_vars :shared;
    $timezone_config_vars[0] = "$userrealm";
    $timezone_config_vars[1] = "$new_timezone";
    $timezone_config_vars[2] = "$server_user";
    $timezone_config_vars[3] = "$username";
    my $var_ref :shared;
    $var_ref = \@timezone_config_vars;
    $timezone_config_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Timezone Configuration to $new_timezone - $server_user - $username")});
    return $resultRef;
}

sub changeFirewallProxyConfig{
    my ($userrealm, $capability, $external_name, $ssl) = @_;

    if (getUserStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "Change Firewall Proxy Config");
	fail("Cloud is still processing - changeFirewallProxyConfig $userrealm $capability $external_name $ssl");
	next;
    }	

    updateCloudConfigStatus($db_conn, $userrealm, 'fpc', 'PROCESSING');
    
    mylog("Remote call to change the Firewall Proxy Configuration for $userrealm");
    my @firewall_proxy_config_vars :shared;
    $firewall_proxy_config_vars[0] = "$userrealm";
    $firewall_proxy_config_vars[1] = "@$capability";
    $firewall_proxy_config_vars[2] = "@$external_name";
    $firewall_proxy_config_vars[3] = "@$ssl";
    my $var_ref :shared;
    $var_ref = \@firewall_proxy_config_vars;
    $firewallproxy_config_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Firewall_Proxy Configuration")});
    return $resultRef;
}

sub cloudReboot{
    my ($userrealm)  = @_;
    if (getCloudStatus($userrealm)==1 or getUserStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "Cloud Reboot");
	fail("Cloud is still processing - cloudReboot $userrealm");
	next;
    }
    
    mylog("Remote call to reboot cloud $userrealm");
    my @cloudreboot_vars :shared;
    $cloudreboot_vars[0] = "$userrealm";
    my $var_ref :shared;
    $var_ref = \@cloudreboot_vars;
    $cloudreboot_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for Cloud Reboot")});
    return $resultRef;
}

sub changeUserAliasConfig{
    my ($userrealm, $option, $username, $alias)  = @_;
    if (getCloudStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "User Alias Config");
	fail("Cloud is still processing - User Alias Config $userrealm");
	next;
    }
    
    mylog("Remote call to $option alias $alias for username $username at realm $userrealm");
    my @useraliasconfig_vars :shared;
    $useraliasconfig_vars[0] = "$userrealm";
    $useraliasconfig_vars[1] = "$option";
    $useraliasconfig_vars[2] = "$username";
    $useraliasconfig_vars[3] = "$alias";
    my $var_ref :shared;
    $var_ref = \@useraliasconfig_vars;
    $useraliasconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for User Alias Config")});
    return $resultRef;
}

sub changeUserPrimaryEmailConfig{
    my ($userrealm, $username, $old_email, $new_email)  = @_;
    if (getCloudStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "User Primary Email Config");
	fail("Cloud is still processing - User Primary Email Config $userrealm");
	next;
    }
    
    my @userprimaryemailconfig_vars :shared;
    $userprimaryemailconfig_vars[0] = "$userrealm";
    $userprimaryemailconfig_vars[1] = "@$username";
    $userprimaryemailconfig_vars[2] = "@$old_email";
    $userprimaryemailconfig_vars[3] = "@$new_email";
    my $var_ref :shared;
    $var_ref = \@userprimaryemailconfig_vars;
    $userprimaryemailconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for User Primary Config")});
    return $resultRef;
}

sub changeUserFullnameConfig{
    my ($userrealm, $username, $old_firstname, $old_lastname, $new_firstname, $new_lastname)  = @_;
    if (getCloudStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "User Fullname Config");
	fail("Cloud is still processing - User Fullname Config $userrealm");
	next;
    }
    
    my @userfullnameconfig_vars :shared;
    $userfullnameconfig_vars[0] = "$userrealm";
    $userfullnameconfig_vars[1] = "@$username";
    $userfullnameconfig_vars[2] = "@$old_firstname";
    $userfullnameconfig_vars[3] = "@$old_lastname";
    $userfullnameconfig_vars[4] = "@$new_firstname";
    $userfullnameconfig_vars[5] = "@$new_lastname";
    my $var_ref :shared;
    $var_ref = \@userfullnameconfig_vars;
    $userfullnameconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for User Fullname Config")});
    return $resultRef;
}

sub changeUserType{
    my ($userrealm, $params)  = @_;
    if (getCloudStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "changeUserType");
	fail("Cloud is still processing - Change User Type $userrealm");
	next;
    }

    my $username = @$params[0];
    my $new_user_type = @$params[1];

    if ($new_user_type eq 'Everything'){
	$new_user_type = 'full';
    }
    elsif ($new_user_type eq 'Email Only'){
	$new_user_type = 'email_only';
    }

    my $change_usertype = $db_conn->prepare("UPDATE network.eseri_user SET status = 'UPDATING' WHERE username = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)");
    $change_usertype->bind_param(1, $username);
    $change_usertype->bind_param(2, $userrealm);
    $change_usertype->execute();

    mylog("Remote call to change user type for $username to $new_user_type at realm $userrealm");
    my @changeusertype_vars :shared;
    $changeusertype_vars[0] = "$userrealm";
    $changeusertype_vars[1] = "$username";
    $changeusertype_vars[2] = "$new_user_type";
    my $var_ref :shared;
    $var_ref = \@changeusertype_vars;
    $changeusertype_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for User Type change")});
    return $resultRef;
}

sub changeFirewallPortConfig{
    my ($userrealm, $params)  = @_;

    my $username = @$params[0];
    my $port = @$params[1];

    if ($username eq '' or $port eq '' or $port <= 1024){
	mylog("Remote call from $userrealm to configure firewall port will not proceed futher because of username/port error - $username $port");
	next;
    }

    mylog("Remote call to configure port $port at firewall server for $username at realm $userrealm");
    my @firewallportconfig_vars :shared;
    $firewallportconfig_vars[0] = "$userrealm";
    $firewallportconfig_vars[1] = "$username";
    $firewallportconfig_vars[2] = "$port";
    my $var_ref :shared;
    $var_ref = \@firewallportconfig_vars;
    $firewallportconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for configuring Firewall Port")});
    return $resultRef;
}

sub changeBackupConfig{
    my ($userrealm, $params)  = @_;

    my $option = @$params[0];
    my $profile_id = @$params[1];
    my $name = @$params[2];
    my $frequency_number = @$params[3];
    my $frequency_duration = @$params[4];
    my $time = @$params[5];
    my $target_url = @$params[6];
    my $enabled = @$params[7];
    my $snapshot = @$params[8];

    if (getUserStatus($userrealm)==1) {
	sendAdminProcessingMail($userrealm, "Change Backup Config");
	fail("Cloud is still processing - changeBackupConfig $userrealm $option profile_id $name $frequency_number $frequency_duration $time $target_url $enabled $snapshot");
	next;
    }

    ($option ne 'snapshot') ? (updateCloudConfigStatus($db_conn, $userrealm, 'bc', 'PROCESSING')) : ();

    mylog("Remote call from $userrealm to $option backup - Profile ID = $profile_id, Name = $name, Frequency = $frequency_number $frequency_duration, Time = $time, Target URL = $target_url, Enabled = $enabled, Snapshot = $snapshot");

    my @backupconfig_vars :shared;
    $backupconfig_vars[0] = "$userrealm";
    $backupconfig_vars[1] = "$option";
    $backupconfig_vars[2] = "$profile_id";
    $backupconfig_vars[3] = "$name";
    $backupconfig_vars[4] = "$frequency_number";
    $backupconfig_vars[5] = "$frequency_duration";
    $backupconfig_vars[6] = "$time";
    $backupconfig_vars[7] = "$target_url";
    $backupconfig_vars[8] = "$enabled";
    $backupconfig_vars[9] = "$snapshot";

    my $var_ref :shared;
    $var_ref = \@backupconfig_vars;
    $backupconfig_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for configuring backup")});
    return $resultRef;
}

sub restoreFilePath{
    my ($userrealm, $params)  = @_;

    my $username = @$params[0];
    my $profile_id = @$params[1];
    my $time = @$params[2];
    my $source = @$params[3];
    my $destination = @$params[4];

    mylog("Remote call from $userrealm to restore file for $username - Profile ID = $profile_id, Time = $time, Source = $source, Destination = $destination");

    my @restorefilepath_vars :shared;
    $restorefilepath_vars[0] = "$userrealm";
    $restorefilepath_vars[1] = "$username";
    $restorefilepath_vars[2] = "$profile_id";
    $restorefilepath_vars[3] = "$time";
    $restorefilepath_vars[4] = "$source";
    $restorefilepath_vars[5] = "$destination";

    my $var_ref :shared;
    $var_ref = \@restorefilepath_vars;
    $restorefilepath_queue->enqueue($var_ref);
    my $resultRef = new RPC::XML::struct({
	Success => new RPC::XML::boolean("true"),
	Reason => new RPC::XML::string("Organization $userrealm has been enqueued for restoring file path")});
    return $resultRef;
}

sub changeSystemAnchorConfig{
	my ($userrealm, $system_anchor_config_array) = @_;

	my $new_system_anchor_domain = @$system_anchor_config_array[0];
	my $new_system_anchor_ip = @$system_anchor_config_array[1];
	my $new_system_anchor_netmask = @$system_anchor_config_array[2];

	# Removing first character.
	$new_system_anchor_ip =~ s/^.//;
	$new_system_anchor_netmask =~ s/^.//;

	if (getUserStatus($userrealm)==1 or getCloudStatus($userrealm, 'dc')==1) {
                sendAdminProcessingMail($userrealm, "Change System Anchor");
                fail("Cloud is still processing - changesystemAnchorConfig $userrealm $new_system_anchor_domain $new_system_anchor_ip $new_system_anchor_netmask");
                next;
        }

	# Update dc status since this only applies to the system manager cloud.
	updateCloudConfigStatus($db_conn, $userrealm, 'dc', 'PROCESSING');

	mylog("Remote call to change the System Anchor Configuration for $userrealm with params $userrealm $new_system_anchor_domain $new_system_anchor_ip $new_system_anchor_netmask");
	my @system_anchor_config_vars :shared;
        $system_anchor_config_vars[0] = "$userrealm";
	$system_anchor_config_vars[1] = "$new_system_anchor_domain";
        $system_anchor_config_vars[2] = "$new_system_anchor_ip";
        $system_anchor_config_vars[3] = "$new_system_anchor_netmask";
        my $var_ref :shared;
        $var_ref = \@system_anchor_config_vars;
        $system_anchor_config_queue->enqueue($var_ref);
        my $resultRef = new RPC::XML::struct({
                Success => new RPC::XML::boolean("true"),
                Reason => new RPC::XML::string("Organization $userrealm has been enqueued for System Anchor Configuration.")});
        return $resultRef;
}
