#!/usr/bin/python
#
# Double-Lock v2.2 - Create pam_obc.conf to send the Double-Lock password
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2014 (Free Open Source Solutions Inc.)
# All Rights Reserved
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

import os
import sys
import pycurl
from lxml import etree

class AccountManager(object):

    def __init__(self):
        '''
        Initializes the GUI
        '''
        self.contents = ''
	self.update_user_list()

    def buffer_callback(self, buf):
        '''
        Called by pycurl object to build data from webserver
        '''
        self.contents = self.contents + buf

    def update_user_list(self):
        '''
        Creates the pam_obc.conf file to with the server's most up-to-date list from the database
        '''
	c = pycurl.Curl()
        c.setopt(c.URL, 'http://sys')
        c.setopt(c.USERPWD, ':')
        c.setopt(c.WRITEFUNCTION, self.buffer_callback)
        c.setopt(c.HTTPAUTH, c.HTTPAUTH_GSSNEGOTIATE) 
	c.setopt(c.HTTPHEADER, ['Content-Type: text/xml'])
        c.setopt(c.POSTFIELDS, '<?xml version="1.0" encoding="UTF-8"?><msg><listUsers/></msg>')
        c.perform()
        c.close()
	root = etree.fromstring(self.contents)
        self.contents = ''
	case = sys.argv[1]
        if case == "1" or case == "2":
		f = open('/var/lib/eseriman/pam/pam_obc.conf', 'w+')

	for user in root.xpath('/result/user'):
            username = user.xpath('username')[0].text
            fname = user.xpath('first_name')[0].text
            lname = user.xpath('last_name')[0].text
            remail = user.xpath('real_email')[0].text
            status = user.xpath('status')[0].text
	    dloption = user.xpath('double_lock_option')[0].text
            if (case == "1" or case == "2") and status == "ACTIVE":
		f.write(username + ':mutt -s \"Double-Lock Password\" ' + remail + '\n') 

	    if (case == "1" or case == "3") and status == "ACTIVE":
	            if cmp(dloption,'ON')==0 or cmp(dloption,'ON_LOCKED')==0:
			a = open ('/var/lib/eseriman//pam/' + username, 'w+')
			a.write('[Desktop Entry]\nName=Screenlock\nGenericName=screenlock\nComment=Lock the screen!\nKeywords=lock;screen;screensaver;password;desktop\nExec=gnome-screensaver-command --lock\nTerminal=false\nType=Application\nStartupNotify=true\nNoDisplay=true')
			a.close()	
	    	    else:
			a = open ('/var/lib/eseriman/pam/' + username, 'w+')	
                	a.write('[Desktop Entry]\nName=Screenlock\nGenericName=screenlock\nComment=Lock the screen!\nKeywords=lock;screen;screensaver;password;desktop\nExec=gnome-screensaver-command --lock\nTerminal=false\nType=Application\nStartupNotify=true\nNoDisplay=true\nHidden=true')
                	a.close()
	if (case == "1" or case == "2") and status == "ACTIVE":
		f.close()
	
if __name__ == "__main__":
    app = AccountManager()
