#!/bin/bash
#
# VPS Reboot script - v2.9
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Boot all VPS"

VEID_BASE=$(getParameter veid_base)
VPS_LIST=$(getParameter vps_list)
VPS_LIST_STOP=$(echo "$VPS_LIST" | tr " " "\n" | sort -unr | tr "\n" " ")
VPS_LIST_START=$(echo "$VPS_LIST" | tr " " "\n" | sort -un | tr "\n" " ")
ACTION=$(getParameter boot_action)

echo "$(date) - VPS $ACTION"

# All services
VPS_PROCESSES_2=( "/usr/sbin/sshd" "/usr/sbin/named" )
VPS_PROCESSES_3=( "/usr/sbin/sshd" "/sbin/shorewall" "/usr/sbin/apache2" )
VPS_PROCESSES_4=( "/usr/sbin/sshd" )
VPS_PROCESSES_10=( "/usr/sbin/sshd" "/usr/sbin/krb5kdc" "/usr/sbin/kadmind" "/usr/sbin/slapd" )
VPS_PROCESSES_11=( "/usr/sbin/sshd" "/usr/sbin/slapd" "/usr/sbin/saslauthd" )
VPS_PROCESSES_30=( "/usr/sbin/sshd" "/usr/sbin/mysqld" "/usr/lib/postgresql/8.4/bin/postgres" )
hasCapability MailingLists
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_31=( "/usr/sbin/sshd" "/usr/lib/postfix/master" "/usr/lib/mailman/bin/mailmanctl" "/usr/sbin/nscd" "/var/lib/mailman/bin/qrunner" "/usr/bin/dspam" "/usr/sbin/apache2" "/usr/sbin/dovecot" "/usr/bin/dk-filter" "/usr/sbin/dkim-filter" )
else
	VPS_PROCESSES_31=( "/usr/sbin/sshd" "/usr/lib/postfix/master" "/usr/sbin/nscd" "/usr/bin/dspam" "/usr/sbin/dovecot" "/usr/bin/dk-filter" "/usr/sbin/dkim-filter" )
fi
VPS_PROCESSES_32=( "/usr/sbin/sshd" "/usr/sbin/apache2" )
hasCapability Nuxeo
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_33=( "/usr/sbin/sshd" "/var/lib/nuxeo/bin/run.sh" )
else
	VPS_PROCESSES_33=( "/usr/sbin/sshd" )
fi
hasCapability WebConferencing
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_34=( "/usr/sbin/sshd" "/usr/lib/openoffice/program/soffice.bin" "/var/lib/webhuddle/bin/run.sh" )
else
	VPS_PROCESSES_34=( "/usr/sbin/sshd" )
fi
hasCapability InstantMessaging
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_35=( "/usr/sbin/sshd" "/usr/lib/jvm/java-6-sun/bin/java" )
else
	VPS_PROCESSES_35=( "/usr/sbin/sshd" )
fi
hasCapability Smartphone
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_36=( "/usr/sbin/sshd" "/opt/Funambol/tools/jre-1.6.0/jre/bin/java" )
else
	VPS_PROCESSES_36=( "/usr/sbin/sshd" )
fi
hasCapability SOGo
if [ $? -eq 0 ] ; then
	VPS_PROCESSES_37=( "/usr/sbin/sshd" "/usr/bin/memcached" "/usr/sbin/sogod" "/usr/sbin/apache2" "/usr/sbin/dovecot" )
else
	VPS_PROCESSES_37=( "/usr/sbin/sshd" )
fi
VPS_PROCESSES_39=( "/usr/sbin/sshd" "/usr/sbin/apache2" )
VPS_PROCESSES_50=( "/usr/sbin/sshd" "/usr/sbin/nscd" )

# Service init scripts
VPS_INIT_SCRIPTS_2=( "/etc/init.d/bind9" )
VPS_INIT_SCRIPTS_3=( "/etc/init.d/shorewall" "/etc/init.d/apache2" )
VPS_INIT_SCRIPTS_4=( )
VPS_INIT_SCRIPTS_10=( "/etc/init.d/krb5-admin-server" "/etc/init.d/krb5-kdc" "/etc/init.d/slapd" )
VPS_INIT_SCRIPTS_11=( "/etc/init.d/slapd" "/etc/init.d/saslauthd" )
VPS_INIT_SCRIPTS_30=( "/etc/init.d/postgresql-8.4" "service mysql" )
VPS_INIT_SCRIPTS_31=( "/etc/init.d/postfix" "/etc/init.d/mailman" "/etc/init.d/dovecot" "/etc/init.d/dspam" "/etc/init.d/dk-filter" "/etc/init.d/dkim-filter" "/etc/init.d/apache2" )
VPS_INIT_SCRIPTS_32=( "/etc/init.d/apache2" )
VPS_INIT_SCRIPTS_33=( "/etc/init.d/nuxeo" )
VPS_INIT_SCRIPTS_34=( "/etc/init.d/webhuddle" "/etc/init.d/openoffice" )
VPS_INIT_SCRIPTS_35=( "/etc/init.d/openfire" )
VPS_INIT_SCRIPTS_36=( "/etc/init.d/funambol" )
VPS_INIT_SCRIPTS_37=( "/etc/init.d/apache2" "/etc/init.d/sogo" "/etc/init.d/memcached" "/etc/init.d/dovecot" )
VPS_INIT_SCRIPTS_39=( "/etc/init.d/apache2" )
VPS_INIT_SCRIPTS_50=( "/etc/init.d/nxserver" "service dbus" "/etc/init.d/cups" "/etc/init.d/nscd" )

