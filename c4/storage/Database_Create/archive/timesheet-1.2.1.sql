# MySQL dump
#
# Host: localhost    Database: timesheet
#--------------------------------------------------------

#
# Table structure for table 'assignments'
#
DROP TABLE IF EXISTS assignments;
CREATE TABLE assignments (
  proj_id int(11) DEFAULT '0' NOT NULL,
  username char(32) DEFAULT '' NOT NULL,
  PRIMARY KEY (proj_id,username)
);

INSERT INTO assignments VALUES ( 1, 'guest'); 

#
# Table structure for table 'client'
#
DROP TABLE IF EXISTS client;
CREATE TABLE client (
  client_id int(8) NOT NULL auto_increment,
  organisation varchar(64),
  description varchar(255),
  address1 varchar(127),
  city varchar(60),
  state varchar(80),
  country char(2),
  postal_code varchar(13),
  contact_first_name varchar(127),
  contact_last_name varchar(127),
  username varchar(32),
  contact_email varchar(127),
  phone_number varchar(20),
  fax_number varchar(20),
  gsm_number varchar(20),
  http_url varchar(127),
  address2 varchar(127),
  PRIMARY KEY (client_id)
);

INSERT INTO client VALUES (1,'No Client', 'This is required, do not edit or delete this client record', '', '', '', '', '', '', '', '', '', '', '', '', '', '');

#
# Table structure for table 'config'
#

DROP TABLE IF EXISTS config;
CREATE TABLE config (
  config_set_id int(1) NOT NULL default '0',
  version varchar(32) NOT NULL default '1.2.1',
  headerhtml mediumtext NOT NULL,
  bodyhtml mediumtext NOT NULL,
  footerhtml mediumtext NOT NULL,
  errorhtml mediumtext NOT NULL,
  bannerhtml mediumtext NOT NULL,
  tablehtml mediumtext NOT NULL,
  locale varchar(127) default NULL,
  timezone varchar(127) default NULL,
  timeformat enum('12','24') NOT NULL default '12',
  weekstartday TINYINT NOT NULL default 0,
  useLDAP tinyint(4) NOT NULL default '0',
  LDAPScheme varchar(32) default NULL,
  LDAPHost varchar(255) default NULL,
  LDAPPort int(11) default NULL,
  LDAPBaseDN varchar(255) default NULL,
  LDAPUsernameAttribute varchar(255) default NULL,
  LDAPSearchScope enum('base','sub','one') NOT NULL default 'base',
  LDAPFilter varchar(255) default NULL,
  LDAPProtocolVersion varchar(255) default '3',
  LDAPBindUsername varchar(255) default '',
  LDAPBindPassword varchar(255) default '',
  PRIMARY KEY  (config_set_id)
) TYPE=MyISAM;

