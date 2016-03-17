//
// Webhuddle automation
//
// Created by Karoly Molnar <kmolnar@eseri.com>
//
// Copyright (c) 1996-2010 Free Open Source Solutions Inc.
// All Rights Reserved
//
// Free Open Source Solutions Inc. owns and reserves all rights, title,
// and interest in and to this software in both machine and human
// readable forms.
//

// Include necessary modules
var RELATIVE_ROOT = '../../../../usr/local/share/eseri/ffautomation/shared/';
var MODULE_REQUIRES = ['TabbedBrowsingAPI', 'UtilsAPI'];

const gDelay = 0;
const gTimeout = 5000;

var setupModule = function(module) {
  controller = mozmill.getBrowserController();
  tabBrowser = new TabbedBrowsingAPI.tabBrowser(controller);

  module.pm = Cc["@mozilla.org/login-manager;1"]
                 .getService(Ci.nsILoginManager);
}

/**
 * Test saving a password using the notification bar
 */
var testSavePassword = function() {
  controller.open('https://webmeeting.[-DOMAIN-]/');
  controller.waitForPageLoad();

  controller.click(new elementslib.Link(controller.tabs.activeTab, "Logon"));
  controller.waitForPageLoad();

  var userField = new elementslib.Name(controller.tabs.activeTab, "username");
  var passField = new elementslib.Name(controller.tabs.activeTab, "password");

  controller.waitForElement(userField, gTimeout);
  controller.type(userField, "[-USERNAME-]");
  controller.type(passField, "[-PASSWORD-]");

  controller.click(new elementslib.XPath(controller.tabs.activeTab, "/html/body/form/table/tbody/tr[4]/td/input"));
  controller.sleep(500);

  // After logging in, remember the login information
  var label = UtilsAPI.getProperty("chrome://passwordmgr/locale/passwordmgr.properties", "notifyBarRememberButtonText");
  var button = tabBrowser.getTabPanelElement(tabBrowser.selectedIndex,
                                             '/{"value":"password-save"}/{"label":"' + label + '"}');

  controller.waitThenClick(button, gTimeout);
  controller.sleep(500);
  controller.assertNodeNotExist(button);
}
