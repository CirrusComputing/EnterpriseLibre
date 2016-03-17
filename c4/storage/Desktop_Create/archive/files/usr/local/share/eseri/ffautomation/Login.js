//
// Web services automation
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

const gTimeout = 5000;

var setupModule = function(module) {
  controller = mozmill.getBrowserController();
}

var testRecorded = function () {
  controller.open('http://wiki.[-DOMAIN-]/');[-DELETE_UNLESS_Wiki-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Wiki-]
  controller.sleep(500);[-DELETE_UNLESS_Wiki-]

  controller.open('http://trac.[-DOMAIN-]/');[-DELETE_UNLESS_Trac-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Trac-]
  controller.sleep(500);[-DELETE_UNLESS_Trac-]
  controller.click(new elementslib.Link(controller.tabs.activeTab, "Preferences"));[-DELETE_UNLESS_Trac-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Trac-]
  var nameField = new elementslib.ID(controller.tabs.activeTab, "name");[-DELETE_UNLESS_Trac-]
  var emailField = new elementslib.ID(controller.tabs.activeTab, "email");[-DELETE_UNLESS_Trac-]
  controller.waitForElement(nameField, gTimeout);[-DELETE_UNLESS_Trac-]
  controller.type(nameField, "[-REAL_NAME-]");[-DELETE_UNLESS_Trac-]
  controller.type(emailField, "[-EMAIL-]");[-DELETE_UNLESS_Trac-]
  controller.click(new elementslib.XPath(controller.tabs.activeTab, "/html/body/div[@id='main']/div[@id='content']/div[@id='tabcontent']/form[@id='userprefs']/div[2]/input[2]"));[-DELETE_UNLESS_Trac-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Trac-]
  controller.sleep(500);[-DELETE_UNLESS_Trac-]

  controller.open('http://vtiger.[-DOMAIN-]/');[-DELETE_UNLESS_Vtiger-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Vtiger-]
  controller.sleep(500);[-DELETE_UNLESS_Vtiger-]

  controller.open('http://timesheet.[-DOMAIN-]/');[-DELETE_UNLESS_Timesheet-]
  controller.waitForPageLoad();[-DELETE_UNLESS_Timesheet-]
  controller.sleep(500);[-DELETE_UNLESS_Timesheet-]
}
