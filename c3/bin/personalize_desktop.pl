#!/usr/bin/perl -w
#
# personalize_desktop.pl - v6.2
#
# This script creates the desktop account and configures it for use in different multi-user apps.
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

###########################
#Imports and declarations
###########################
use Getopt::Long;
use Pod::Usage;
use XML::XPath;
use XML::XPath::XMLParser;
use Net::SSH::Perl;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use Sys::Syslog;
use WWW::Mechanize;
use Proc::Reliable;
use Config::General;
use subs qw(mylog fail);
use XML::LibXML;
use Net::SCP::Expect;
use Config::General;
use MIME::Lite::TT::HTML;
use Comms qw(ssh scp ssh_key get_system_anchor_domain);
use Digest::MD5 qw(md5_hex);

##########################
#Configuration
##########################
# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();

my $conf = new Config::General("personalize_desktop.config");
my %config = $conf->getall;
for (values %config) {s|\[-system_anchor_domain-\]|$system_anchor_domain|g};

my $DBNAME = $config{"dbname"};
my $DBHOST = $config{"dbhost"};
my $DBKEYTAB = $config{"dbkeytab"};
my $DBPRINCIPAL = $config{"dbprincipal"};
my $DBUSER = $config{"dbuser"};
my $DBPASS = $config{"dbpass"};
my $ERROREMAILADDRESS = $config{"erroremailaddress"};
my $FROMEMAILADDRESS = $config{"fromemailaddress"};

########################
#Variables
########################
my $verbose = 0;
my $dbuserid = '';
my $db_log;
my $nxrun = "FALSE";
my $sshConn = '';
my $stdout = '';
my $stderr = '';
my $exit = '';
my $display = '';
my $userid = '';
my $nxsessions = '';
my @sessions = ();
my $db_conn = '';
my $username = '';
my $email_prefix = '';
my $network_name = '';
my @capabilities = ();
my @capabilities_enabled = ();
my $man = 0;
my $help = 0;
my $domain_config_version = '';
my $cloud_domain = '';
my $alias_domain = '';

#########################
#Options parsing
#########################
GetOptions ('username=s' => \$username, 'desired_email_prefix=s' => \$email_prefix, 'network_name=s' => \$network_name, 'help|?' => \$help, 'man' => \$man, 'verbose' => \$verbose) or pod2usage(2);
pod2usage(1) if $help;
pod2usage("-exitstatus" => 0, "-verbose" => 2) if $man;
pod2usage(-exitstatus => 1, -message => "Username is mandatory\n") if $username eq "";
pod2usage(-exitstatus => 1, -message => "User realm is mandatory\n") if $network_name eq "";

&makeDBConnection();

##########################
#Environment sanity checks
##########################
if (! defined $ENV{DISPLAY} || $ENV{DISPLAY} eq ''){
	fail("Display environment variable not set");
}

fail("Password scrambling command not found in cwd") if(! -x "./scramble_password.pl");

fail("Couldn't find template.nxs in the cwd") if (! -r "./template.nxs"); 

fail("Couldn't find accounts.xml in the cwd") if (! -r "./accounts.xml");

fail("Couldn't find blist.xml in the cwd") if (! -r "./blist.xml");

#We don't want any leftover NX sessions running, as our cleanup involves a nuking pass. So check n' warn n' die
my $nxresult = `nxkill --list`;
my @nxsessions = split(/\n/, $nxresult);
foreach my $nxsession (@nxsessions) {
	if ($nxsession =~ m/^Type.*/){
		next;
	}
	if ($nxsession =~ m/^-.*/){
		next;
	}
	chomp($nxsession);
	if ($nxsession ne ''){
		fail("There is an NX session currently running: " . @{[split(/\s+/, $nxsession)]}[1]);
	}
}

# Username character check
fail("Username contains not allowed characters: $username") if $username =~ m/[^a-z0-9]/;

#Retrieve needed info about our environment and our user from the configuration database
my $db_st = $db_conn->prepare("SELECT password FROM network.eseri_user WHERE organization=(SELECT id FROM network.organization WHERE network_name = ?) AND username=?");
$db_st->bind_param(1, "$network_name");
$db_st->bind_param(2, "$username");
$db_st->execute();
fail "User $username in realm $network_name was not found, terminating" if $db_st->rows == 0;
my $password = @{[$db_st->fetchrow_array()]}[0];
$db_st->finish;
fail "Could not retrieve password from database" if ($password eq "" || ! defined $password);

$db_st = $db_conn->prepare("SELECT id FROM network.eseri_user WHERE organization=(SELECT id FROM network.organization WHERE network_name = ?) AND username=?");
$db_st->bind_param(1, "$network_name");
$db_st->bind_param(2, "$username");
$db_st->execute();
$dbuserid = @{[$db_st->fetchrow_array()]}[0];
$db_st->finish;
fail "Could not retrieve user id from database" if (! defined $dbuserid || $dbuserid eq "");
mylog("DB user id is $dbuserid");

$db_st = $db_conn->prepare("SELECT first_name, last_name FROM network.eseri_user WHERE id = ?");
$db_st->bind_param(1, "$dbuserid");
$db_st->execute();
my ($firstname, $lastname) = $db_st->fetchrow_array();
$db_st->finish;
mylog("User full name is $firstname $lastname");

#Figure out the capabilities installed
$db_st = $db_conn->prepare("SELECT name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id from network.organization WHERE network_name = ?))");
$db_st->bind_param(1, "$network_name");
$db_st->execute();
while ((my $cap) = $db_st->fetchrow()){
	push(@capabilities, $cap);
}
$db_st->finish;
mylog("Capabilities: @capabilities");

#Figure out the capabilities enabled
$db_st = $db_conn->prepare("SELECT name FROM packages.capabilities WHERE capid IN (SELECT capability FROM packages.organizationcapabilities WHERE organization = (SELECT id from network.organization WHERE network_name = ?) and enabled = ?)");
$db_st->bind_param(1, "$network_name");
$db_st->bind_param(2, "t", PG_BOOL);
$db_st->execute();
while ((my $cap_e) = $db_st->fetchrow()){
        push(@capabilities_enabled, $cap_e);
}
$db_st->finish;
mylog("Enabled capabilities: @capabilities_enabled");

$db_st = $db_conn->prepare("SELECT full_name FROM network.organization WHERE network_name = ? ");
$db_st->bind_param(1, "$network_name");
$db_st->execute();
my ($orgname) = $db_st->fetchrow_array();
$db_st->finish;
mylog("Organization name is $orgname");

