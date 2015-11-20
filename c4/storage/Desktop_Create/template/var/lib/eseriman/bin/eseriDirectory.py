#!/usr/bin/env python
#
# Manipulate the entries in the directory - v1.0
#
# Created by Karoly Molnar <kmolnar@eseri.com>
#
# Copyright (c) 1996-2010 Eseri (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

from optparse import OptionParser
from socket import getfqdn;
import ldap
import ldap.modlist as modlist

# Globals
domain = getfqdn().partition('.')[2]
ldap_host = "ldap://directory." + domain + "/"
ldap_base_dn = 'dc=' + ',dc='.join(domain.split('.'))
ldap_bind_user = "cn=admin," + ldap_base_dn
ldap_bind_pw = "[-LDAP_DIRECTORY_PASSWORD_ROOT-]"
verbose = False

def ldap_add_entry(first_name, last_name, username, email):
	l = ldap.initialize(ldap_host)
	l.simple_bind_s(ldap_bind_user, ldap_bind_pw)

	dn = "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn
	if verbose:
		print "Add '" + dn + "' entry"
	attrs = {}
	attrs['objectclass'] = ['top', 'inetOrgPerson', 'evolutionPerson', 'calEntry']
	attrs['sn'] = last_name
	attrs['givenName'] = first_name
	attrs['cn'] = first_name + " " + last_name
	attrs['mail'] = email
	attrs['calFBURL'] = 'http://webmail.' + domain + '/index.php?u=' + username
	ldif = modlist.addModlist(attrs)

	l.add_s(dn,ldif)

	l.unbind_s()

def ldap_del_entry(first_name, last_name):
	l = ldap.initialize(ldap_host)
	l.simple_bind_s(ldap_bind_user, ldap_bind_pw)

	dn = "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn
	if verbose:
		print "Delete '" + dn + "' entry"
	try:
		# you can safely ignore the results returned as an exception 
		# will be raised if the delete doesn't work.
		l.delete_s(dn)
	except ldap.LDAPError, e:
		sys.exc_clear()

	l.unbind_s()

def ldap_add_email(first_name, last_name, username, email):
	l = ldap.initialize(ldap_host)
	l.simple_bind_s(ldap_bind_user, ldap_bind_pw)

	mail_add_email = False
	mail_remove_default_email = False
	try:
		ldap_results = l.search_s(
			"ou=people," + ldap_base_dn,
			ldap.SCOPE_ONELEVEL,
			"(cn=" + first_name + " " + last_name + ")",
			[("mail")])

		for dn, attrs in ldap_results:
			if dn == "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn:
				mail_add_email = True
				if "mail" in attrs:
					for email_address in attrs["mail"]:
						if email_address == email:
							print "Email address is already associated with the entry"
							exit(1)
						if email_address == username + "@" + domain:
							mail_remove_default_email = True

	except ldap.LDAPError, e:
		print e

	if mail_add_email:
		dn = "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn
		if verbose:
			print "Add '" + email + "' address to '" + dn + "' entry"
		modlist = [(ldap.MOD_ADD, "mail", email)]
		l.modify_s(dn,modlist)

	l.unbind_s()

	if mail_remove_default_email:
		ldap_remove_email(first_name, last_name, username, username + "@" + domain)

def ldap_remove_email(first_name, last_name, username, email):
	l = ldap.initialize(ldap_host)
	l.simple_bind_s(ldap_bind_user, ldap_bind_pw)

	mail_remove_email = False
	mail_add_default_email = False
	try:
		ldap_results = l.search_s(
			"ou=people," + ldap_base_dn,
			ldap.SCOPE_ONELEVEL,
			"(cn=" + first_name + " " + last_name + ")",
			[("mail")])

		for dn, attrs in ldap_results:
			if dn == "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn:
				if "mail" in attrs:
					for email_address in attrs["mail"]:
						if email_address == email:
							mail_remove_email = True

					if mail_remove_email:
						if len(attrs["mail"]) == 1:
							mail_add_default_email = True

	except ldap.LDAPError, e:
		print e

	if mail_remove_email:
		dn = "cn=" + first_name + " " + last_name + ",ou=people," + ldap_base_dn
		if verbose:
			print "Remove '" + email + "' address from '" + dn + "' entry"
		modlist = [(ldap.MOD_DELETE, "mail", email)]
		l.modify_s(dn,modlist)

	l.unbind_s()

	if mail_add_default_email:
		ldap_add_email(first_name, last_name, username, username + "@" + domain)

def main():
	global verbose

	# Parse command line arguments
	parser = OptionParser(usage="usage: %prog [options]")

	parser.add_option("-c", "--create", action="store_true", dest="create", default=False, help="Add entry to directory")
	parser.add_option("-a", "--add", action="store_true", dest="add", default=False, help="Add email address to entry in directory")
	parser.add_option("-r", "--remove", action="store_true", dest="remove", default=False, help="Remove email address from entry in directory")
	parser.add_option("-d", "--delete", action="store_true", dest="delete", default=False, help="Delete entry from directory")

	parser.add_option("-u", "--username", action="store", type="string", dest="username", help="Username")
	parser.add_option("-f", "--first_name", action="store", type="string", dest="first_name", help="First name (required)")
	parser.add_option("-l", "--last_name", action="store", type="string", dest="last_name", help="Last name (required)")
	parser.add_option("-e", "--email", action="store", type="string", dest="email", help="Email")

	parser.add_option("-v", "--verbose", action="store_true", dest="verbose", default=False, help="Show activity")

	(options, args) = parser.parse_args()

	verbose = options.verbose

	if len(args) != 0:
		parser.error("Unnecessary argument is specified")

	# Create entry in directory
	if options.create:
		if options.add or options.remove or options.delete:
			parser.error("--create, --add, --remove and --delete are mutually exclusive")

		mandatories = ['first_name', 'last_name', 'username', 'email']
		for m in mandatories:
			if not options.__dict__[m]:
				parser.error("Required option is missing")

		ldap_add_entry(options.first_name, options.last_name, options.username, options.email)

	# Delete entry from directory
	elif options.delete:
		if options.create or options.add or options.remove:
			parser.error("--create, --add, --remove and --delete are mutually exclusive")

		mandatories = ['first_name', 'last_name']
		for m in mandatories:
			if not options.__dict__[m]:
				parser.error("Required option is missing")

		ldap_del_entry(options.first_name, options.last_name)

	# Add email to entry in directory
	elif options.add:
		if options.create or options.remove or options.delete:
			parser.error("--create, --add, --remove and --delete are mutually exclusive")

		mandatories = ['first_name', 'last_name', 'username', 'email']
		for m in mandatories:
			if not options.__dict__[m]:
				parser.error("Required option is missing")

		ldap_add_email(options.first_name, options.last_name, options.username, options.email)

	# Remove email from entry in directory
	elif options.remove:
		if options.create or options.add or options.delete:
			parser.error("--create, --add, --remove and --delete are mutually exclusive")

		mandatories = ['first_name', 'last_name', 'username', 'email']
		for m in mandatories:
			if not options.__dict__[m]:
				parser.error("Required option is missing")

		ldap_remove_email(options.first_name, options.last_name, options.username, options.email)

if __name__ == "__main__":
    main()
