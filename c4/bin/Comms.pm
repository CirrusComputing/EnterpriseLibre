# Comms.pm - v1.3
#
# Module to use ssh and scp with error checking and retries
#
# Created by Rick Leir <rleir@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

package Comms;

use strict;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Net::SSH2;

$VERSION     = 1.30;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(ssh scp ssh_key);
%EXPORT_TAGS = ( DEFAULT => [qw(ssh scp ssh_key)],
                 Both    => [qw(ssh scp)]);

# Copy files to/from another server, and retry when we fail.
sub scp{
	my ($src, $dest) = @_;

	# print "SCP == $src, $dest \n";
	my $scp_done = 0;
	my $sleep_time = 2;

	do {
	    foreach ($src, $dest){
		my $full_hostname = `echo "$_" | sed 's|.*@\\(.*\\):.*|\\1|g'`;
		chomp($full_hostname);
		`host '$full_hostname'`;
		if ($? == 0){
		    ssh_key($full_hostname);
		}
	    }

	    `scp -l 50000 -r $src $dest`;
	    if ($? != 0){
		print " -- Return code of scp from $src to $dest is $?\n";
		sleep( $sleep_time);

		# increase the sleep time until it is over an hour
		$sleep_time = $sleep_time * 2;
		if( $sleep_time > 3600) {
		    print "ERROR: scp failed \n";
		    exit(1);
		} 
	    } else {
		$scp_done = 1;
	    }
	} while ($scp_done == 0);
}

# Run commands on another server, and retry when ssh fails to connect.
# Assume that a fail code from ssh means the command did not get run.
sub ssh{
	my ($full_hostname, $cmd, $optional_username) = @_;
#	if (defined $optional_username) { do something }
	$optional_username //= "root"; # default optional value

	print "SSH == $optional_username at $full_hostname, $cmd \n";

	my $ssh_done = 0;
        my $sleep_time = 2;
	my $rvalue = ' ';
        do {
	    ssh_key($full_hostname);

	    $rvalue = `ssh $optional_username\@$full_hostname "$cmd"`;
	    my $rcode = $?;                # actually should be $? >> 8, then 65280 is 255, see perlvar
	    if ($rcode == 0){
		$ssh_done = 1;
	    } else {
		if ($rcode == 65280 ) {  # 255
		    print " -- Return code from ssh is $rcode 1\n";
		    sleep( $sleep_time);

		    # increase the sleep time until it is over an hour                                                                                             
		    $sleep_time = $sleep_time * 2;
		    if( $sleep_time > 3600) {
			print "ERROR: ssh to $full_hostname failed \n";
			exit(1);
		    }
		} else {
		    print " -- Return code from ssh is $rcode 1\n";
                    exit(1);
		}
	    }
	} while ($ssh_done == 0);

	return $rvalue;
}

sub ssh_key{
	my ($full_hostname) = @_;
	# print " -- Clearing SSH known hosts for $full_hostname\n";
	# Remove key for host and quad ip
	`ssh-keygen -R $full_hostname 2>/dev/null`;
	`ssh-keygen -R \$(host $full_hostname | grep 'has address' | awk '{print \$4}') 2>/dev/null`;
	my $scan_done = 0;
	my $sleep_time = 2;
	do {
		# print " -- Acquiring SSH fingerprint for $full_hostname \n";
		`ssh-keyscan -t rsa -H $full_hostname >> $ENV{HOME}/.ssh/known_hosts 2>/dev/null`;
		my $rcode1 = $?;                # actually should be $? >> 8, then 65280 is 255, see perlvar
		`ssh-keyscan -t rsa -H \$(host $full_hostname | grep 'has address' | awk '{print \$4}') >> $ENV{HOME}/.ssh/known_hosts 2>/dev/null`;
		my $rcode2 = $?;
		# actually, it might not return an error when it has failed. RWL  Nov 2013
		# it should have written this to STDERR:
		# but we got nothing, and known_hosts did not get anything appended.
		# So I will call this everytime that ssh has failed.
		if ($rcode1 == 0){
			$scan_done = 1;
		} else {
			print " -- Return code from ssh-keyscan is $rcode1 and $rcode2 \n";

			sleep( $sleep_time);
			# increase the sleep time until it is over 15 min
			$sleep_time = $sleep_time * 2;
			if( $sleep_time > 1000) {
			    print "ERROR: ssh-keyscan failed \n";
			    exit(1);
			} 
		}
	} while ($scan_done == 0);
}

# end