#
# Dumping data for table 'config'
#
INSERT INTO config VALUES (0,'1.2.1','<META name=\"description\" content=\"Timesheet.php Employee/Contractor Timesheets\">\r\n<link href=\"css/timesheet.css\" rel=\"stylesheet\" type=\"text/css\">','link=\"#004E8A\" vlink=\"#171A42\"','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\r\n<tr><td style=\"background-color: #000788; padding: 3;\" class=\"bottom_bar_text\" align=\"center\">\r\n\r\nTimesheet.php website: <A href=\"http://www.advancen.com/timesheet/\"><span \r\n\r\nclass=\"bottom_bar_text\">http://www.advancen.com/timesheet/</span></A>\r\n<br><span style=\"font-size: 9px;\"><b>Page generated %time% %date% (%timezone% time)</b></span>\r\n\r\n</td></tr></table>','<TABLE border=0 cellpadding=5 width=\"100%\">\r\n<TR><TD><FONT size=\"+2\" color=\"red\">%errormsg%</FONT></TD></TR></TABLE>\r\n<P>Please go <A href=\"javascript:history.back()\">Back</A> and try again.</P>','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n<td colspan=\"2\" background=\"images/timesheet_background_pattern.gif\"><img src=\"images/timesheet_banner.gif\"></td></tr><tr>\r\n\r\n<td style=\"background-color: #F2F3FF; padding: 3;\">%commandmenu%</td>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\" align=\"right\" width=\"145\" valign=\"top\">You are logged in as %username%</td>\r\n</tr><td colspan=\"2\" height=\"1\" style=\"background-color: #758DD6;\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td></tr>\r\n</table>','','en_AU','Australia/Melbourne','12',1,0,'ldap','watson',389,'dc=watson','cn','base','','3','','');
INSERT INTO config VALUES (1,'1.2.1','<META name=\"description\" content=\"Timesheet.php Employee/Contractor Timesheets\">\r\n<link href=\"css/timesheet.css\" rel=\"stylesheet\" type=\"text/css\">','link=\"#004E8A\" vlink=\"#171A42\"','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\r\n<tr><td style=\"background-color: #000788; padding: 3;\" class=\"bottom_bar_text\" align=\"center\">\r\n\r\nTimesheet.php website: <A href=\"http://www.advancen.com/timesheet/\"><span \r\n\r\nclass=\"bottom_bar_text\">http://www.advancen.com/timesheet/</span></A>\r\n<br><span style=\"font-size: 9px;\"><b>Page generated %time% %date% (%timezone% time)</b></span>\r\n\r\n</td></tr></table>','<TABLE border=0 cellpadding=5 width=\"100%\">\r\n<TR><TD><FONT size=\"+2\" color=\"red\">%errormsg%</FONT></TD></TR></TABLE>\r\n<P>Please go <A href=\"javascript:history.back()\">Back</A> and try again.</P>','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n<td colspan=\"2\" background=\"images/timesheet_background_pattern.gif\"><img src=\"images/timesheet_banner.gif\"></td></tr><tr>\r\n\r\n<td style=\"background-color: #F2F3FF; padding: 3;\">%commandmenu%</td>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\" align=\"right\" width=\"145\" valign=\"top\">You are logged in as %username%</td>\r\n</tr><td colspan=\"2\" height=\"1\" style=\"background-color: #758DD6;\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td></tr>\r\n</table>','','en_AU','Australia/Melbourne','12',1,0,'ldap','watson',389,'dc=watson','cn','base','','3','','');
INSERT INTO config VALUES (2,'1.2.1','<META name=\"description\" content=\"Timesheet.php Employee/Contractor Timesheets\">\r\n<link href=\"css/questra/timesheet.css\" rel=\"stylesheet\" type=\"text/css\">','link=\"#004E8A\" vlink=\"#171A42\"','</td><td width=\"2\" style=\"background-color: #9494B7;\"><img src=\"images/questra/spacer.gif\" width=\"2\" height=\"1\"></td></tr>\r\n<tr><td colspan=\"3\" style=\"background-color: #9494B7; padding: 3;\" class=\"bottom_bar_text\" align=\"center\">\r\n\r\nTimesheet.php website: <A href=\"http://www.advancen.com/timesheet/\"><span \r\n\r\nclass=\"bottom_bar_text\">http://www.advancen.com/timesheet/</span></A>\r\n<br><span style=\"font-size: 9px;\"><b>Page generated %time% %date% (%timezone% time)</b></span>\r\n\r\n</td></tr></table>','<TABLE border=0 cellpadding=5 width=\"100%\">\r\n<TR><TD><FONT size=\"+2\" color=\"red\">%errormsg%</FONT></TD></TR></TABLE>\r\n<P>Please go <A href=\"javascript:history.back()\">Back</A> and try again.</P>','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n  <td style=\"padding-right: 15; padding-bottom: 8;\"><img src=\"images/questra/logo.gif\"></td>\r\n  <td width=\"100%\" valign=\"bottom\">\r\n    <table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\r\n      <tr><td colspan=\"3\" class=\"text_faint\" style=\"padding-bottom: 5;\" align=\"right\">You are logged in as %username%.</td></tr>\r\n      <tr>\r\n        <td background=\"images/questra/bar_left.gif\" valign=\"top\"><img src=\"images/questra/spacer.gif\" height=\"1\" width=\"8\"></td>\r\n        <td background=\"images/questra/bar_background.gif\" width=\"100%\" style=\"padding: 5;\">%commandmenu%</td>\r\n        <td background=\"images/questra/bar_right.gif\" valign=\"top\"><img src=\"images/questra/spacer.gif\" height=\"1\" width=\"8\"></td>\r\n      </tr>\r\n    </table>\r\n  </td>\r\n</tr></table>\r\n\r\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n<td colspan=\"3\" height=\"8\" style=\"background-color: #9494B7;\"><img src=\"images/questra/spacer.gif\" width=\"1\" height=\"8\"></td></tr><tr>\r\n<td width=\"2\" style=\"background-color: #9494B7;\"><img src=\"images/questra/spacer.gif\" width=\"2\" height=\"1\"></td>\r\n<td width=\"100%\" bgcolor=\"#F2F2F8\">','','en_AU','Australia/Melbourne','12',1,0,'ldap','watson',389,'dc=watson','cn','base','','3','','');