$db_st = $db_conn->prepare("SELECT config_version, email_domain, alias_domain FROM network.domain_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)");
$db_st->bind_param(1, lc($network_name));
$db_st->execute();
($domain_config_version, $cloud_domain, $alias_domain) = $db_st->fetchrow_array();
$db_st->finish;
mylog("Organization has config_version = $domain_config_version, email_domain = $cloud_domain, alias_domain = $alias_domain");

my $target_host = "chaos." . $network_name;
my $smtp_host = "smtp." . $network_name;
my $imap_host = "imap." . $network_name;
my $xmpp_host = "xmpp." . $network_name;
my $sync_host = "funambol." . $network_name;
my $mysql_host = "mysql." . $network_name;
my $pgsql_host = "pgsql." . $network_name;

my $mail_login = $username;
my $mail_login_escaped = $username;
if($domain_config_version eq '2.12'){
    mylog("Setting mail_login to <username>@<email_domain> for config_version 2.12");
    $mail_login = $email_prefix.'@'.$cloud_domain;
    $mail_login_escaped = $email_prefix.'%40'.$cloud_domain;
}

my $scpe = Net::SCP::Expect->new(host=>$target_host, user=>$username, password=>$password);

#Enable multi-user collaboration app sites for C3 creation
&sitesEnableDisable("enable");
#This creates the user in LDAP and Kerberos
&runEseriman();
#This sets up the SSH connection early to make the menu
&makeSSHConnection();
#This sets up the user's menu
&createMenu();
#This makes the configuration file for an NX connection
&makeNXConfFile();
#This runs an NX session and figures out the details of that session
&runNXFirstTime();
#This figures out the UID of the new user
&getUserID();
#This disables the screen saver
&disableScreenSaver();
#This makes a default keyring, with no password
&makeKeyring();
#This configures Evolution and SOGo
&configureEvolution();
#This runs and configures pidgin
&configurePidgin();
#This adds the user to Funambol
&configureFunambol();
#This configures the gnome-panel
&configureGnomePanel();
#This configures Syncthing
&configureSyncthing();
#This does a bunch of things, including running the browser and adding a desktop shortcut
&userInit();
#This edits the user wiki page
&configureWiki();
#This sets up the user's IMAP mail in Vtiger
&configureVtiger();
#This adds the user to SQL-Ledger
&configureSQLLedger();
#This adds the user to Redmine
&configureRedmine();
#This adds the user to PHPScheduleIt
&configurePHPScheduleIt();
#This adds the user to Drupal
&configureDrupal();
#This adds the user to ChurchInfo
&configureChurchInfo();
#This adds the user to Moodle
&configureMoodle();
#This adds the user to OpenERP
&configureOpenERP();
#This updates the user status in the database
&setUserActive();
#Disable the enabled multi-user collaboration app sites for C3 creation
&sitesEnableDisable("disable");


########################################################################
#Subroutine blocks go here
########################################################################

sub sitesEnableDisable{
	my ($option) = @_;
	my $a2_site_poseidon = '';
	(&has_capability("Nuxeo") and ! &has_enabled_capability("Nuxeo")) ? ($a2_site_poseidon .= 'nuxeo ') : ();
	(&has_capability("Timesheet") and ! &has_enabled_capability("Timesheet")) ? ($a2_site_poseidon .= 'timesheet ') : ();
	(&has_capability("Trac") and ! &has_enabled_capability("Trac")) ? ($a2_site_poseidon .= 'trac ') : ();
	(&has_capability("Wiki") and ! &has_enabled_capability("Wiki")) ? ($a2_site_poseidon .= 'wiki ') : ();
	(&has_capability("OrangeHRM") and ! &has_enabled_capability("OrangeHRM")) ? ($a2_site_poseidon .= 'orangehrm ') : ();
	(&has_capability("Vtiger") and ! &has_enabled_capability("Vtiger")) ? ($a2_site_poseidon .= 'vtiger ') : ();
	(&has_capability("SQLLedger") and ! &has_enabled_capability("SQLLedger")) ? ($a2_site_poseidon .= 'sqlledger ') : ();
	my $a2_site_trident = '';
	(&has_capability("Redmine") and ! &has_enabled_capability("Redmine")) ? ($a2_site_trident .= 'redmine ') : ();
	(&has_capability("PHPScheduleIt") and ! &has_enabled_capability("PHPScheduleIt")) ? ($a2_site_trident .= 'phpscheduleit ') : ();
	(&has_capability("Drupal") and ! &has_enabled_capability("Drupal")) ? ($a2_site_trident .= 'drupal ') : ();
	(&has_capability("CiviCRM") and ! &has_enabled_capability("CiviCRM")) ? ($a2_site_trident .= 'civicrm ') : ();
	(&has_capability("ChurchInfo") and ! &has_enabled_capability("ChurchInfo")) ? ($a2_site_trident .= 'churchinfo ') : ();
	(&has_capability("Moodle") and ! &has_enabled_capability("Moodle")) ? ($a2_site_trident .= 'moodle ') : ();
	
	#OpenERP has a special configuration cuz it runs on port 8069, so have to start/stop openerp process
	if (&has_capability("OpenERP") and ! &has_enabled_capability("OpenERP")){ 
	    $a2_site_trident .= 'openerp ';
	    my $initFunc = '';
	    ($option eq 'enable') ? ($initFunc = 'start') : ($initFunc = 'stop');	    
	    my $res = ssh( "trident.$network_name",
			   "sudo /etc/init.d/openerp $initFunc",
			   "eseriman" );
	    mylog("Result of trying to run was -\n$res");
	}

	my $apacheFunc = '';
	($option eq 'enable') ? ($apacheFunc = "a2ensite") : ($apacheFunc = "a2dissite");

	if ($a2_site_poseidon ne ''){
		my $a2ensite_poseidon = ssh( "poseidon.$network_name", 
					     "sudo $apacheFunc '$a2_site_poseidon'; sudo /etc/init.d/apache2 reload;",
					     "eseriman" );  # optional username # No, C3 can only ssh to eseriman, and eseriman can only call sudo, so not optional
                mylog("Result of trying to run was -\n$a2ensite_poseidon");
	}
	if ($a2_site_trident ne ''){
		my $a2ensite_trident = ssh( "trident.$network_name",
					    "sudo $apacheFunc '$a2_site_trident'; sudo /etc/init.d/apache2 reload;",
					    "eseriman" );
                mylog("Result of trying to run was -\n$a2ensite_trident");
	}
}

