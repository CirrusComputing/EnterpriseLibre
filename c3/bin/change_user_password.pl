#!/usr/bin/perl -w
#
# Change User Password v3.2 - Simple helper script to log into remote system and perform auxiliary actions to change a user's password
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

#Imports and declarations
use Getopt::Long;
use Net::SSH::Perl;
use Sys::Syslog;
use Digest::MD5 qw(md5_hex);
use Comms qw(ssh scp ssh_key);
use Mail::IMAPClient;

#Options parsing
my $username = '';
my $email_prefix = '';
my $cloud_domain = '';
my $alias_domain = '';
my $domain_config_version = '';
my $network_name = '';
my $old_password = '';
my $new_password = '';
my $funambol = '';
my $vtiger = '';
my $webhuddle = '';
my $nuxeo = '';
my $churchinfo = '';
my $syncthing = '';

GetOptions('username=s' => \$username, 'email_prefix=s' => \$email_prefix, 'cloud_domain=s' => \$cloud_domain, 'alias_domain=s' => \$alias_domain, 'domain_config_version=s' => \$domain_config_version, 'old_password=s' => \$old_password, 'new_password=s' => \$new_password, 'network_name=s' => \$network_name, 'funambol=s' => \$funambol, 'vtiger=s' => \$vtiger, 'webhuddle=s' => \$webhuddle, 'nuxeo=s' => \$nuxeo, 'churchinfo=s' => \$churchinfo, 'syncthing=s' => \$syncthing) or die ("Options set incorrectly");

my $mail_login = $username;
my $mail_login_escaped = $username;
if($domain_config_version eq '2.12'){
    $mail_login = $email_prefix.'@'.$cloud_domain;
    $mail_login_escaped = $email_prefix.'%40'.$cloud_domain;
}

ssh_key("chaos.$network_name");
my $sshConn = Net::SSH::Perl->new("chaos.$network_name") || die ("Could not start SSH session for target host chaos.$network_name");
$sshConn->login("$username", "$new_password") || die ("Could not log in with username $username");
my $stdout ='';
my $stderr ='';
my $exit ='';

($stdout, $stderr, $exit) = $sshConn->cmd("find /home/$username/.mozilla/firefox/* -maxdepth 0 -type d | grep -v Crash");
chomp($stdout);
my $ff_dir = $stdout;

