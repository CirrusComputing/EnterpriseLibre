#!/bin/bash
#
# Kerberos & Addressbook deploy script - v2.4
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2013 Free Open Source Solutions Inc.
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include eseri functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) - Deploy Kerberos Server and LDAP for addressbook"

KRB5_MASTER_PW=$(getPassword KRB5_MASTER_PW)
KRB5_ADMIN_PW=$(getPassword KRB5_ADMIN_PW)
LDAP_SSHA_PASSWORD_ROOT=$(getPassword LDAP_PASSWORD_ROOT)

# Variables
KRB5_SEED=${ARCHIVE_FOLDER}/krb5.seed
KRB5_CONFIG_FOLDER=/etc/krb5kdc
KRB5_TEMPLATE_KDC_CONFIG=${TEMPLATE_FOLDER}/etc/krb5kdc/kdc.conf
KRB5_KDC_CONFIG=${KRB5_CONFIG_FOLDER}/kdc.conf
KRB5_TEMPLATE_KADMIN_ACL=${TEMPLATE_FOLDER}/etc/krb5kdc/kadm5.acl
KRB5_KADMIN_ACL=${KRB5_CONFIG_FOLDER}/kadm5.acl
KRB5_KADMIN_KEYTAB=${KRB5_CONFIG_FOLDER}/kadm5.keytab
KRB5_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}/etc/krb5.conf
KRB5_CONFIG=/etc/krb5.conf

# Template files
LDAP_TMP_LDIF=/tmp/lapd.ldif
LDAP_TMP_OUTPUT=/tmp/ldif_output

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# Preseed the Kerberos parameters
debconf-set-selections $KRB5_SEED

# Install the Kerberos server and admin server
aptGetInstall krb5-kdc krb5-admin-server

# Deploy config files and modify values
install -o root -g root -m 644 $KRB5_TEMPLATE_KDC_CONFIG $KRB5_KDC_CONFIG
install -o root -g root -m 644 $KRB5_TEMPLATE_KADMIN_ACL $KRB5_KADMIN_ACL
eseriReplaceValues $KRB5_KDC_CONFIG
eseriReplaceValues $KRB5_KADMIN_ACL
cat <<EOF >>$KRB5_CONFIG

[logging]
	kdc = SYSLOG:INFO:DAEMON
	admin_server = SYSLOG:INFO:DAEMON
	default = SYSLOG:INFO:DAEMON
EOF

# Create the database
kdb5_util -r $REALM -P $KRB5_MASTER_PW create -s

# Add the admin principal to the kadm5.keytab file
kadmin.local -q "ktadd -k $KRB5_KADMIN_KEYTAB kadmin/admin kadmin/changepw"

# Add policies for the different principal types
kadmin.local -q "addpol users"
kadmin.local -q "addpol admins"

# Add a principal for remote administration
kadmin.local -q "addprinc -policy admins -pw $KRB5_ADMIN_PW root/admin"

# Start the servers
invoke-rc.d krb5-kdc start
invoke-rc.d krb5-admin-server start

# Create principals
kadmin.local -q "addprinc -randkey ldap/aphrodite.$DOMAIN"
kadmin.local -q "ktadd -k $RESULT_FOLDER/aphrodite.slapd.keytab ldap/aphrodite.$DOMAIN"
kadmin.local -q "addprinc -randkey host/aphrodite.$DOMAIN"
kadmin.local -q "ktadd -k $RESULT_FOLDER/aphrodite.host.keytab host/aphrodite.$DOMAIN"
kadmin.local -q "addprinc -randkey HTTP/poseidon.$DOMAIN"
kadmin.local -q "ktadd -k $RESULT_FOLDER/poseidon.apache2.keytab HTTP/poseidon.$DOMAIN"
kadmin.local -q "addprinc -randkey HTTP/trident.$DOMAIN"
kadmin.local -q "ktadd -k $RESULT_FOLDER/trident.apache2.keytab HTTP/trident.$DOMAIN"