sub runEseriman{
	#Increments UID held in LDAP (better off in the DB?)
 	#Adds LDAP info to put user into Nuxeo group
	#Adds LDAP info for user in general
	#Adds LDAP info for chat group - XMPP
	#calls eseriCreateHomeFolder
	# which makes the home folder, populates from /etc/skel, makes empty diretories
	# and also adds the user to the local group 'lpadmin'
	mylog("Running eseriman to create account");
	my $use_chat  = (&has_capability("InstantMessaging")) ? "1" : "0";
	my $use_nuxeo  = (&has_capability("Nuxeo")) ? "1" : "0";
	mylog("Calling ssh eseriman\@$target_host './bin/eseriCreateAccount \"$username\" \"$email_prefix\" \"$lastname\" \"$firstname\" \"$cloud_domain\" \"$use_nuxeo\" \"$use_chat\"'");
	my $account_output = ssh( "$target_host",
				  "./bin/eseriCreateAccount '$username' '$email_prefix' '$lastname' '$firstname' '$cloud_domain' '$use_nuxeo' '$use_chat'",
				  "eseriman");

	#Adds principal to Kerberos KDC	
	mylog("Running eseriman to create password");
	my $password_output = ssh( $target_host, "./bin/eseriCreatePassword '$username' '$password'", "eseriman");
}

sub createMenu{
	#Don't bother with this if the user isn't a desktop user
	if (! &has_capability("Desktop")){
		mylog("Skipping createMenu");
		return;
	}
	
	my $applications_menu_filename='/tmp/c3user_applications_menu';
	my $settings_menu_filename='/tmp/c3user_settings_menu';
	`./create_menu.pl --capabilities_enabled "@capabilities_enabled" --applications_menu_filename "$applications_menu_filename" --settings_menu_filename "$settings_menu_filename" >&2`;

	$sshConn->cmd("mkdir -p /home/$username/.config/menus");
        my $hostdest = "/home/$username/.config/menus/applications.menu";
        $scpe->scp($applications_menu_filename,$hostdest);
	$hostdest = "/home/$username/.config/menus/settings.menu";
	$scpe->scp($settings_menu_filename,$hostdest);

	#Add gnome-screensaver-command to the autostart directory. Make that directory if we need to
	($stdout, $stderr, $exit) = $sshConn->cmd("mkdir -p /home/$username/.config/autostart");
	open GSC, "<gnome-screensaver-command.desktop";
	undef $/;
	my $gsc = <GSC>;
	close GSC;
	$/ = "\n";
	($stdout, $stderr, $exit) = $sshConn->cmd("cat > /home/$username/.config/autostart/gnome-screensaver-command.desktop", $gsc);
	if ($exit != 0) {fail ("Problem writing out gnome-screensaver-command autostart file $stdout $stderr")};

	# Change Shared Files to Shared Folder in Places menu	
	$sshConn->cmd("sed -i 's|Shared Files|Shared Folder|' /home/$username/.gtk-bookmarks");
}

sub makeNXConfFile{
	#Grab the DSA private key from the database
	$db_st = $db_conn->prepare("SELECT nxkey FROM network.organization WHERE network_name=?");
	$db_st->bind_param(1, "$network_name");
	$db_st->execute();
	my ($DSA_key) = $db_st->fetchrow();
	$db_st->finish;
	mylog("DSA key appears to be $DSA_key");

	#Develop an NXClient session file that will run auto-magically and establish the connection we need
	#Get the NX scrambled version of the password we were given
	mylog("Begin password scrambling for NX");
	my $scrambled_password=`./scramble_password.pl $password`;
	($? == 0) || fail("Failed to scramble password!");

	my $xpath = XML::XPath->new(filename => "template.nxs");
	$xpath->setNodeText('/NXClientSettings/group[@name="Login"]/option[@key="Auth"]/@value', "$scrambled_password");
	$xpath->setNodeText('/NXClientSettings/group[@name="Login"]/option[@key="User"]/@value', "$username");
	$xpath->setNodeText('/NXClientSettings/group[@name="General"]/option[@key="Server host"]/@value', "$target_host");
	$xpath->setNodeText('/NXClientSettings/group[@name="Login"]/option[@key="Public Key"]/@value', "$DSA_key");

	my $homedir=$ENV{'HOME'};
	open(CONFFILE, ">$homedir/.nx/config/$username.chaos.nxs") || fail("Couldn't open NX config file for writing");
	print CONFFILE "<!DOCTYPE NXClientSettings>\n";
	print CONFFILE $xpath->find('/')->get_node(1)->toString() || fail("Couldn't write to NX config file");
	print CONFFILE "\n";
	close(CONFFILE);

	mylog("Wrote NX client configuration file");
}

sub makeKeyring{
	if (! &has_capability("Desktop")){
		mylog("Skipping makeKeyring");
		return;
	}
	#Setup their default keyring
	mylog("Setting up passwordless default keyring");
	$sshConn->cmd("echo default > /home/$username/.gnome2/keyrings/default");
	$sshConn->cmd("echo '\n[keyring]\ndisplay-name=Default\nctime=0\nmtime=0\nlock-on-idle=false\nlock-after=false\n\n[1]\nitem-type=0\ndisplay-name=webdav://$username\@webmail.$alias_domain/SOGo/dav/$username/Contacts/personal/\nsecret=$password\nmtime=1292615328\nctime=0\n\n[1:attribute0]\nname=application\ntype=string\nvalue=Evolution\n\n[1:attribute1]\nname=protocol\ntype=string\nvalue=webdav\n\n[1:attribute2]\nname=server\ntype=string\nvalue=webmail.$alias_domain\n\n[1:attribute3]\nname=user\ntype=string\nvalue=$username\n' > /home/$username/.gnome2/keyrings/default.keyring");
	if($domain_config_version eq '2.11' or $domain_config_version eq '2.12'){
		mylog("Setting up passwordless evolution keyring for domain config version $domain_config_version");
		$sshConn->cmd("echo '\n[0]\nitem-type=0\ndisplay-name=imap://$mail_login_escaped\@imap.$alias_domain/\nsecret=$password\nmtime=1292615328\nctime=0\n\n[0:attribute0]\nname=application\ntype=string\nvalue=Evolution\n\n[0:attribute1]\nname=protocol\ntype=string\nvalue=imap\n\n[0:attribute2]\nname=server\ntype=string\nvalue=imap.$alias_domain\n\n[0:attribute3]\nname=user\ntype=string\nvalue=$mail_login\n' >> /home/$username/.gnome2/keyrings/default.keyring");
	}
}