stopVPS()
{
	VEID_INDEX=$1
	VEID=$(expr $VEID_BASE + $VEID_INDEX)
	vzctl exec $VEID 'apt-get clean'

	echo "Stopping services on $VEID"

	# Stop services
	eval LENGTH=\${#VPS_INIT_SCRIPTS_$VEID_INDEX[@]}
	LENGTH=$(expr $LENGTH - 1)
	for INIT_SCRIPT_INDEX in $(seq 0 $LENGTH) ; do
		eval VPS_INIT_SCRIPT=\${VPS_INIT_SCRIPTS_$VEID_INDEX[$INIT_SCRIPT_INDEX]}
		echo "Stopping: $VPS_INIT_SCRIPT"
		vzctl exec $VEID "$VPS_INIT_SCRIPT stop"
	done

	# Stop general services
	echo "Stopping: ssh, nagios, cron, syslog"
	vzctl exec $VEID 'service ssh stop'
	vzctl exec $VEID '/etc/init.d/nagios-nrpe-server stop'
	vzctl exec $VEID 'service cron stop'
	vzctl exec $VEID '/etc/init.d/syslog-ng stop'
	echo "Checking remaining procs"
	vzctl exec $VEID 'ps aux' | tee - | wc -l
	echo "Checking remaining procs"
	vzctl exec $VEID 'ps aux' | tee - | wc -l
	echo "$(date) - Stop VPS $VEID"
	vzctl stop $VEID
}

startVPS()
{
        VEID_INDEX=$1
	VEID=$(expr $VEID_BASE + $VEID_INDEX)
	vzctl start $VEID

	# Wait for all the services to start
	TIME=1
	TIMEOUT=60
	ITERATION=1
	while true; do
		[ $ITERATION -gt 3 ] && exit 1
		echo "$VEID - Iteration: $ITERATION - Time: $TIME sec(s)"
		RUNNING=1
		eval LENGTH=\${#VPS_PROCESSES_$VEID_INDEX[@]}
		LENGTH=$(expr $LENGTH - 1)
		for PROCESS_INDEX in $(seq 0 $LENGTH) ; do
			eval VPS_PROCESS=\${VPS_PROCESSES_$VEID_INDEX[$PROCESS_INDEX]}
			if [ $VPS_PROCESS == '/sbin/shorewall' ]; then
				vzctl exec $VEID "$VPS_PROCESS status"
			else
				vzctl exec $VEID 'ps aux' | grep $VPS_PROCESS | grep -v grep
			fi
			if [ $? -eq 0 ]; then
				echo " -$VPS_PROCESS is running on $VEID"
			else
				echo " -$VPS_PROCESS is not running on $VEID"
				RUNNING=0
				break
			fi
		done

		[ $RUNNING -eq 1 ] && break
		sleep 1
		TIME=$(expr $TIME + 1)
		if [ $TIME -ge $TIMEOUT ]; then
			stopVPS $VEID_INDEX
			vzctl start $VEID
			TIME=1
			ITERATION=$(expr $ITERATION + 1)
		fi
	done
}

if [ $ACTION == 'suspend' -o $ACTION == 'reboot' ]; then
    # Stop all VPS
    echo "$(date) - Stop all VPS"
    for VEID_INDEX in $VPS_LIST_STOP ; do
	stopVPS $VEID_INDEX
    done
fi

if [ $ACTION == 'resume' -o $ACTION == 'reboot' ]; then
    # Start all VPS
    echo "$(date) - Start all VPS"
    for VEID_INDEX in $VPS_LIST_START ; do
	startVPS $VEID_INDEX
    done

    # List all listening sockets
    echo "$(date) - Listening sockets VPS"
    for VEID_INDEX in $VPS_LIST_START ; do
	VEID=$(expr $VEID_BASE + $VEID_INDEX)
	echo "Sockets listening on $VEID:"
	vzctl exec $VEID 'netstat -ntlp'
    done
fi

echo "$(date) - Done $ACTION"
exit 0
