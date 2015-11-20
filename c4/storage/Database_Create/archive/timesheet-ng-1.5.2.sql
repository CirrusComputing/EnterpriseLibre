-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: timesheet
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `timesheet_absences`
--

DROP TABLE IF EXISTS `timesheet_absences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_absences` (
  `entry_id` int(6) NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `AM_PM` enum('day','AM','PM') NOT NULL DEFAULT 'day',
  `subject` varchar(127) NOT NULL DEFAULT '',
  `type` enum('Holiday','Sick','Military','Training','Compensation','Other','Public') NOT NULL DEFAULT 'Holiday',
  `user` varchar(32) NOT NULL DEFAULT '0',
  PRIMARY KEY (`entry_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_absences`
--

LOCK TABLES `timesheet_absences` WRITE;
/*!40000 ALTER TABLE `timesheet_absences` DISABLE KEYS */;
/*!40000 ALTER TABLE `timesheet_absences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_allowances`
--

DROP TABLE IF EXISTS `timesheet_allowances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_allowances` (
  `entry_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL DEFAULT '0',
  `date` date NOT NULL,
  `Holiday` int(11) NOT NULL,
  `glidetime` time NOT NULL,
  PRIMARY KEY (`entry_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_allowances`
--

LOCK TABLES `timesheet_allowances` WRITE;
/*!40000 ALTER TABLE `timesheet_allowances` DISABLE KEYS */;
/*!40000 ALTER TABLE `timesheet_allowances` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_assignments`
--

DROP TABLE IF EXISTS `timesheet_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_assignments` (
  `proj_id` int(11) NOT NULL DEFAULT '0',
  `username` char(32) NOT NULL DEFAULT '',
  `rate_id` int(11) NOT NULL,
  PRIMARY KEY (`proj_id`,`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_assignments`
--

LOCK TABLES `timesheet_assignments` WRITE;
/*!40000 ALTER TABLE `timesheet_assignments` DISABLE KEYS */;
INSERT INTO `timesheet_assignments` VALUES (1,'guest',1);
/*!40000 ALTER TABLE `timesheet_assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_billrate`
--

DROP TABLE IF EXISTS `timesheet_billrate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_billrate` (
  `rate_id` int(8) NOT NULL AUTO_INCREMENT,
  `bill_rate` decimal(8,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`rate_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_billrate`
--

LOCK TABLES `timesheet_billrate` WRITE;
/*!40000 ALTER TABLE `timesheet_billrate` DISABLE KEYS */;
INSERT INTO `timesheet_billrate` VALUES (1,'0.00');
/*!40000 ALTER TABLE `timesheet_billrate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_client`
--

DROP TABLE IF EXISTS `timesheet_client`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_client` (
  `client_id` int(8) NOT NULL AUTO_INCREMENT,
  `organisation` varchar(64) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `address1` varchar(127) DEFAULT NULL,
  `city` varchar(60) DEFAULT NULL,
  `state` varchar(80) DEFAULT NULL,
  `country` char(2) DEFAULT NULL,
  `postal_code` varchar(13) DEFAULT NULL,
  `contact_first_name` varchar(127) DEFAULT NULL,
  `contact_last_name` varchar(127) DEFAULT NULL,
  `username` varchar(32) DEFAULT NULL,
  `contact_email` varchar(127) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `fax_number` varchar(20) DEFAULT NULL,
  `gsm_number` varchar(20) DEFAULT NULL,
  `http_url` varchar(127) DEFAULT NULL,
  `address2` varchar(127) DEFAULT NULL,
  PRIMARY KEY (`client_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_client`
--

LOCK TABLES `timesheet_client` WRITE;
/*!40000 ALTER TABLE `timesheet_client` DISABLE KEYS */;
INSERT INTO `timesheet_client` VALUES (1,'No Client','This is required, do not edit or delete this client record','','','','','','','','','','','','','','');
/*!40000 ALTER TABLE `timesheet_client` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_config`
--

DROP TABLE IF EXISTS `timesheet_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_config` (
  `config_set_id` int(1) NOT NULL DEFAULT '0',
  `version` varchar(32) NOT NULL DEFAULT '1.5.2',
  `headerhtml` mediumtext NOT NULL,
  `bodyhtml` mediumtext NOT NULL,
  `footerhtml` mediumtext NOT NULL,
  `errorhtml` mediumtext NOT NULL,
  `bannerhtml` mediumtext NOT NULL,
  `tablehtml` mediumtext NOT NULL,
  `locale` varchar(127) DEFAULT NULL,
  `timezone` varchar(127) DEFAULT NULL,
  `timeformat` enum('12','24') NOT NULL DEFAULT '12',
  `weekstartday` tinyint(4) NOT NULL DEFAULT '0',
  `useLDAP` tinyint(4) NOT NULL DEFAULT '0',
  `LDAPScheme` varchar(32) DEFAULT NULL,
  `LDAPHost` varchar(255) DEFAULT NULL,
  `LDAPPort` int(11) DEFAULT NULL,
  `LDAPBaseDN` varchar(255) DEFAULT NULL,
  `LDAPUsernameAttribute` varchar(255) DEFAULT NULL,
  `LDAPSearchScope` enum('base','sub','one') NOT NULL DEFAULT 'base',
  `LDAPFilter` varchar(255) DEFAULT NULL,
  `LDAPProtocolVersion` varchar(255) DEFAULT '3',
  `LDAPBindUsername` varchar(255) DEFAULT '',
  `LDAPBindPassword` varchar(255) DEFAULT '',
  `LDAPBindByUser` tinyint(4) NOT NULL DEFAULT '0',
  `LDAPReferrals` tinyint(4) NOT NULL DEFAULT '0',
  `LDAPFallback` tinyint(4) NOT NULL DEFAULT '0',
  `aclStopwatch` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclDaily` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclWeekly` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclMonthly` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclSimple` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclClients` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclProjects` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclTasks` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclReports` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclRates` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `aclAbsences` enum('Admin','Mgr','Basic','None') NOT NULL DEFAULT 'Basic',
  `simpleTimesheetLayout` enum('small work description field','big work description field','no work description field') NOT NULL DEFAULT 'small work description field',
  `startPage` enum('stopwatch','daily','weekly','monthly','simple') NOT NULL DEFAULT 'monthly',
  `project_items_per_page` int(11) DEFAULT '10',
  `task_items_per_page` int(11) DEFAULT '10',
  PRIMARY KEY (`config_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_config`
--

LOCK TABLES `timesheet_config` WRITE;
/*!40000 ALTER TABLE `timesheet_config` DISABLE KEYS */;
INSERT INTO `timesheet_config` VALUES (0,'1.5.2','<META name=\"description\" content=\"Timesheet Next Gen\">\r\n<link href=\"css/timesheet.css\" rel=\"stylesheet\" type=\"text/css\">\r\n<link rel=\"shortcut icon\" href=\"images/favicon.ico\">','link=\"#004E8A\" vlink=\"#171A42\"','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\r\n<tr><td style=\"background-color: #000788; padding: 3;\" class=\"bottom_bar_text\" align=\"center\">\r\nTimesheetNextGen\r\n<br><span style=\"font-size: 9px;\"><b>Page generated %time% %date% (%timezone% time)</b></span>\r\n</td></tr></table>','<TABLE border=0 cellpadding=5 width=\"100%\">\r\n<TR>\r\n  <TD><FONT size=\"+2\" color=\"red\">%errormsg%</FONT></TD>\r\n</TR></TABLE>\r\n<P>Please go <A href=\"javascript:history.back()\">Back</A> and try again.</P>','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n<td colspan=\"2\" background=\"images/timesheet_background_pattern.gif\"><img src=\"images/timesheet_banner.gif\"></td>\r\n</tr><tr>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\">%commandmenu%</td>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\" align=\"right\" width=\"145\" valign=\"top\">You are logged in as %username%</td>\r\n</tr><tr>\r\n<td colspan=\"2\" height=\"1\" style=\"background-color: #758DD6;\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td>\r\n</tr></table>','','','Europe/Zurich','12',1,0,'ldap','watson',389,'dc=watson','cn','base','','3','','',0,0,0,'Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','small work description field','monthly',10,10),(1,'1.5.2','<META name=\"description\" content=\"Timesheet Next Gen\">\r\n<link href=\"css/timesheet.css\" rel=\"stylesheet\" type=\"text/css\">\r\n<link rel=\"shortcut icon\" href=\"images/favicon.ico\">','link=\"#004E8A\" vlink=\"#171A42\"','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\r\n<tr><td style=\"background-color: #000788; padding: 3;\" class=\"bottom_bar_text\" align=\"center\">\r\nTimesheetNextGen\r\n<br><span style=\"font-size: 9px;\"><b>Page generated %time% %date% (%timezone% time)</b></span>\r\n</td></tr></table>','<TABLE border=0 cellpadding=5 width=\"100%\">\r\n<TR>\r\n  <TD><FONT size=\"+2\" color=\"red\">%errormsg%</FONT></TD>\r\n</TR></TABLE>\r\n<P>Please go <A href=\"javascript:history.back()\">Back</A> and try again.</P>','<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\r\n<td colspan=\"2\" background=\"images/timesheet_background_pattern.gif\"><img src=\"images/timesheet_banner.gif\"></td>\r\n</tr><tr>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\">%commandmenu%</td>\r\n<td style=\"background-color: #F2F3FF; padding: 3;\" align=\"right\" width=\"145\" valign=\"top\">You are logged in as %username%</td>\r\n</tr><tr>\r\n<td colspan=\"2\" height=\"1\" style=\"background-color: #758DD6;\"><img src=\"images/spacer.gif\" width=\"1\" height=\"1\"></td>\r\n</tr></table>','','','Europe/Zurich','12',1,0,'ldap','watson',389,'dc=watson','cn','base','','3','','',0,0,0,'Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','Basic','small work description field','monthly',10,10);
/*!40000 ALTER TABLE `timesheet_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_project`
--

DROP TABLE IF EXISTS `timesheet_project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_project` (
  `proj_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL DEFAULT '',
  `client_id` int(11) NOT NULL DEFAULT '0',
  `description` varchar(255) DEFAULT NULL,
  `start_date` date NOT NULL DEFAULT '1970-01-01',
  `deadline` date NOT NULL DEFAULT '0000-00-00',
  `http_link` varchar(127) DEFAULT NULL,
  `proj_status` enum('Pending','Started','Suspended','Complete') NOT NULL DEFAULT 'Pending',
  `proj_leader` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`proj_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_project`
--

LOCK TABLES `timesheet_project` WRITE;
/*!40000 ALTER TABLE `timesheet_project` DISABLE KEYS */;
INSERT INTO `timesheet_project` VALUES (1,'Default Project',1,'','1970-01-01','1970-01-01','','Started','');
/*!40000 ALTER TABLE `timesheet_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_task`
--

DROP TABLE IF EXISTS `timesheet_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_task` (
  `task_id` int(11) NOT NULL AUTO_INCREMENT,
  `proj_id` int(11) NOT NULL DEFAULT '0',
  `name` varchar(127) NOT NULL DEFAULT '',
  `description` text,
  `assigned` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `started` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `suspended` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `completed` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status` enum('Pending','Assigned','Started','Suspended','Complete') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`task_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_task`
--

LOCK TABLES `timesheet_task` WRITE;
/*!40000 ALTER TABLE `timesheet_task` DISABLE KEYS */;
INSERT INTO `timesheet_task` VALUES (1,1,'Default Task','','0000-00-00 00:00:00','0000-00-00 00:00:00','0000-00-00 00:00:00','0000-00-00 00:00:00','Started');
/*!40000 ALTER TABLE `timesheet_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_task_assignments`
--

DROP TABLE IF EXISTS `timesheet_task_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_task_assignments` (
  `task_id` int(8) NOT NULL DEFAULT '0',
  `username` varchar(32) NOT NULL DEFAULT '',
  `proj_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`task_id`,`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_task_assignments`
--

LOCK TABLES `timesheet_task_assignments` WRITE;
/*!40000 ALTER TABLE `timesheet_task_assignments` DISABLE KEYS */;
INSERT INTO `timesheet_task_assignments` VALUES (1,'guest',1);
/*!40000 ALTER TABLE `timesheet_task_assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_times`
--

DROP TABLE IF EXISTS `timesheet_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_times` (
  `uid` varchar(32) NOT NULL DEFAULT '',
  `start_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00',
  `end_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `duration` smallint(5) unsigned DEFAULT NULL,
  `trans_num` int(11) NOT NULL AUTO_INCREMENT,
  `proj_id` int(11) NOT NULL DEFAULT '1',
  `task_id` int(11) NOT NULL DEFAULT '1',
  `log_message` text,
  UNIQUE KEY `trans_num` (`trans_num`),
  KEY `uid` (`uid`,`trans_num`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_times`
--

LOCK TABLES `timesheet_times` WRITE;
/*!40000 ALTER TABLE `timesheet_times` DISABLE KEYS */;
/*!40000 ALTER TABLE `timesheet_times` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timesheet_user`
--

DROP TABLE IF EXISTS `timesheet_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timesheet_user` (
  `username` varchar(32) NOT NULL DEFAULT '',
  `level` int(11) NOT NULL DEFAULT '0',
  `password` varchar(41) NOT NULL DEFAULT '',
  `first_name` varchar(64) NOT NULL DEFAULT '',
  `last_name` varchar(64) NOT NULL DEFAULT '',
  `email_address` varchar(63) NOT NULL DEFAULT '',
  `time_stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status` enum('INACTIVE','ACTIVE') NOT NULL DEFAULT 'ACTIVE',
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `session` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`username`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timesheet_user`
--

LOCK TABLES `timesheet_user` WRITE;
/*!40000 ALTER TABLE `timesheet_user` DISABLE KEYS */;
/*!40000 ALTER TABLE `timesheet_user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-11-06 13:37:23
