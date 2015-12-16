#!/usr/bin/perl -w
#
# system_anchor_config.pl - v1.1
#
# This script handles the C3 requests for changing the system anchor domain.
# The logs should be written to /var/log/c4/systemanchor_config.log
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

use strict;

use MIME::Lite::TT::HTML;
use Config::General;
use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use XML::LibXML;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use File::Slurp;

use common qw(:systemanchor_config);

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
my $new_system_anchor_domain;
my $new_system_anchor_ip;
my $new_system_anchor_netmask;

GetOptions('network_name=s' => \$network_name, 'new_system_anchor_domain=s' => \$new_system_anchor_domain, 'new_system_anchor_ip=s' => \$new_system_anchor_ip, 'new_system_anchor_netmask=s' => \$new_system_anchor_netmask) or die ("Options set incorrectly");

my %capabilities;
my @capabilities;
my @containers = ("chaos", "trident", "gaia", "erato", "cronus", "poseidon", "hera", "hades", "aphrodite", "athena", "apollo", "hermes", "server", "zeus"); # Order is important.
my @container_veids;
my %userlist;
my %superuser_details;
my $deployment_name = "systemanchor_config-$network_name-".get_random_string(8);
my $deployment_file = "/tmp/$deployment_name" ;
my $tar_file = "/tmp/$deployment_name.tar.gz";
my $script_folder = "$c4_root/storage/SystemAnchor_Config/";
my @deploy_nodes = ("old_system_anchor_domain", "old_system_anchor_ip", "old_system_anchor_netmask", "new_system_anchor_domain", "new_system_anchor_ip", "new_system_anchor_netmask", "manager_username", "manager_password");
my %password_nodes = (
    MASTER_PASSWORD_KRB5 => {
	athena => 'Krb5Master',	
    },
    ADMIN_PASSWORD_KRB5 => {
	athena => 'Krb5Admin',	
    },
    DB_PASSWORD_MYSQL => {
	mysql => 'root',	
    },
    DOVECOT_PASSWORD_PROXY => {
	dovecot => 'proxy',	
    },
    KEYSTORE_PASSWORD_NUXEO_SYSTEM => {
	cronus => 'Java Keystore',	
    },
    KEYSTORE_PASSWORD_XMPP_SYSTEM => {
	erato => 'Java Keystore',	
    },
    KEYSTORE_PASSWORD_XMPP => {
	erato => 'XMPP Keystore',	
    },
    );

my $old_system_anchor_domain = $system_anchor_domain;
my $old_system_anchor_ip;
my $old_system_anchor_netmask;
my $new_short_domain = `DOMAIN=$new_system_anchor_domain; echo \${DOMAIN%%.*}`;
chomp($new_short_domain);
my $new_short_name = uc($new_short_domain);

my $root_ca_password = determine_entity_password($db_conn, $network_name, '', 'Root CA Passphrase');
my $c4_cert_folder = "$c4_root/certs/$new_short_domain";
my @ca_cert_files = ("caconfig.txt", "cacert.pem", "private/cakey.pem", "dsaparam.pem");
my @cert_hosts = ('ssl','aphrodite','imap','smtp','dkim','xmpp','xmpp');
my @cert_containers = ('hermes','aphrodite','hera','hera','hera','erato','erato');
my @cert_types = ('RSA','RSA','RSA','RSA','RSA','RSA','DSA');

my @keytab_hosts = ('apollo', 'aphrodite', 'aphrodite', 'hera', 'hera', 'poseidon', 'erato', 'gaia', 'trident', 'chaos', 'chaos');
my @keytab_src_files = ('apache2', 'host', 'slapd', 'host', 'dovecot', 'apache2', 'openfire', 'apache2', 'apache2', 'host', 'eseriman_admin');
my @keytab_dst_files = ('/etc/apache2/apache2', '/etc/krb5', '/etc/ldap/aphrodite.slapd', '/etc/krb5', '/etc/dovecot/hera.dovecot', '/etc/apache2/apache2', '/etc/openfire/xmpp', '/etc/apache2/apache2', '/etc/apache2/apache2', '/etc/krb5', '/var/lib/eseriman/keytabs/eseriman-admin');

my %ssh_key_users = (
    c3 => '',
    c4 => '',
    c5 => '',
    backup => '',
    );

my $server_ip = `host server.$old_system_anchor_domain | grep 'has address' | awk '{print \$4}'`;
chomp($server_ip);

deploy_main();