sub configureEvolution{
	#Only performed for desktop users with email
	mylog("Starting to Configure Evolution");
	if (! (&has_capability("Email") && &has_capability("Desktop"))){
		mylog("Skipping configureEvolution");
		return;
	}
	($stdout, $stderr, $exit) = $sshConn->cmd("ldapsearch uid=$username 2>&1");
	fail ("Remote LDAP command failed $stdout $stderr") if ($exit != 0);
	my @ldap_out = split(/\n/, $stdout);
	my $ldap_base_dn='';
     	
	foreach my $ldap_val (@ldap_out){
		if ($ldap_val =~ m/^dn:/){
			$ldap_base_dn=@{[split(/people,/, $ldap_val)]}[1];
		}
	}
	fail ("Could not determine LDAP base") if ($ldap_base_dn eq '');
	
	my $sogo="False";
	if (&has_capability("SOGo")){
		$sogo="True";
	}
	
	mylog("About to run sed command: sed -e \"s|\\[-USERNAME-\\]|$username|;s|\\[-EMAIL_PREFIX-\\]|$email_prefix|;s|\\[-FIRSTNAME-\\]|$firstname|;s|\\[-LASTNAME-\\]|$lastname|;s|\\[-ORGNAME-\\]|$orgname|;s|\\[-LDAP_BASE_DN-\\]|$ldap_base_dn|;s|\\[-CLOUD_DOMAIN-\\]|$cloud_domain|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|\"");
	`cat /home/c3/bin/create_evolution_xml.pl.template | sed -e "s|\\[-USERNAME-\\]|$username|;s|\\[-EMAIL_PREFIX-\\]|$email_prefix|;s|\\[-FIRSTNAME-\\]|$firstname|;s|\\[-LASTNAME-\\]|$lastname|;s|\\[-ORGNAME-\\]|$orgname|;s|\\[-LDAP_BASE_DN-\\]|$ldap_base_dn|;s|\\[-CLOUD_DOMAIN-\\]|$cloud_domain|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|" > /home/c3/bin/create_evolution_xml.pl`;
	`chmod a+x /home/c3/bin/create_evolution_xml.pl`;
	mylog("create_evolution_xml.pl file is generated, chmodded and ready to be run.");
	`./create_evolution_xml.pl >&2`;
	
	my $hostdest = "/home/$username/.evolutionconf.xml";
	$scpe->scp('/home/c3/bin/evolutionconf.xml',$hostdest);	
	mylog("Copied evolutionconf.xml file on target host");
	
	($stdout, $stderr, $exit) = $sshConn->cmd("mkdir -p /home/$username/.evolution/mail/config");
	
	#Copy the two files which handle configuration specific to evolution over to chaos
	$hostdest = "/home/$username/.evolution/mail/config";
	$scpe->scp('/home/c3/bin/folder-tree-expand-state.xml',$hostdest);
	mylog("Copied file1 under /home/$username/.evolution/mail/config on target host");

	$scpe->scp('/home/c3/bin/et-expanded-imap',$hostdest);
	mylog("Copied file2 under /home/$username/.evolution/mail/config on target host");	
	($stdout, $stderr, $exit) = $sshConn->cmd("mv /home/$username/.evolution/mail/config/et-expanded-imap /home/$username/.evolution/mail/config/et-expanded-imap:__$username\@imap.$alias_domain\_INBOX");
	($stdout, $stderr, $exit) = $sshConn->cmd("chown -r $username:$username /home/$username/.evolution");

	#Change the imap auth type from GSSAPI to PASSWORD and username for domain config version 2.11 and 2.12
	if($domain_config_version eq '2.11' or $domain_config_version eq '2.12'){
                ($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e \"s|imap\:\/\/$username\;auth=GSSAPI\@imap.$alias_domain\/\;|imap\:\/\/$mail_login_escaped\@imap.$alias_domain\/\;|g\" /home/$username/.evolutionconf.xml"); 
		($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e \"s|imap\:\/\/$username\@imap.$alias_domain\/Drafts|imap\:\/\/$mail_login_escaped\@imap.$alias_domain\/Drafts|g\" /home/$username/.evolutionconf.xml");
                ($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e \"s|imap\:\/\/$username\@imap.$alias_domain\/Sent|imap\:\/\/$mail_login_escaped\@imap.$alias_domain\/Sent|g\" /home/$username/.evolutionconf.xml");
		($stdout, $stderr, $exit) = $sshConn->cmd("rm -rf /home/$username/.evolution/mail/config/et-expanded-imap*");
		($stdout, $stderr, $exit) = $sshConn->cmd("echo -e '<?xml version=\"1.0\"?>\n<tree-state>\n  <node name=\"local\" expand=\"false\"/>\n  <node name=\"vfolder\" expand=\"false\"/>\n  <node name=\"1337374872.661.24\@chaos\" expand=\"true\"><node name=\"INBOX\" expand=\"false\"/></node>\n  <selected uri=\"imap://$mail_login_escaped\@imap.$alias_domain/INBOX\"/>\n</tree-state>' > /home/$username/.evolution/mail/config/folder-tree-expand-state.xml");
        }

	#Load the xml file using gconftool
        ($stdout, $stderr, $exit) = $sshConn->cmd("gconftool-2 --load /home/$username/.evolutionconf.xml");

	`rm /home/c3/bin/evolutionconf.xml`;
	`rm /home/c3/bin/folder-tree-expand-state.xml`;
	`rm /home/c3/bin/et-expanded-imap`;	
	
	#Modify user mail preferences and add junk filter for SOGo.
        mylog("SOGo configuration started");
	my $configure_sogo_script = '/home/c3/bin/configure_sogo.sh';
	mylog("About to run sed command: sed -e \"s|\\[-USERNAME-\\]|$username|;s|\\[-EMAIL_PREFIX-\\]|$email_prefix|;s|\\[-CLOUD_DOMAIN-\\]|$cloud_domain|;\"");
	`cat $configure_sogo_script.template | sed -e "s|\\[-USERNAME-\\]|$username|;s|\\[-EMAIL_PREFIX-\\]|$email_prefix|;s|\\[-CLOUD_DOMAIN-\\]|$cloud_domain|;" > $configure_sogo_script`;
	scp("$configure_sogo_script", "root\@hades.$network_name:/tmp");
	ssh("hades.$network_name", "chmod +x /tmp/configure_sogo.sh; bash /tmp/configure_sogo.sh >&2");
	mylog("SOGo configuration completed");

	# Init Dovecot Sieve for Junk mail flagging
	# The Sogo preferences need a simple Save/close to trigger creation of a Dovecot Sieve script on Hera
	# subs Domain and User into script template
	mylog("About to run sed command: sed -e \"s|\\[-USERNAME-\\]|$username|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|\"");
	`cat /home/c3/bin/sogo_manage_sieve.py.template | sed -e "s|\\[-USERNAME-\\]|$username|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|" > /home/c3/bin/sogo_manage_sieve.py`;
	`chmod a+x /home/c3/bin/sogo_manage_sieve.py`;
	mylog("sogo_manage_sieve.py file is generated, chmodded and ready to be copied");
	# copy script to chaos, run it and remove it
	$scpe->scp("/home/c3/bin/sogo_manage_sieve.py", "/home/$username");
	($stdout, $stderr, $exit) = $sshConn->cmd("export DISPLAY=0:$display; python /home/$username/sogo_manage_sieve.py");
	mylog("Result of trying to run was -\n$stdout");
	if ($exit != 0){
	    fail("Error initSieve, $stderr");
	}
	($stdout, $stderr, $exit) = $sshConn->cmd("rm /home/$username/sogo_manage_sieve.py");
	
	# Create Business Calendar in SOGo
	($stdout, $stderr, $exit) = $sshConn->cmd("wget --user=$username --password=$password --post-data='name=Business Calendar' http://webmail.$alias_domain/SOGo/so/$username/Calendar/createFolder");
	if ($exit != 0){
            fail("Error: Could not create Business Calendar, $stdout, $stderr");
        }
	else{
	    # Get folder name of the newly created calendar
	    my ($stdout, $stderr, $exit) = $sshConn->cmd("cat /home/$username/createFolder && rm /home/$username/createFolder");
	    # Replace the folder name with 'business'
	    my $res = ssh( "hades.$network_name",'su - -c \"psql -d sogo << EOF
UPDATE sogo_folder_info SET c_path = REPLACE (c_path, \''.$stdout.'\', \'business\'), c_path4 = REPLACE (c_path4, \''.$stdout.'\', \'business\') WHERE c_path4 = \''.$stdout.'\';
EOF\" postgres');
	    mylog("Business Calendar $stdout renamed to business.");
	    mylog("Result of trying to run was -\n$res");
	}

	#Add CA certificate to Evolution which won't use the system-wide settings
	mylog("Running certutil for import");
	mylog("certutil -A -n \"$orgname\" -t \"TCu,TCu,TCu\" -d /home/$username/.evolution -i /usr/share/ca-certificates/$network_name/$network_name.crt");
	($stdout, $stderr, $exit) = $sshConn->cmd("certutil -A -n \"$orgname\" -t \"TCu,TCu,TCu\" -d /home/$username/.evolution -i /usr/share/ca-certificates/$network_name/$network_name.crt");
	unless ($exit == 0){fail("Certutil screwed up: $stdout, $stderr")};

	# Killing gconfd so that gconf settings are saved, and we can open evolution.
	($stdout, $stderr, $exit) = $sshConn->cmd("ps -C gconfd-2 -o pid= -o ruser= | grep $username | awk '{print \$1}'");
	mylog("Killing gconfd-2 process with pid $stdout");
	if ($stdout ne ''){
	    $sshConn->cmd("kill -9 $stdout");
	}

	# Starting evolution, so that the next time the user opens evolution, the Sent folder will appear instead of it being replaced by "Loading..."
	mylog("About to start evolution");
	my $run_process = "export DISPLAY=0:$display; evolution";
	`./run_process.pl "$username" "$password" "$target_host" "$run_process" >&2 &`;

	my $evolution_is_ready = 0;
	while (! $evolution_is_ready ){
	    sleep(5);
	    ($stdout, $stderr, $exit) = $sshConn->cmd("ls /home/$username/.evolution/mail/imap/");
	    $evolution_is_ready = ($exit == 0);
        }

	($stdout, $stderr, $exit) = $sshConn->cmd("ps -C evolution -o pid= -o ruser= | grep $username | awk '{print \$1}'");
	mylog("Killing evolution process with pid $stdout");
        if ($stdout ne ''){
            $sshConn->cmd("kill -9 $stdout");
        }
}

sub configurePidgin{
	#Don't run if users doesn't have desktop with instant messaging
	if (! (&has_capability("InstantMessaging") && &has_capability("Desktop"))){
		mylog("Skipping configurePidgin");
		return;
	}
	mylog("About to run pidgin");
	my $run_process = "pidgin --display 0:$display";
	`./run_process.pl "$username" "$password" "$target_host" "$run_process" >&2 &`;
	#Again, loop until we see a file we need then kill Pidgin
	my $pidgin_is_ready = 0;
	while (! $pidgin_is_ready ){
		($stdout, $stderr, $exit) = $sshConn->cmd("ls /home/$username/.purple/status.xml");
		$pidgin_is_ready = ($exit == 0);
		sleep(10);
	}

	#($stdout, $stderr, $exit) = $sshConn->cmd("kill -9 `ps -C pidgin -o pid= -o ruser= | grep $username | sed \"s/ $username//\"`");
	#if ($exit != 0) {fail ("Problem forcing pidgin to shutdown $stdout $stderr")};

	($stdout1, $stderr1, $exit1) = $sshConn->cmd("kill -9 `ps -C pidgin -o pid= -o ruser= | grep $username | sed \"s/ $username//\"`");
	if ($exit1 !=0) {
		mylog("No pidgin process found based of username search, $stdout1, $stderr1");
		my $uid = $sshConn->cmd("id -u $username");
		($stdout2, $stderr2, $exit2) = $sshConn->cmd("kill -9 `ps -C pidgin -o pid= -o ruser= | grep $uid | sed \"s/ $uid//\"`");
		if ($exit2 != 0) {fail ("Problem forcing pidgin to shutdown $stdout2 $stderr2")};
	}

	$xpath = XML::XPath->new(filename => "accounts.xml");
	$xpath->setNodeText('/account/account/name', "$username\@$xmpp_host/Home");
	$xpath->setNodeText('/account/account/settings[count(@*)=0]/setting[@name=\'connect_server\']', "$xmpp_host");

	($stdout, $stderr, $exit) = $sshConn->cmd("cat > /home/$username/.purple/accounts.xml", $xpath->find('/')->get_node(1)->toString());

	#Change the x,y coordinates of the pidgin window so that it does not cover the Start Here link.
	($stdout, $stderr, $exit) = $sshConn->cmd("sed -i \"s|^\t\t\t<pref name='x' type='int' value=.*|\t\t\t<pref name='x' type='int' value='150'/>|\" /home/$username/.purple/prefs.xml");

	#Add pidgin to the autostart directory. Make that directory if we need to
	($stdout, $stderr, $exit) = $sshConn->cmd("mkdir -p /home/$username/.config/autostart");
	open PIDGIN, "<pidgin.desktop";
	undef $/;
	my $pidgin = <PIDGIN>;
	close PIDGIN;
	$/ = "\n";
	($stdout, $stderr, $exit) = $sshConn->cmd("cat > /home/$username/.config/autostart/pidgin.desktop", $pidgin);
	if ($exit != 0) {fail ("Problem writing out pidgin autostart file $stdout $stderr")};

	#Run the LDAP user plugin to register this new user with the Openfire server
	($stdout, $stderr, $exit) = $sshConn->cmd("wget http://$xmpp_host:9090/plugins/ldapUserAdd/ldapuseradd?username=$username\@xmpp -O /tmp/$username.xmppres");
	if ($exit != 0) {fail ("Problem activating plugin to register new Openfire account $stdout $stderr http://$xmpp_host:9090/plugins/ldapUserAdd/ldapuseradd?username=$username\@xmpp -O /dev/null")};
	($stdout, $stderr, $exit) = $sshConn->cmd("grep \"Success!\" /tmp/$username.xmppres");
	$sshConn->cmd("rm /tmp/$username.xmppres");
	if ($exit != 0) {fail ("Plugin to activate new XMPP account failed to function correctly")};
}

sub configureFunambol{
	#No need to setup Funambol without smartphone capability
	if (! &has_capability("Smartphone")){
		mylog("Skipping configureFunambol");
		return;
	}
	mylog("Starting to setup Funambol account");
	mylog("Commandline is ssh eseriman\@metis.$network_name 'sudo /var/lib/eseriman/bin/addFunambolUser.sh \"$username\" \"$firstname\" \"$lastname\" \"********\"'");
	my $funambol_result = ssh( "metis.$network_name",
				   "sudo /var/lib/eseriman/bin/addFunambolUser.sh '$username' '$firstname' '$lastname' '$password'",
				   "eseriman");
	mylog("Funambol account setup output was -\n$funambol_result");
}

sub configureGnomePanel{
        my $hostdest = "/home/$username/.gnome_panel.xml";
	$scpe->scp('/home/c3/bin/gnome_panel.xml', $hostdest);
	mylog("Copied gnome_panel.xml file on target host");
	
	($stdout, $stderr, $exit) = $sshConn->cmd("mkdir -p /home/$username/.gnome2/panel2.d/default/launchers");
	$hostdest = "/home/$username/.gnome2/panel2.d/default/launchers";

	# Personal Wiki
	mylog("About to run sed command: sed -e \"s|\\[-USERNAME-\\]|$username|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|\"");
        `cat /home/c3/bin/personal-wiki.desktop.template | sed -e "s|\\[-USERNAME-\\]|$username|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|" > /home/c3/bin/personal-wiki.desktop`;
	`chmod a+x /home/c3/bin/personal-wiki.desktop`;
	$scpe->scp('/home/c3/bin/personal-wiki.desktop', $hostdest);
	mylog("Copied personal-wiki.desktop under /home/$username/.gnome2/panel2.d/default/launchers on target host");
	`rm /home/c3/bin/personal-wiki.desktop`;

	# Shared Folder
	$hostdest = "/home/$username/.gnome2/panel2.d/default/launchers";
	$scpe->scp('/home/c3/bin/shared.desktop', $hostdest);
	mylog("Copied shared.desktop under /home/$username/.gnome2/panel2.d/default/launchers on target host");	

	# Load the gnome panel configuration using gconftool-2
	($stdout, $stderr, $exit) = $sshConn->cmd("gconftool-2 --load /home/$username/.gnome_panel.xml");

}

sub configureSyncthing{
	#Don't run if users doesn't have desktop with syncthing
	if (! (&has_capability("Syncthing") && &has_capability("Desktop"))){
		mylog("Skipping configureSyncthing");
		return;
	}
	mylog("About to run syncthing");

	my $run_process = "syncthing";
	`./run_process.pl "$username" "$password" "$target_host" "$run_process" >&2 &`;
	#Again, loop until we see a file we need then kill Syncthing
	my $syncthing_is_ready = 0;
	my $syncthing_config="/home/$username/.config/syncthing/config.xml";
	while (! $syncthing_is_ready ){
		($stdout, $stderr, $exit) = $sshConn->cmd("ls $syncthing_config");
		$syncthing_is_ready = ($exit == 0);
		sleep(10);
	}

	($stdout1, $stderr1, $exit1) = $sshConn->cmd("kill -9 `ps -C syncthing -o pid= -o ruser= | grep $username | sed \"s/ $username//\"`");
	if ($exit1 !=0) {
		mylog("No syncthing process found based of username search, $stdout1, $stderr1");
		my $uid = $sshConn->cmd("id -u $username");
		($stdout2, $stderr2, $exit2) = $sshConn->cmd("kill -9 `ps -C syncthing -o pid= -o ruser= | grep $uid | sed \"s/ $uid//\"`");
		if ($exit2 != 0) {fail ("Problem forcing syncthing to shutdown $stdout2 $stderr2")};
	}

	# Add username and password for authentication
	($stdout, $stderr, $exit) = $sshConn->cmd("sed -i '/<\\/gui>/i\\        <user>$username</user>\\n        <password>$password</password>' $syncthing_config");
	# Change device name from chaos to Desktop
	($stdout, $stderr, $exit) = $sshConn->cmd("sed -i '/<device id=.* name=\"chaos\" .*>/s|name=\"chaos\"|name=\"Desktop\"|g' $syncthing_config");
	# Adjust a few parameters - Change GUI and Sync port to default so that when user logs in, new port is determined and changeFirewallPortConfig request is sent out.
	($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e 's|<address>0.0.0.0:.*<\\/address>|<address>0.0.0.0:8080<\\/address>|g;s|<listenAddress>0.0.0.0:.*<\\/listenAddress>|<listenAddress>0.0.0.0:22000<\\/listenAddress>|g;s|<startBrowser>true<\\/startBrowser>|<startBrowser>false<\\/startBrowser>|g;s|<upnpEnabled>true<\\/upnpEnabled>|<upnpEnabled>false<\\/upnpEnabled>|g;s|<autoUpgradeIntervalH>12<\\/autoUpgradeIntervalH>|<autoUpgradeIntervalH>0<\\/autoUpgradeIntervalH>|g' $syncthing_config");

	#Add syncthing to the autostart directory. Make that directory if we need to
	($stdout, $stderr, $exit) = $sshConn->cmd("mkdir -p /home/$username/.config/autostart");
	open SYNCTHING, "<syncthing.desktop";
	undef $/;
	my $syncthing = <SYNCTHING>;
	close SYNCTHING;
	$/ = "\n";
	($stdout, $stderr, $exit) = $sshConn->cmd("cat > /home/$username/.config/autostart/syncthing.desktop", $syncthing);
	if ($exit != 0) {fail ("Problem writing out syncthing autostart file $stdout $stderr")};
}

sub userInit{
	#Run the client side user init script
	mylog("userInit start");
	($stdout, $stderr, $exit) = $sshConn->cmd("export DISPLAY=0:$display; if [ -x /usr/local/share/eseri/eseriUserInit ] ; then /usr/local/share/eseri/eseriUserInit \"$password\"; fi");
	mylog("userInit end");
	if ($exit != 0) {fail ("Problem running the eseriUserInit script, $stdout, $stderr")};
}

sub configureWiki{
    if (! &has_capability("Wiki")){
	mylog("Skipping configureWiki");
	return;
    }
    
    # Substitute Domain and Username into script template
    mylog("About to run sed command: sed -e \"s|\\[-USERNAME-\\]|$username|;s|\\[-NETWORK_NAME-\\]|$network_name|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|\" edit_user_wiki.js.template");
    `cat /home/c3/bin/edit_user_wiki.js.template | sed -e "s|\\[-USERNAME-\\]|$username|;s|\\[-NETWORK_NAME-\\]|$network_name|;s|\\[-ALIAS_DOMAIN-\\]|$alias_domain|" > /home/c3/bin/edit_user_wiki.js`;
    mylog("edit_user_wiki.js file is generated, and ready to be copied");
    # Copy script to chaos, run it and remove it
    $scpe->scp("/home/c3/bin/edit_user_wiki.js", "/home/$username");
    for (my $i=0; $i<3; $i++){
	($stdout, $stderr, $exit) = $sshConn->cmd("export DISPLAY=0:$display; mozmill -t /home/$username/edit_user_wiki.js -P \$((30000+\$(id -u)))");
	mylog("Result of trying to run was -\n$stdout");
	if ($exit != 0){
	    `echo 'From: <$FROMEMAILADDRESS>\nSubject: Error in C3 creation - personalize_desktop.pl\nTo: <$ERROREMAILADDRESS>\n\nMozmill edit_user_wiki.js test #$i failed for $username at cloud $network_name.\n$stdout\n' | ssmtp -t`;
	    mylog("Error edit_user_wiki.js - $stderr");
	}
	else{
	    last;
	}
    }
    $sshConn->cmd("rm /home/$username/edit_user_wiki.js");
}

sub configureVtiger{
	if (! &has_capability("Vtiger")){
		mylog("Skipping configureVtiger");
		return;
	}
	#Now set the IMAP settings for Vtiger mail
	my $vtigerpw = `perl -MMIME::Base64 vtiger_obfuscate.pl "$password"`;
	mylog("Obfuscated password for Vtiger is $vtigerpw");
	my $res = ssh( "poseidon.$network_name",
			  "sudo /var/lib/eseriman/bin/createVtigerIMAPPassword.sh '$username' '$email_prefix' '$vtigerpw' '$firstname' '$lastname' '$cloud_domain' 'imap.$alias_domain' '$mail_login'",
			  "eseriman");
	mylog("Result of trying to run was -\n$res");
}

sub configureSQLLedger{
	if (! &has_capability("SQLLedger")){
		mylog("Skipping configureSQLLedger");
		return;
	}
	#Create user in SQL-Ledger
	my $res = ssh( "poseidon.$network_name",
		       "sudo /var/lib/eseriman/bin/sql-ledger-add-user '$username' '$password'",
		       "eseriman");
	mylog("Result too long, so commented out.\n");
	#mylog("Result of trying to run was -\n$res");
}

sub configureRedmine{
	if (! &has_capability("Redmine")){
                mylog("Skipping configureRedmine");
                return;
        }
	my $res = ssh( "trident.$network_name",
		       "sudo /var/lib/eseriman/bin/createRedmineUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain'",
		       "eseriman");
        mylog("Result of trying to run was -\n$res");
		
}

sub configurePHPScheduleIt{
        if (! &has_capability("PHPScheduleIt")){
                mylog("Skipping configurePHPScheduleIt");
                return;
        }
        my $res = ssh( "trident.$network_name",
		       "sudo /var/lib/eseriman/bin/createPHPScheduleItUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain'",
		       "eseriman");

        mylog("Result of trying to run was -\n$res");

}

sub configureDrupal{
        if (! &has_capability("Drupal")){
                mylog("Skipping configureDrupal");
                return;
        }
        my $res = ssh( "trident.$network_name",
                       "sudo /var/lib/eseriman/bin/createDrupalUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain' 'server'",
                       "eseriman");

        mylog("Result of trying to run was -\n$res");
}

sub configureChurchInfo{
        if (! &has_capability("ChurchInfo")){
	    mylog("Skipping configureChurchInfo");
	    return;
	}
    
	my $md5_user_password = md5_hex($password);
        my $res = ssh( "trident.$network_name",
                       "sudo /var/lib/eseriman/bin/createChurchInfoUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain' '$md5_user_password'",
                       "eseriman");

	mylog("Result of trying to run was -\n$res");
}

sub configureMoodle{
        if (! &has_capability("Moodle")){
                mylog("Skipping configureMoodle");
                return;
        }
        my $res = ssh( "trident.$network_name",
                       "sudo /var/lib/eseriman/bin/createMoodleUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain' 'server'",
                       "eseriman");

        mylog("Result of trying to run was -\n$res");
}

sub configureOpenERP{
        if (! &has_capability("OpenERP")){
                mylog("Skipping configureOpenERP");
                return;
        }
        my $res = ssh( "trident.$network_name",
                       "sudo /var/lib/eseriman/bin/createOpenERPUser.sh '$username' '$email_prefix' '$firstname' '$lastname' '$cloud_domain' '$password' 'server'",
                       "eseriman");

        mylog("Result of trying to run was -\n$res");
}

sub has_capability{
	my $target = shift;
	#Determine if capability is installed
	foreach my $cap (@capabilities){
                if ($target eq $cap){
                        return 1;
                }
        }
        return 0;
}

sub has_enabled_capability{
        my $target = shift;
	#Determine if capability is enabled
	foreach my $cap_e (@capabilities_enabled){
        	if ($target eq $cap_e){
		        return 1;
		}
	}
	return 0;
}

sub disableScreenSaver{
	#Turn off the flipping screensaver
	($stdout, $stderr, $exit) = $sshConn->cmd("gconftool-2 -t boolean -s /apps/gnome-screensaver/idle_activation_enabled false");
	if ($exit != 0) {fail ("Problem deactivating screensaver, $stdout, $stderr")};
}

sub runNXFirstTime{
	`nxclient --session $username.chaos &`;
	mylog("Started NX client");
	sleep(10);
	`pidof nxssh 2>&1 > /dev/null`;
	unless($? == 0) {fail ("NX session did not appear to stay alive")};
	mylog("NX client started successfully");

	$nxrun="TRUE";
	#Challenge number one: Configuring Evolution!

	$sshConn = Net::SSH::Perl->new("$target_host") || fail("Couldn't get SSH tunnel to target host");
	$sshConn->login("$username", "$password") || fail("Couldn't use SSH to log in to target host");

	($stdout, $stderr, $exit) = $sshConn->cmd("ls -rt /home/$username/.nx | grep \"^C-\" | tail -n 1");
	mylog( "Finding most recent session, result: $stdout");
	if ($stdout =~ m/^C-[^-]+-([0-9]*)-.*/){
		$display=$1;
	}
	if ($display eq '') {fail("Failed to determine target host DISPLAY setting, $stdout, $stderr")};
	chomp($display);
	mylog( "Most recent session is using display: $display");

}
sub getUserID{
	($stdout, $stderr, $exit) = $sshConn->cmd("id -u");
	chomp($stdout);
	$userid = $stdout;
}

sub fail{
	my $output = shift;
	print STDERR "$output\n" if $verbose;
	$db_log->bind_param(1, $output);
	my $res = $db_log->execute();
	if ($dbuserid){
		&setUserFailed();
	}
	openlog("Desktop Customization", "pid,perror", "daemon");
	syslog("info", "$output");
	closelog;	
	die "$output";
}

sub mylog{
	my $output = shift;
	print STDERR "$output\n" if $verbose;
	$db_log->bind_param(1, $output);
	my $res = $db_log->execute();
	if (! $res){
		fail("Could not write to DB log: $DBI::errstr");
	}
}

sub makeDBConnection{
	$db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS") || fail "Failed to establish database link";
	$db_log = $db_conn->prepare("INSERT INTO c5.c3_log (log) VALUES (?)") || fail "Failed to establish database statement handle";
}

sub makeSSHConnection{
	$sshConn = Net::SSH::Perl->new("$target_host") || fail("Couldn't get SSH tunnel to target host");
	$sshConn->login("$username", "$password") || fail("Couldn't use SSH to log in to target host");
}

sub setUserActive{
	$db_st = $db_conn->prepare("UPDATE network.eseri_user SET status = 'ACTIVE' WHERE id = ?");
	$db_st->bind_param(1, $dbuserid);
	$db_st->execute();
	$db_st->finish;
}

sub setUserFailed{
	$db_st = $db_conn->prepare("UPDATE network.eseri_user SET status = 'PROCESSING_FAILED' WHERE id = ?");
	$db_st->bind_param(1, $dbuserid);
	$db_st->execute();
	$db_st->finish;
}
#######################################
#Termination and cleanup block
######################################

END{
	#All I really care about at this point is making sure the NX client session is terminated if it's running
	if (defined $nxrun && $nxrun eq "TRUE"){
		my $nxsessions = `nxkill --list`;
		print $nxsessions;
		my @sessions = split(/\n/, $nxsessions);
		foreach my $session (@sessions) {
			#Header line, ignore ...
			if ($session =~ m/^Type.*/){
				next;
			}
			#Spacer line, ignore ...
			if ($session =~ m/^-.*/){
				next;
			}
			#This has to be the session we want - nuke it
			my @session_info = split(/\s+/, $session);
			my $session_id = $session_info[1];
			my $session_dir = $ENV{'HOME'}."/.nx/".$session_info[0]."-".$session_info[3]."-".$session_info[2]."-".$session_info[1];
			mylog ("Trying to kill NX Session: $session_id");
			`nxkill --kill --id $session_id`;
			mylog ("Trying to remove leftover session directory: $session_dir");
			(-d "$session_dir") ? (`rm -r $session_dir`) : (mylog ("Session directory already removed cleanly"));
			mylog ("Trying to issue remote kill command");
			ssh( $target_host, "sudo ./bin/eseriKillNXSession '$username'", "eseriman");
		}
		#Now, clean up any leftovers
		if (defined $sshConn){
			($stdout, $stderr, $exit) = $sshConn->cmd("find /tmp -maxdepth 1 -user $username -exec rm -r {} \\;");
			(defined $exit && $exit != 0) ? (mylog("Error cleaning up /tmp directories, $stderr")) : (mylog("Cleaned up /tmp directories"));
			($stdout, $stderr, $exit) = $sshConn->cmd("rm /home/$username/some_tmp_file /home/$username/cal_disp_result /home/$username/core");
			($stdout, $stderr, $exit) = $sshConn->cmd("rm /home/$username/evolution_addressbook.tmp /home/$username/evolution_after.tmp");
			($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e 's/true/false/' /home/$username/.gconf/apps/evolution/calendar/notify/%gconf.xml");
			undef $sshConn;
			$? = 0;
		}
		$? = 0;
	}
	$db_log->finish;
	$db_conn->disconnect;
	$? = 0;
	exit 0;
}


__END__
