#!/usr/bin/perl -w
#
# set_free_space.pl - v2.0
#
# Determine the host's disk free space and update the Prime DB
#
# Created by Rick Leir <rleir@cirruscomputing.com>
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
use PrimeDB qw(&updateFree);

use Net::SSH2;
use common qw(get_system_anchor_domain);

if ($#ARGV != 0 ) {
    print "Useage: $0 HWHOST \n";
    exit(0);
}

my $HWHOST = $ARGV[0];

# Get system anchor domain
my $system_anchor_domain = get_system_anchor_domain();

my $hostname = "$HWHOST.$system_anchor_domain";
my $username = "root";

# Send the command to the host.
# The cmd parses vgdisplay's output.
# From the line showing Free space, blank out all non-numerics.
# 3 numbers remain, and we want the second one.
my $cmd = ' '
    . "/sbin/vgdisplay --units g |  "
    . " /bin/sed -r "
    . " -e '/^\ \ Free/!d' "
    . " -e 's/[^0-9]/ /g' "
    . " -e 's/[0-9]+//' "
    . " -e 's/[0-9]+\ +\$//' "
    . " -e 's/\ +//' ";

#print "$cmd \n";

my $ssh2 = Net::SSH2->new();
my $auth;
if ( $ssh2->connect("$hostname") ) {
    $auth = $ssh2->auth_publickey(
       'root',
       '/home/c4/.ssh/id_rsa.pub',
       '/home/c4/.ssh/id_rsa'
	);  
}   

if ($auth && $ssh2->auth_ok) {
#    print "Success \n";
} else {
    print $ssh2->error;
}  
#$ssh2->debug(1);

my $chan = $ssh2->channel();
$chan->blocking(1);

# merge stderr with stdout
$chan->ext_data('merge');

$chan->exec("$cmd");
my $output;
my $len = $chan->read($output,8192);
#print "output is $output\n";

my $status = $chan->exit_status();
if( $status != 0) {
    die "status is $status, err is $output \n";
}
$ssh2->disconnect();

# update the DB tally of free space
#print "Setting free space to $output ";
updateFree( $HWHOST, $output);

# end