sub determine_inferred_value{
    my ($arg) = @_;
    if ($arg eq 'old_system_anchor_domain'){
	return $old_system_anchor_domain;
    }
    elsif ($arg eq 'old_system_anchor_ip'){
	return $old_system_anchor_ip;
    }
    elsif ($arg eq 'old_system_anchor_netmask'){
	return $old_system_anchor_netmask;
    }
    elsif ($arg eq 'new_system_anchor_domain'){
	return $new_system_anchor_domain;
    }
    elsif ($arg eq 'new_system_anchor_ip'){
	return $new_system_anchor_ip;
    }
    elsif ($arg eq 'new_system_anchor_netmask'){
	return $new_system_anchor_netmask;
    }
    elsif ($arg eq 'manager_username'){
	return $superuser_details{'username'};		
    }
    elsif ($arg eq 'manager_password'){
	return $superuser_details{'password'};		
    }
}

sub generate_deployment{
    mylog(" -- Creating deployment file");
    `rm -f $deployment_file`;
    determine_capabilities($db_conn, $network_name, 'cloud', \%capabilities, \@capabilities);
    deploy_capabilities($deployment_file, 'CAPABILITY', \%capabilities);

    foreach my $deploy_node (@deploy_nodes){
	my $arg_value = determine_inferred_value( $deploy_node );
	deploy_parameters($deployment_file, $deploy_node, $arg_value);
    }

    deploy_passwords($db_conn, $network_name, $deployment_file, \%password_nodes);
}

sub generate_copy_ssh_keys(){
    mylog(" -- Generating ssh keys");
    for (my $i=0; $i<scalar keys %ssh_key_users; $i++){
	my $user = (keys %ssh_key_users)[$i];
	my $host = (keys %ssh_key_users)[$i];
	my $ssh_key;
	my $ssh_key_folder;
	# Creating C4 key in /tmp, and will copy over to the ssh folder in it's home directory later (after run_script method).
	($host eq 'c4') ? ($ssh_key_folder = "/tmp") : ($ssh_key_folder = ".ssh");
	ssh("$host.$system_anchor_domain", "rm -f $ssh_key_folder/id_rsa*", "$user");
	ssh("$host.$system_anchor_domain", "cd $ssh_key_folder; ssh-keygen -f id_rsa -N '' -t rsa -q", "$user");
	$ssh_key = ssh("$host.$system_anchor_domain", "cat $ssh_key_folder/id_rsa.pub", "$user");	
	chomp($ssh_key);	    
	$ssh_key_users{$user} = $ssh_key;	
    }

    my $ssh_auth_key_files;
    for (my $i=0; $i<scalar @containers; $i++){
	$ssh_auth_key_files="/root/.ssh/authorized_keys ";
	if ($containers[$i] eq 'poseidon' || $containers[$i] eq 'trident' || $containers[$i] eq 'chaos'){
	    $ssh_auth_key_files.="/var/lib/eseriman/.ssh/authorized_keys ";
	}
	if ($containers[$i] eq 'apollo'){
	    $ssh_auth_key_files.="/home/c3/.ssh/authorized_keys ";
	    $ssh_auth_key_files.="/home/c4/.ssh/authorized_keys ";
	    $ssh_auth_key_files.="/home/c5/.ssh/authorized_keys ";
	    $ssh_auth_key_files.="/var/lib/backup/.ssh/authorized_keys ";
	    $ssh_auth_key_files.="/home/c4/storage/ssh/authorized_keys ";
	    $ssh_auth_key_files.="/home/c4/storage/ssh/authorized_keys.c3 ";
	    $ssh_auth_key_files.="/home/c4/storage/ssh/authorized_keys.c5 ";
	}

	ssh("$containers[$i].$system_anchor_domain","sed -i -e '/c3\@apollo/s|.*|$ssh_key_users{c3}|g' -e '/c4\@apollo/s|.*|$ssh_key_users{c4}|g' -e '/c5\@apollo/s|.*|$ssh_key_users{c5}|g' -e '/backup\@apollo/s|.*|$ssh_key_users{backup}|g' $ssh_auth_key_files");
    }

    #Copying C4 ssh key created at /tmp into its home folder.
    `cp /tmp/id_rsa* /home/c4/.ssh/`;
}