#################
##### Nuxeo #####
#################
if ($nuxeo eq 'YES'){
    print "Changing Nuxeo passwords\n";
    ($stdout, $stderr, $exit) = $sshConn->cmd("cat $ff_dir/user.js");
    my @ffout = split(/\n/, $stdout);
    foreach my $ffline (@ffout){
	if ($ffline =~ m/^user_pref\("extensions.nxedit.password"/){
	    $ffline = "user_pref(\"extensions.nxedit.password\", \"$new_password\");";
	}
    }
    #$ffline = join("\n", @ffout);
    $sshConn->cmd("echo '' > $ff_dir/user.js");
    foreach $ffline (@ffout){
	($stdout, $stderr, $exit) = $sshConn->cmd("cat >> $ff_dir/user.js", $ffline);
    }
}

###########################
##### WebConferencing #####
###########################
if ($webhuddle eq 'YES'){
    # Use pwencrypt to get the new Webhuddle password
    print "Changing WebConferencing passwords\n";    
    ($stdout, $stderr, $exit) = $sshConn->cmd("/usr/local/share/eseri/pwencrypt -d $ff_dir -i $new_password");
    my @temp_lines = split(/\n/, $stdout);
    $temp_lines[1] =~ s/\r//;
    $temp_lines[2] =~ s/\r//;
    my $new_webhuddle_pw = $temp_lines[1] . $temp_lines[2];
    ($stdout, $stderr, $exit) = $sshConn->cmd("sqlite3 $ff_dir/signons.sqlite \"UPDATE moz_logins SET encryptedPassword = '$new_webhuddle_pw' WHERE hostname LIKE 'https://webmeeting%'\"");
}

($stdout, $stderr, $exit) = $sshConn->cmd("sed -i -e 's|secret=.*|secret=$new_password|' /home/$username/.gnome2/keyrings/default.keyring");

##################
##### Vtiger #####
##################
if ($vtiger eq 'YES'){
    my $vtigerpassword = `perl -MMIME::Base64 vtiger_obfuscate.pl $new_password`;
    ssh( "poseidon.$network_name",
	 "sudo /var/lib/eseriman/bin/changeVtigerIMAPPassword.sh '$username' '$email_prefix' '$vtigerpassword' '$cloud_domain' 'imap.$alias_domain' '$mail_login'",
	 "eseriman");
}

######################
##### Smartphone #####
######################
if ($funambol eq 'YES'){
    ssh( "metis.$network_name",
	 "sudo /var/lib/eseriman/bin/changeFunambolUserPassword.sh '$username' '$new_password'",
	 "eseriman");
}   

######################
##### ChurchInfo #####
######################
if ($churchinfo eq 'YES'){
    my $md5_user_password = md5_hex($new_password);
    ssh( "trident.$network_name",
	 "sudo /var/lib/eseriman/bin/changeChurchInfoUserPassword.sh '$username' '$md5_user_password'",
	 "eseriman");
}

#####################
##### Syncthing #####
#####################
if ($syncthing eq 'YES'){
    print "Changing Syncthing passwords\n";
    # Change password in config file
    ($stdout, $stderr, $exit) = $sshConn->cmd("sed -i 's|<password>.*<\\/password>|<password>$new_password<\\/password>|g' /home/$username/.config/syncthing/config.xml");
}

# Additional config for domain config versions 2.11 and 2.12
if($domain_config_version eq '2.11' or $domain_config_version eq '2.12'){
    print "Configuring user for domain config version $domain_config_version\n";

    my $imap = Mail::IMAPClient->new(
	Server => "imap.$alias_domain",
	User => $mail_login,
	Password => $new_password,
	Timeout => 5
	)       or print "Cannot connect to 'imap.$alias_domain' as $mail_login: $@\n";
    if ($imap){
	# hera.$alias_domain which is the cloud mail server can only be connected using new password because we changed the password in LDAP. 
	# imap.$alias_domain which is the external mail server should be connected using old password in order to check sync.
	print "Doing a dry run for imapsync using old password\n";
	`imapsync --host1 hera.$alias_domain --user1 $username --password1 $new_password --authmech1 PLAIN --host2 imap.$alias_domain --user2 $mail_login -password2 $old_password --authmech2 PLAIN --dry >/dev/null`;
	# If the above failed, it would mean that the sync never went through for this user during domain config. So try now with the new password.
	if ($? != 0){
	    print "Not synced previously, therefore synching user email from internal to external mail servers using new password.\n";
	    `imapsync --host1 hera.$alias_domain --user1 $username --password1 $new_password --authmech1 PLAIN --host2 imap.$alias_domain --user2 $mail_login -password2 $new_password --authmech2 PLAIN >/dev/null`;
	}
	else{
	    print "Synced previously, therefore not running sync again.\n";
	}
    }
    
    # Kill Evolution and Gconf.
    ($stdout, $stderr, $exit) = $sshConn->cmd("ps -C evolution -o pid= -o ruser= | grep $username | awk '{print \$1}'");
    if ($stdout){
	print "Killing evolution process with pid $stdout";
	$sshConn->cmd("kill -9 $stdout");
    }

    # Update passwordless keyrings.
    print "Setting up passwordless evolution keyring\n";
    my $default_keyring_file="/home/$username/.gnome2/keyrings/default.keyring";
    my $line_start;
    my $line_end;
    while(1){
	($stdout, $stderr, $exit) = $sshConn->cmd("grep -i '\\[0\\]' $default_keyring_file | awk '{print}'");
	if ($stdout){
	    ($line_start, $stderr, $exit) = $sshConn->cmd("grep -in '\\[0\\]' $default_keyring_file | sed -e 's|\\:\\[0\\]||'");
	    $line_start = ( split /\n/, $line_start )[0];
	    $line_end = $line_start + 25;
	    print "Removing lines $line_start through $line_end from default.keyring\n";
	    $sshConn->cmd("awk -v m=$line_start -v n=$line_end 'm <= NR && NR <= n {next} {print}' $default_keyring_file > $default_keyring_file.tmp");
	    $sshConn->cmd("mv $default_keyring_file.tmp $default_keyring_file");
	    # Remove trailing newline characters.
	    $sshConn->cmd("printf '\%s\\n' \"\$(cat $default_keyring_file)\" > $default_keyring_file");
	}
	else{
	    last;
	}
    }
    $sshConn->cmd("echo '\n[0]\nitem-type=0\ndisplay-name=imap://$mail_login_escaped\@imap.$alias_domain/\nsecret=$new_password\nmtime=1292615328\nctime=0\n\n[0:attribute0]\nname=application\ntype=string\nvalue=Evolution\n\n[0:attribute1]\nname=protocol\ntype=string\nvalue=imap\n\n[0:attribute2]\nname=server\ntype=string\nvalue=imap.$alias_domain\n\n[0:attribute3]\nname=user\ntype=string\nvalue=$mail_login\n' >> $default_keyring_file");    
}
