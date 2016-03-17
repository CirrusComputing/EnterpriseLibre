#!/bin/sh 
# 
# A utility for accessing ldap with retries. 
# 
# When C4 is 20 minutes into its work, and a LDAP server it temporarily not reachable, 
# we do not want to give up until we have retried a few times. 
# 
# RWL Dec 2013 
# 
# Copyright (c) 1996-2013 Free Open Source Solutions Inc. 
# All Rights Reserved 
# 
# Free Open Source Solutions Inc. owns and reserves all rights, title, 
# and interest in and to this software in both machine and human 
# readable forms. 
# 

ldapSearchUser()
{
    local  __pass=$1
    local  __app=$2
    local  __usr=$3
    local  __base=$4
    local  __request=$5
    local  __resultvar=$6
    local  ldap_out='s'

    TIME=0
    TIMEOUT=40000
    while true; do
        # Read full name from LDAP 
        ldap_out=$(ldapsearch -x -w "$__pass" -D cn=$__app,ou=applications,ou=system,$__base  uid=$__usr $__request )
        [ $? -eq 0 ] && break
        echo "Time: $TIME sec(s)"
        sleep 10
	TIME=$(expr $TIME + 10)
        # loop forever might be better?? 
        [ $TIME -ge $TIMEOUT ] && exit 1
    done
    eval $__resultvar="'$ldap_out'"
}

# end 