sub generate_copy_certs{
    mylog(" -- Deleting old certificates from database");
    my $delete_vault_certificate_files = $db_conn->prepare("DELETE FROM vault.certificate_files WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $delete_vault_certificate_files->bind_param(1, $network_name);
    $delete_vault_certificate_files->execute()
	or die "Couldn't execute statement: " . $delete_vault_certificate_files->errstr;

    #Remember where we were
    my $cwd = &Cwd::cwd();
    `rm -rf $c4_cert_folder`;
    `mkdir -p $c4_cert_folder`;
    chdir("$c4_cert_folder");
    `mkdir $c4_cert_folder/signedcerts`;
    `mkdir $c4_cert_folder/private`;
    `echo "01" > $c4_cert_folder/serial`;
    `touch $c4_cert_folder/index.txt`;
    `echo "unique_subject = no" > $c4_cert_folder/index.txt.attr`;

    mylog(" -- Generating CA certificate");
    `sed -e "s|\\\[-SYSTEM_ANCHOR_DOMAIN-\\\]|$new_system_anchor_domain|g" -e "s|\\\[-SHORT_DOMAIN-\\\]|$new_short_domain|g" -e "s|\\\[-SHORT_NAME-\\\]|$new_short_name|g" $script_folder/template/transient/openssl.cnf > $c4_cert_folder/caconfig.txt`;
    `openssl req -x509 -newkey rsa:2048 -out cacert.pem -outform PEM -days 1825 -passout "pass:$root_ca_password" -config ./caconfig.txt 2>&1 > /dev/null`;
    `openssl dsaparam -out dsaparam.pem 1024 2>&1 > /dev/null`;

    for (my $i=0; $i<scalar @ca_cert_files; $i++){
	my $file_contents = read_file("$c4_cert_folder/$ca_cert_files[$i]");
	my $ca_file_ins = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES ((SELECT id FROM network.organization WHERE network_name = ?), ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$ca_file_ins->bind_param(1, $network_name);
	$ca_file_ins->bind_param(2, "$c4_cert_folder/$ca_cert_files[$i]");
	$ca_file_ins->bind_param(3, $file_contents);
	$ca_file_ins->execute()
	    or die "Couldn't execute statement: " . $ca_file_ins->errstr;
	$ca_file_ins->finish;
    }

    for (my $i=0; $i<scalar @containers; $i++){
	if ($containers[$i] ne 'server'){
	    ssh("$containers[$i].$old_system_anchor_domain", "mkdir -p /usr/share/ca-certificates/$new_system_anchor_domain/");
	    scp("$c4_cert_folder/cacert.pem", "root\@$containers[$i].$old_system_anchor_domain:/usr/share/ca-certificates/$new_system_anchor_domain/CA.crt");
	}
    }
    
    for (my $i=0; $i<scalar @cert_hosts; $i++){
	my $host = "$cert_hosts[$i].$new_system_anchor_domain";
	mylog(" -- Generating certificate for $host");
	my $cnffilename = "${host}.cnf";
	`sed -e "s|\\\[-SYSTEM_ANCHOR_DOMAIN-\\\]|$new_system_anchor_domain|g" -e "s|\\\[-SHORT_DOMAIN-\\\]|$new_short_domain|g" -e "s|\\\[-HOST-\\\]|$host|g" $script_folder/template/transient/host.cnf > $c4_cert_folder/$cnffilename`;

	my $reqfilename = "${host}_req.pem";
	my $keyfilename = "${host}_key.pem";
	my $crtfilename = "${host}_crt.pem";
	my $destfilename = "${host}.pem";
	my $keyparams = 'rsa:1024';

	if ($cert_types[$i] eq "DSA"){
	    $reqfilename = "${host}_dsa_req.pem";
	    $keyfilename = "${host}_dsa_key.pem";
	    $crtfilename = "${host}_dsa_crt.pem";
	    $destfilename = "${host}_dsa.pem";
	    $keyparams = 'dsa:dsaparam.pem';
	}

	`openssl req -newkey $keyparams -nodes -keyout $keyfilename -keyform PEM -out $reqfilename -outform PEM -config ./$cnffilename`;
	`openssl ca -batch -in $reqfilename -out $crtfilename -config ./caconfig.txt -passin "pass:$root_ca_password"`;	
	unlink("$reqfilename");
	my $key_contents = read_file($keyfilename);
	my $crt_contents = read_file($crtfilename);
	my $key_ins = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES ((SELECT id FROM network.organization WHERE network_name = ?), ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$key_ins->bind_param(1, $network_name);
	$key_ins->bind_param(2, "$c4_cert_folder/$keyfilename");
	$key_ins->bind_param(3, $key_contents);
	$key_ins->execute()
	    or die "Couldn't execute statement: " . $key_ins->errstr;
	$key_ins->finish;
	
	my $crt_ins = $db_conn->prepare("INSERT INTO vault.certificate_files (organization, file, contents) VALUES ((SELECT id FROM network.organization WHERE network_name = ?), ?, ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$crt_ins->bind_param(1, $network_name);
	$crt_ins->bind_param(2, "$c4_cert_folder/$crtfilename");
	$crt_ins->bind_param(3, $crt_contents);
	$crt_ins->execute()
	    or die "Couldn't execute statement: " . $crt_ins->errstr;
	$crt_ins->finish;

	# Using old system anchor domain since we haven't yet run the deploy scripts.
	scp("$keyfilename", "root\@$cert_containers[$i].$old_system_anchor_domain:/etc/ssl/private/$destfilename");
	scp("$crtfilename", "root\@$cert_containers[$i].$old_system_anchor_domain:/etc/ssl/certs/$destfilename");
 	ssh("$cert_containers[$i].$old_system_anchor_domain", "chmod 640 /etc/ssl/private/$destfilename; chown root:ssl-cert /etc/ssl/private/$destfilename; chmod 644 /etc/ssl/certs/$destfilename");

	# Change DKIM key record in zone file.
	if ($cert_hosts[$i] eq 'dkim'){
	    my $domain_key = `openssl rsa -in $keyfilename -pubout -outform pem 2>/dev/null | grep -v "^-" | tr -d '\n'`;
	    ssh("zeus.$old_system_anchor_domain", "sed -i 's|\\\"k=rsa; p=.*\\\"|\\\"k=rsa; p=$domain_key\\\"|' /etc/bind/db.$old_system_anchor_domain.external");
	}
    }

    #Go back to working dir.
    chdir($cwd);
}

sub generate_copy_nx_license{
    mylog(" -- Performing C5 to renew NX license specifically for System Manager Cloud.");
    ssh("c5.$system_anchor_domain", "sudo /home/c5/bin/c5.sh >&2");
}

sub copy_keytabs{
    mylog(" -- Transferring keytabs from Athena Kerberos to the respective containers");
    `mkdir -p $c4_cert_folder/keytabs`;
    scp("root\@athena.$old_system_anchor_domain:/tmp/*.keytab", "$c4_cert_folder/keytabs");
    for (my $i=0; $i<scalar @keytab_hosts; $i++){
	my $host = "$keytab_hosts[$i].$old_system_anchor_domain";
	my $keytab_src="$c4_cert_folder/keytabs/$keytab_hosts[$i].$keytab_src_files[$i].keytab";
	my $keytab_dst="$keytab_dst_files[$i].keytab";
	scp("$keytab_src", "root\@$host:/$keytab_dst");
    }
}

sub configure_database{
    mylog(" -- Configuring Database");
    # Update status here, since after cloud reboot the C3 thread won't finish.
    my $change_cloud_config_status = $db_conn->prepare("UPDATE network.organization_config_status SET dc = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $change_cloud_config_status->bind_param(1, 'ACTIVE');
    $change_cloud_config_status->bind_param(2, $network_name);
    $change_cloud_config_status->execute()
	or die "Couldn't execute statement: " . $change_cloud_config_status->errstr;
    $change_cloud_config_status->finish;

    my $update_address_pool = $db_conn->prepare("UPDATE network.address_pool SET address = ?, netmask = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $update_address_pool->bind_param(1, $new_system_anchor_ip);
    $update_address_pool->bind_param(2, $new_system_anchor_netmask);
    $update_address_pool->bind_param(3, $network_name);
    $update_address_pool->execute()
	or die "Couldn't execute statement: " . $update_address_pool->errstr;

    my $update_vault_certificate_details = $db_conn->prepare("UPDATE vault.certificate_details SET email = REPLACE(email, ?, ?), name = ? WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $update_vault_certificate_details->bind_param(1, $old_system_anchor_domain);
    $update_vault_certificate_details->bind_param(2, $new_system_anchor_domain);
    $update_vault_certificate_details->bind_param(3, $new_short_domain);
    $update_vault_certificate_details->bind_param(4, $network_name);
    $update_vault_certificate_details->execute()
	or die "Couldn't execute statement: " . $update_vault_certificate_details->errstr;


    my $update_domain_config = $db_conn->prepare("UPDATE network.domain_config SET email_domain = REPLACE(email_domain, ?, ?), imap_server = REPLACE(imap_server, ?, ?), alias_domain = REPLACE(alias_domain, ?, ?) WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $update_domain_config->bind_param(1, $old_system_anchor_domain);
    $update_domain_config->bind_param(2, $new_system_anchor_domain);
    $update_domain_config->bind_param(3, $old_system_anchor_domain);
    $update_domain_config->bind_param(4, $new_system_anchor_domain);
    $update_domain_config->bind_param(5, $old_system_anchor_domain);
    $update_domain_config->bind_param(6, $new_system_anchor_domain);
    $update_domain_config->bind_param(7, $network_name);
    $update_domain_config->execute()
	or die "Couldn't execute statement: " . $update_domain_config->errstr;

    my $update_network_organization = $db_conn->prepare("UPDATE network.organization SET network_name = REPLACE(network_name, ?, ?), email_domain = REPLACE(email_domain, ?, ?), nxserver = REPLACE(nxserver, ?, ?) WHERE network_name = ?")
	or die "Couldn't prepare statement: " . $db_conn->errstr;
    $update_network_organization->bind_param(1, $old_system_anchor_domain);
    $update_network_organization->bind_param(2, $new_system_anchor_domain);
    $update_network_organization->bind_param(3, $old_system_anchor_domain);
    $update_network_organization->bind_param(4, $new_system_anchor_domain);
    $update_network_organization->bind_param(5, $old_system_anchor_domain);
    $update_network_organization->bind_param(6, $new_system_anchor_domain);
    $update_network_organization->bind_param(7, $network_name);
    $update_network_organization->execute()
	or die "Couldn't execute statement: " . $update_network_organization->errstr;
}

sub cloud_reboot{
    mylog(" -- Performing Cloud Reboot");
    @containers = ("zeus", "hermes", "athena", "aphrodite", "hades", "hera", "poseidon", "cronus", "erato", "gaia", "trident", "chaos", "apollo"); # Order is important.

    # Get container veids for the containers in array above.
    for (my $i=0; $i<scalar @containers; $i++){
	my $get_container_veid = $db_conn->prepare("SELECT veid FROM network.server WHERE hostname = ? AND organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	    or die "Couldn't prepare statement: " . $db_conn->errstr;
	$get_container_veid->bind_param(1, $containers[$i]);
	$get_container_veid->bind_param(2, $new_system_anchor_domain);
	$get_container_veid->execute()
	    or die "Couldn't execute statement: " . $get_container_veid->errstr;
	push(@container_veids, $get_container_veid->fetchrow_array());
	$get_container_veid->finish;
    }
    
    # Do the below using server ip address since once the dns container restarts then server.old_system_anchor_domain won't work.
    ssh("$server_ip", "sed -i 's|$old_system_anchor_domain|$new_system_anchor_domain|g' /var/lib/vz/private/*/etc/resolv.conf");
    for (my $i=0; $i<scalar @container_veids; $i++){
	ssh("$server_ip", "vzctl stop $container_veids[$i] >&2; vzctl start $container_veids[$i] >&2");
    }
}

sub deploy_systemanchor_config{
    mylog(" - Performing System Anchor Config at $network_name - $new_system_anchor_domain, $new_system_anchor_ip, $new_system_anchor_netmask");
    generate_copy_ssh_keys();
    generate_deployment();
    generate_copy_certs();
    generate_copy_nx_license();
    run_script($network_name, $script_folder, $deployment_name, $tar_file, $deployment_file, \@containers);

    # Since we restarted the postgres server on the system manager cloud, connection is lost. So establish a new one.
    $db_conn = DBI->connect("dbi:Pg:dbname=$DBNAME;host=$DBHOST", "$DBUSER", "$DBPASS");

    copy_keytabs();
    configure_database();

    # Last step is to reboot the system manager cloud. Once the script is called, all the containers will be restarted, meaning we won't really know if the reboot was successfull or not.
    cloud_reboot();
}

sub deploy_main{
    get_superuser_details($db_conn, $network_name, \%superuser_details);

    my $get_old_system_anchor_ip_netmask = $db_conn->prepare("SELECT address, inet(netmask) FROM network.address_pool WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)")
	 or die "Couldn't prepare statement: " . $db_conn->errstr;
    $get_old_system_anchor_ip_netmask->bind_param(1, $network_name);
    $get_old_system_anchor_ip_netmask->execute()
        or die "Couldn't execute statement: " . $get_old_system_anchor_ip_netmask->errstr;
    ($old_system_anchor_ip, $old_system_anchor_netmask) = $get_old_system_anchor_ip_netmask->fetchrow_array();
    $get_old_system_anchor_ip_netmask->finish;

    if ($old_system_anchor_domain eq $network_name){
	deploy_systemanchor_config();
    }
    mylog("- Done");
}

exit 0