#
# Table structure for table 'note'
#
DROP TABLE IF EXISTS note;
CREATE TABLE note (
  note_id int(6) auto_increment,
  proj_id int(8) DEFAULT '0' NOT NULL,
  date datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  subject varchar(127) DEFAULT '' NOT NULL,
  body text NOT NULL,
  to_contact enum('Y','N') DEFAULT 'N' NOT NULL,
  PRIMARY KEY (note_id)
);

#
# Table structure for table 'project'
#
DROP TABLE IF EXISTS project;
CREATE TABLE project (
  proj_id int(11) NOT NULL auto_increment,
  title varchar(200) DEFAULT '' NOT NULL,
  client_id int(11) DEFAULT '0' NOT NULL,
  description varchar(255),
  start_date date DEFAULT '1970-01-01' NOT NULL,
  deadline date DEFAULT '0000-00-00' NOT NULL,
  http_link varchar(127),
  proj_status enum('Pending','Started','Suspended','Complete') DEFAULT 'Pending' NOT NULL,
  proj_leader varchar(32) DEFAULT '' NOT NULL,
  PRIMARY KEY (proj_id)
);

INSERT INTO project VALUES ( 1, 'Default Project', 1, '','','','','Started','');

#
# Table structure for table 'task'
#
DROP TABLE IF EXISTS task;
CREATE TABLE task (
  task_id int(11) NOT NULL auto_increment,
  proj_id int(11) DEFAULT '0' NOT NULL,
  name varchar(127) DEFAULT '' NOT NULL,
  description text,
  assigned datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  started datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  suspended datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  completed datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  status enum('Pending','Assigned','Started','Suspended','Complete') DEFAULT 'Pending' NOT NULL,
  PRIMARY KEY (task_id)
);

INSERT INTO task VALUES (1,1,'Default Task','','','','','','Started');

#
# Table structure for table 'task_assignments'
#
DROP TABLE IF EXISTS task_assignments;
CREATE TABLE task_assignments (
  task_id int(8) DEFAULT '0' NOT NULL,
  username varchar(32) DEFAULT '' NOT NULL,
  proj_id int(11) DEFAULT '0' NOT NULL,
  PRIMARY KEY (task_id,username)
);

INSERT INTO task_assignments VALUES ( 1, 'guest', 1);

#
# Table structure for table 'times'
#
DROP TABLE IF EXISTS times;
CREATE TABLE times (
  uid varchar(32) DEFAULT '' NOT NULL,
  start_time datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  end_time datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  trans_num int(11) NOT NULL auto_increment,
  proj_id int(11) DEFAULT '1' NOT NULL,
  task_id int(11) DEFAULT '1' NOT NULL,
  log_message varchar(255),
  KEY uid (uid,trans_num),
  UNIQUE trans_num (trans_num)
);

#
# Table structure for table 'user'
#
DROP TABLE IF EXISTS user;
CREATE TABLE user (
  username varchar(32) DEFAULT '' NOT NULL,
  level int(11) DEFAULT '0' NOT NULL,
  password varchar(41) DEFAULT '' NOT NULL,
  allowed_realms varchar(20) DEFAULT '.*' NOT NULL,
  first_name varchar(64) DEFAULT '' NOT NULL,
  last_name varchar(64) DEFAULT '' NOT NULL,
  email_address varchar(63) DEFAULT '' NOT NULL,
  phone varchar(31) DEFAULT '' NOT NULL,
  bill_rate decimal(8,2) DEFAULT '0.00' NOT NULL,
  time_stamp timestamp(14),
  status enum('IN','OUT') DEFAULT 'OUT' NOT NULL,
  uid int(11) NOT NULL auto_increment,
  PRIMARY KEY (username),
  KEY uid (uid)
);

