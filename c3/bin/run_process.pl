#!/usr/bin/perl -w
#
# run_process.pl - v1.1
#
# This script runs a specific process for the user in the background - pidgin, evolution, etc.
#
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

use Net::SSH::Perl;
print "Forked process starting...\n";
my $ssh = Net::SSH::Perl->new("$ARGV[2]");
print "Establishing connection to $ARGV[2]\n";
$ssh->login("$ARGV[0]", "$ARGV[1]");
print "Logging into $ARGV[2]\n";
$ssh->cmd("$ARGV[3]");
