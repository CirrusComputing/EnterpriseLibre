#!/usr/bin/env python
#
# Leave the running session dialog window - v1.0
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

import sys
try:
 	import pygtk
  	pygtk.require("2.0")
except:
  	pass
try:
	import gtk
  	import gtk.glade
	import gobject
except:
	sys.exit(1)

class CirrusOpenLeaveSessionGTK:
	def __init__(self):
		try:
			self.builder = gtk.Builder()
			self.builder.add_from_file("/usr/local/share/CirrusOpen/glade/CirrusOpenLeaveSession.glade")
		except:
			self.show_error_dlg("Failed to load UI XML file: CirrusOpenLeaveSession.glade")
			sys.exit(1)
	    
		self.window = self.builder.get_object("MainWindow")
		self.window.connect("destroy", gtk.main_quit)
		self.builder.connect_signals(self)
		self.window.set_keep_above(True)
		self.window.show()

		self.labelAutoLogout = self.builder.get_object('labelAutoLogout')
		self.timeout = 60
		gobject.timeout_add(1000, self.update)

	def update(self):
		if (self.timeout > 0):
			self.timeout -= 1
		if ((self.timeout < 30) or ((self.timeout % 10) == 0)):
			self.labelAutoLogout.set_text("You will be automatically logged out in %d seconds." % self.timeout)
		if (self.timeout==0):
			sys.exit(-1)
		return True

	def on_btnLogout_clicked(self, button):
		sys.exit(-1)

	def on_btnDisconnect_clicked(self, button):
		sys.exit(-2)

	def on_btnCancel_clicked(self, button):
		sys.exit(0)

if __name__ == "__main__":
	CirrusOpenLeaveSessionGTK()
	gtk.main()