hasCapability Email
if [ $? -eq 0 ] ; then
	kadmin.local -q "addprinc -randkey imap/hera.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/hera.dovecot.keytab imap/hera.$DOMAIN"
	kadmin.local -q "addprinc -randkey smtp/hera.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/hera.dovecot.keytab smtp/hera.$DOMAIN"
	kadmin.local -q "addprinc -randkey host/hera.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/hera.host.keytab host/hera.$DOMAIN"
fi

hasCapability InstantMessaging
if [ $? -eq 0 ] ; then
	kadmin.local -q "addprinc -randkey xmpp/erato.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/erato.openfire.keytab xmpp/erato.$DOMAIN"
fi

hasCapability SOGo
if [ $? -eq 0 ] ; then
	kadmin.local -q "addprinc -randkey HTTP/gaia.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/gaia.apache2.keytab HTTP/gaia.$DOMAIN"
fi

hasCapability Desktop
if [ $? -eq 0 ] ; then
	kadmin.local -q "addprinc -randkey host/chaos.$DOMAIN"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/chaos.host.keytab host/chaos.$DOMAIN"
	kadmin.local -q "addprinc -randkey eseriman/admin"
	kadmin.local -q "ktadd -k $RESULT_FOLDER/chaos.eseriman_admin.keytab eseriman/admin"
fi
# Install the LDAP server
#debconf-set-selections $ARCHIVE_FOLDER/slapd.seed
aptGetInstall slapd ldap-utils

# Convert evolution schemas to ldif
install -o root -g root -m 644 -t /etc/ldap/schema $ARCHIVE_FOLDER/files/etc/ldap/schema/evolutionperson.schema
install -o root -g root -m 644 -t /etc/ldap/schema $ARCHIVE_FOLDER/files/etc/ldap/schema/calEntry.schema

mkdir -p $LDAP_TMP_OUTPUT
slapcat -f $ARCHIVE_FOLDER/schema_convert.conf -F $LDAP_TMP_OUTPUT -n0 -s "cn={4}evolutionperson,cn=schema,cn=config" > /etc/ldap/schema/evolutionperson.ldif
slapcat -f $ARCHIVE_FOLDER/schema_convert.conf -F $LDAP_TMP_OUTPUT -n0 -s "cn={5}calEntry,cn=schema,cn=config" > /etc/ldap/schema/calEntry.ldif
rm -rf $LDAP_TMP_OUTPUT

sed -i -e 's/{4}evolutionperson/evolutionperson/g' -e '/^structuralObjectClass/d' -e '/^entryUUID/d' -e '/^creatorsName/d' -e '/^createTimestamp/d' -e '/^entryCSN/d' -e '/^modifiersName/d' -e '/^modifyTimestamp/d' /etc/ldap/schema/evolutionperson.ldif
sed -i -e 's/{5}calEntry/calEntry/g' -e '/^structuralObjectClass/d' -e '/^entryUUID/d' -e '/^creatorsName/d' -e '/^createTimestamp/d' -e '/^entryCSN/d' -e '/^modifiersName/d' -e '/^modifyTimestamp/d' /etc/ldap/schema/calEntry.ldif

# Populate schemas
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/evolutionperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/calEntry.ldif 

# Populate backend
sed "s~\[-LDAP_SSHA_PASSWORD_ROOT-\]~$(slappasswd -h {SSHA} -s $LDAP_SSHA_PASSWORD_ROOT)~" $TEMPLATE_FOLDER/transient/backend.ldif > $LDAP_TMP_LDIF
eseriReplaceValues $LDAP_TMP_LDIF
ldapadd -Y EXTERNAL -H ldapi:/// -f $LDAP_TMP_LDIF
rm $LDAP_TMP_LDIF

# Populate frontend
cp $TEMPLATE_FOLDER/transient/frontend.ldif $LDAP_TMP_LDIF
eseriReplaceValues $LDAP_TMP_LDIF
ldapadd -x -H ldap://localhost/ -D cn=admin,$LDAP_BASE -w "$LDAP_SSHA_PASSWORD_ROOT" -f $LDAP_TMP_LDIF
rm $LDAP_TMP_LDIF

exit 0
