-- MySQL dump 10.11
--
-- Host: localhost    Database: orangehrm
-- ------------------------------------------------------
-- Server version	5.0.51a-3ubuntu5.4

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
-- Table structure for table `hs_hr_attendance`
--

DROP TABLE IF EXISTS `hs_hr_attendance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_attendance` (
  `attendance_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `punchin_time` datetime default NULL,
  `punchout_time` datetime default NULL,
  `in_note` varchar(250) default NULL,
  `out_note` varchar(250) default NULL,
  `timestamp_diff` int(11) NOT NULL,
  `status` enum('0','1') default NULL,
  PRIMARY KEY  (`attendance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_attendance`
--

LOCK TABLES `hs_hr_attendance` WRITE;
/*!40000 ALTER TABLE `hs_hr_attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_comp_property`
--

DROP TABLE IF EXISTS `hs_hr_comp_property`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_comp_property` (
  `prop_id` int(11) NOT NULL auto_increment,
  `prop_name` varchar(250) NOT NULL,
  `emp_id` int(7) default NULL,
  PRIMARY KEY  (`prop_id`),
  KEY `emp_id` (`emp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_comp_property`
--

LOCK TABLES `hs_hr_comp_property` WRITE;
/*!40000 ALTER TABLE `hs_hr_comp_property` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_comp_property` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_compstructtree`
--

DROP TABLE IF EXISTS `hs_hr_compstructtree`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_compstructtree` (
  `title` tinytext NOT NULL,
  `description` text NOT NULL,
  `loc_code` varchar(13) default NULL,
  `lft` int(4) NOT NULL default '0',
  `rgt` int(4) NOT NULL default '0',
  `id` int(6) NOT NULL,
  `parnt` int(6) NOT NULL default '0',
  `dept_id` varchar(32) default NULL,
  PRIMARY KEY  (`id`),
  KEY `loc_code` (`loc_code`),
  CONSTRAINT `hs_hr_compstructtree_ibfk_1` FOREIGN KEY (`loc_code`) REFERENCES `hs_hr_location` (`loc_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_compstructtree`
--

LOCK TABLES `hs_hr_compstructtree` WRITE;
/*!40000 ALTER TABLE `hs_hr_compstructtree` DISABLE KEYS */;
INSERT INTO `hs_hr_compstructtree` VALUES ('','Parent Company',NULL,1,2,1,0,NULL);
/*!40000 ALTER TABLE `hs_hr_compstructtree` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_config`
--

DROP TABLE IF EXISTS `hs_hr_config`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_config` (
  `key` varchar(100) NOT NULL default '',
  `value` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_config`
--

LOCK TABLES `hs_hr_config` WRITE;
/*!40000 ALTER TABLE `hs_hr_config` DISABLE KEYS */;
INSERT INTO `hs_hr_config` VALUES ('attendanceEmpChangeTime','No'),('attendanceEmpEditSubmitted','No'),('attendanceSupEditSubmitted','No'),('hsp_accrued_last_updated','0000-00-00'),('hsp_current_plan','0'),('hsp_used_last_updated','0000-00-00'),('ldap_domain_name',''),('ldap_port',''),('ldap_server',''),('ldap_status','');
/*!40000 ALTER TABLE `hs_hr_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_country`
--

DROP TABLE IF EXISTS `hs_hr_country`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_country` (
  `cou_code` char(2) NOT NULL default '',
  `name` varchar(80) NOT NULL default '',
  `cou_name` varchar(80) NOT NULL default '',
  `iso3` char(3) default NULL,
  `numcode` smallint(6) default NULL,
  PRIMARY KEY  (`cou_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_country`
--

LOCK TABLES `hs_hr_country` WRITE;
/*!40000 ALTER TABLE `hs_hr_country` DISABLE KEYS */;
INSERT INTO `hs_hr_country` VALUES ('AD','ANDORRA','Andorra','AND',20),('AE','UNITED ARAB EMIRATES','United Arab Emirates','ARE',784),('AF','AFGHANISTAN','Afghanistan','AFG',4),('AG','ANTIGUA AND BARBUDA','Antigua and Barbuda','ATG',28),('AI','ANGUILLA','Anguilla','AIA',660),('AL','ALBANIA','Albania','ALB',8),('AM','ARMENIA','Armenia','ARM',51),('AN','NETHERLANDS ANTILLES','Netherlands Antilles','ANT',530),('AO','ANGOLA','Angola','AGO',24),('AQ','ANTARCTICA','Antarctica',NULL,NULL),('AR','ARGENTINA','Argentina','ARG',32),('AS','AMERICAN SAMOA','American Samoa','ASM',16),('AT','AUSTRIA','Austria','AUT',40),('AU','AUSTRALIA','Australia','AUS',36),('AW','ARUBA','Aruba','ABW',533),('AZ','AZERBAIJAN','Azerbaijan','AZE',31),('BA','BOSNIA AND HERZEGOVINA','Bosnia and Herzegovina','BIH',70),('BB','BARBADOS','Barbados','BRB',52),('BD','BANGLADESH','Bangladesh','BGD',50),('BE','BELGIUM','Belgium','BEL',56),('BF','BURKINA FASO','Burkina Faso','BFA',854),('BG','BULGARIA','Bulgaria','BGR',100),('BH','BAHRAIN','Bahrain','BHR',48),('BI','BURUNDI','Burundi','BDI',108),('BJ','BENIN','Benin','BEN',204),('BM','BERMUDA','Bermuda','BMU',60),('BN','BRUNEI DARUSSALAM','Brunei Darussalam','BRN',96),('BO','BOLIVIA','Bolivia','BOL',68),('BR','BRAZIL','Brazil','BRA',76),('BS','BAHAMAS','Bahamas','BHS',44),('BT','BHUTAN','Bhutan','BTN',64),('BV','BOUVET ISLAND','Bouvet Island',NULL,NULL),('BW','BOTSWANA','Botswana','BWA',72),('BY','BELARUS','Belarus','BLR',112),('BZ','BELIZE','Belize','BLZ',84),('CA','CANADA','Canada','CAN',124),('CC','COCOS (KEELING) ISLANDS','Cocos (Keeling) Islands',NULL,NULL),('CD','CONGO, THE DEMOCRATIC REPUBLIC OF THE','Congo, the Democratic Republic of the','COD',180),('CF','CENTRAL AFRICAN REPUBLIC','Central African Republic','CAF',140),('CG','CONGO','Congo','COG',178),('CH','SWITZERLAND','Switzerland','CHE',756),('CI','COTE D\'IVOIRE','Cote D\'Ivoire','CIV',384),('CK','COOK ISLANDS','Cook Islands','COK',184),('CL','CHILE','Chile','CHL',152),('CM','CAMEROON','Cameroon','CMR',120),('CN','CHINA','China','CHN',156),('CO','COLOMBIA','Colombia','COL',170),('CR','COSTA RICA','Costa Rica','CRI',188),('CS','SERBIA AND MONTENEGRO','Serbia and Montenegro',NULL,NULL),('CU','CUBA','Cuba','CUB',192),('CV','CAPE VERDE','Cape Verde','CPV',132),('CX','CHRISTMAS ISLAND','Christmas Island',NULL,NULL),('CY','CYPRUS','Cyprus','CYP',196),('CZ','CZECH REPUBLIC','Czech Republic','CZE',203),('DE','GERMANY','Germany','DEU',276),('DJ','DJIBOUTI','Djibouti','DJI',262),('DK','DENMARK','Denmark','DNK',208),('DM','DOMINICA','Dominica','DMA',212),('DO','DOMINICAN REPUBLIC','Dominican Republic','DOM',214),('DZ','ALGERIA','Algeria','DZA',12),('EC','ECUADOR','Ecuador','ECU',218),('EE','ESTONIA','Estonia','EST',233),('EG','EGYPT','Egypt','EGY',818),('EH','WESTERN SAHARA','Western Sahara','ESH',732),('ER','ERITREA','Eritrea','ERI',232),('ES','SPAIN','Spain','ESP',724),('ET','ETHIOPIA','Ethiopia','ETH',231),('FI','FINLAND','Finland','FIN',246),('FJ','FIJI','Fiji','FJI',242),('FK','FALKLAND ISLANDS (MALVINAS)','Falkland Islands (Malvinas)','FLK',238),('FM','MICRONESIA, FEDERATED STATES OF','Micronesia, Federated States of','FSM',583),('FO','FAROE ISLANDS','Faroe Islands','FRO',234),('FR','FRANCE','France','FRA',250),('GA','GABON','Gabon','GAB',266),('GB','UNITED KINGDOM','United Kingdom','GBR',826),('GD','GRENADA','Grenada','GRD',308),('GE','GEORGIA','Georgia','GEO',268),('GF','FRENCH GUIANA','French Guiana','GUF',254),('GH','GHANA','Ghana','GHA',288),('GI','GIBRALTAR','Gibraltar','GIB',292),('GL','GREENLAND','Greenland','GRL',304),('GM','GAMBIA','Gambia','GMB',270),('GN','GUINEA','Guinea','GIN',324),('GP','GUADELOUPE','Guadeloupe','GLP',312),('GQ','EQUATORIAL GUINEA','Equatorial Guinea','GNQ',226),('GR','GREECE','Greece','GRC',300),('GS','SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS','South Georgia and the South Sandwich Islands',NULL,NULL),('GT','GUATEMALA','Guatemala','GTM',320),('GU','GUAM','Guam','GUM',316),('GW','GUINEA-BISSAU','Guinea-Bissau','GNB',624),('GY','GUYANA','Guyana','GUY',328),('HK','HONG KONG','Hong Kong','HKG',344),('HM','HEARD ISLAND AND MCDONALD ISLANDS','Heard Island and Mcdonald Islands',NULL,NULL),('HN','HONDURAS','Honduras','HND',340),('HR','CROATIA','Croatia','HRV',191),('HT','HAITI','Haiti','HTI',332),('HU','HUNGARY','Hungary','HUN',348),('ID','INDONESIA','Indonesia','IDN',360),('IE','IRELAND','Ireland','IRL',372),('IL','ISRAEL','Israel','ISR',376),('IN','INDIA','India','IND',356),('IO','BRITISH INDIAN OCEAN TERRITORY','British Indian Ocean Territory',NULL,NULL),('IQ','IRAQ','Iraq','IRQ',368),('IR','IRAN, ISLAMIC REPUBLIC OF','Iran, Islamic Republic of','IRN',364),('IS','ICELAND','Iceland','ISL',352),('IT','ITALY','Italy','ITA',380),('JM','JAMAICA','Jamaica','JAM',388),('JO','JORDAN','Jordan','JOR',400),('JP','JAPAN','Japan','JPN',392),('KE','KENYA','Kenya','KEN',404),('KG','KYRGYZSTAN','Kyrgyzstan','KGZ',417),('KH','CAMBODIA','Cambodia','KHM',116),('KI','KIRIBATI','Kiribati','KIR',296),('KM','COMOROS','Comoros','COM',174),('KN','SAINT KITTS AND NEVIS','Saint Kitts and Nevis','KNA',659),('KP','KOREA, DEMOCRATIC PEOPLE\'S REPUBLIC OF','Korea, Democratic People\'s Republic of','PRK',408),('KR','KOREA, REPUBLIC OF','Korea, Republic of','KOR',410),('KW','KUWAIT','Kuwait','KWT',414),('KY','CAYMAN ISLANDS','Cayman Islands','CYM',136),('KZ','KAZAKHSTAN','Kazakhstan','KAZ',398),('LA','LAO PEOPLE\'S DEMOCRATIC REPUBLIC','Lao People\'s Democratic Republic','LAO',418),('LB','LEBANON','Lebanon','LBN',422),('LC','SAINT LUCIA','Saint Lucia','LCA',662),('LI','LIECHTENSTEIN','Liechtenstein','LIE',438),('LK','SRI LANKA','Sri Lanka','LKA',144),('LR','LIBERIA','Liberia','LBR',430),('LS','LESOTHO','Lesotho','LSO',426),('LT','LITHUANIA','Lithuania','LTU',440),('LU','LUXEMBOURG','Luxembourg','LUX',442),('LV','LATVIA','Latvia','LVA',428),('LY','LIBYAN ARAB JAMAHIRIYA','Libyan Arab Jamahiriya','LBY',434),('MA','MOROCCO','Morocco','MAR',504),('MC','MONACO','Monaco','MCO',492),('MD','MOLDOVA, REPUBLIC OF','Moldova, Republic of','MDA',498),('MG','MADAGASCAR','Madagascar','MDG',450),('MH','MARSHALL ISLANDS','Marshall Islands','MHL',584),('MK','MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','Macedonia, the Former Yugoslav Republic of','MKD',807),('ML','MALI','Mali','MLI',466),('MM','MYANMAR','Myanmar','MMR',104),('MN','MONGOLIA','Mongolia','MNG',496),('MO','MACAO','Macao','MAC',446),('MP','NORTHERN MARIANA ISLANDS','Northern Mariana Islands','MNP',580),('MQ','MARTINIQUE','Martinique','MTQ',474),('MR','MAURITANIA','Mauritania','MRT',478),('MS','MONTSERRAT','Montserrat','MSR',500),('MT','MALTA','Malta','MLT',470),('MU','MAURITIUS','Mauritius','MUS',480),('MV','MALDIVES','Maldives','MDV',462),('MW','MALAWI','Malawi','MWI',454),('MX','MEXICO','Mexico','MEX',484),('MY','MALAYSIA','Malaysia','MYS',458),('MZ','MOZAMBIQUE','Mozambique','MOZ',508),('NA','NAMIBIA','Namibia','NAM',516),('NC','NEW CALEDONIA','New Caledonia','NCL',540),('NE','NIGER','Niger','NER',562),('NF','NORFOLK ISLAND','Norfolk Island','NFK',574),('NG','NIGERIA','Nigeria','NGA',566),('NI','NICARAGUA','Nicaragua','NIC',558),('NL','NETHERLANDS','Netherlands','NLD',528),('NO','NORWAY','Norway','NOR',578),('NP','NEPAL','Nepal','NPL',524),('NR','NAURU','Nauru','NRU',520),('NU','NIUE','Niue','NIU',570),('NZ','NEW ZEALAND','New Zealand','NZL',554),('OM','OMAN','Oman','OMN',512),('PA','PANAMA','Panama','PAN',591),('PE','PERU','Peru','PER',604),('PF','FRENCH POLYNESIA','French Polynesia','PYF',258),('PG','PAPUA NEW GUINEA','Papua New Guinea','PNG',598),('PH','PHILIPPINES','Philippines','PHL',608),('PK','PAKISTAN','Pakistan','PAK',586),('PL','POLAND','Poland','POL',616),('PM','SAINT PIERRE AND MIQUELON','Saint Pierre and Miquelon','SPM',666),('PN','PITCAIRN','Pitcairn','PCN',612),('PR','PUERTO RICO','Puerto Rico','PRI',630),('PS','PALESTINIAN TERRITORY, OCCUPIED','Palestinian Territory, Occupied',NULL,NULL),('PT','PORTUGAL','Portugal','PRT',620),('PW','PALAU','Palau','PLW',585),('PY','PARAGUAY','Paraguay','PRY',600),('QA','QATAR','Qatar','QAT',634),('RE','REUNION','Reunion','REU',638),('RO','ROMANIA','Romania','ROM',642),('RU','RUSSIAN FEDERATION','Russian Federation','RUS',643),('RW','RWANDA','Rwanda','RWA',646),('SA','SAUDI ARABIA','Saudi Arabia','SAU',682),('SB','SOLOMON ISLANDS','Solomon Islands','SLB',90),('SC','SEYCHELLES','Seychelles','SYC',690),('SD','SUDAN','Sudan','SDN',736),('SE','SWEDEN','Sweden','SWE',752),('SG','SINGAPORE','Singapore','SGP',702),('SH','SAINT HELENA','Saint Helena','SHN',654),('SI','SLOVENIA','Slovenia','SVN',705),('SJ','SVALBARD AND JAN MAYEN','Svalbard and Jan Mayen','SJM',744),('SK','SLOVAKIA','Slovakia','SVK',703),('SL','SIERRA LEONE','Sierra Leone','SLE',694),('SM','SAN MARINO','San Marino','SMR',674),('SN','SENEGAL','Senegal','SEN',686),('SO','SOMALIA','Somalia','SOM',706),('SR','SURINAME','Suriname','SUR',740),('ST','SAO TOME AND PRINCIPE','Sao Tome and Principe','STP',678),('SV','EL SALVADOR','El Salvador','SLV',222),('SY','SYRIAN ARAB REPUBLIC','Syrian Arab Republic','SYR',760),('SZ','SWAZILAND','Swaziland','SWZ',748),('TC','TURKS AND CAICOS ISLANDS','Turks and Caicos Islands','TCA',796),('TD','CHAD','Chad','TCD',148),('TF','FRENCH SOUTHERN TERRITORIES','French Southern Territories',NULL,NULL),('TG','TOGO','Togo','TGO',768),('TH','THAILAND','Thailand','THA',764),('TJ','TAJIKISTAN','Tajikistan','TJK',762),('TK','TOKELAU','Tokelau','TKL',772),('TL','TIMOR-LESTE','Timor-Leste',NULL,NULL),('TM','TURKMENISTAN','Turkmenistan','TKM',795),('TN','TUNISIA','Tunisia','TUN',788),('TO','TONGA','Tonga','TON',776),('TR','TURKEY','Turkey','TUR',792),('TT','TRINIDAD AND TOBAGO','Trinidad and Tobago','TTO',780),('TV','TUVALU','Tuvalu','TUV',798),('TW','TAIWAN, PROVINCE OF CHINA','Taiwan','TWN',158),('TZ','TANZANIA, UNITED REPUBLIC OF','Tanzania, United Republic of','TZA',834),('UA','UKRAINE','Ukraine','UKR',804),('UG','UGANDA','Uganda','UGA',800),('UM','UNITED STATES MINOR OUTLYING ISLANDS','United States Minor Outlying Islands',NULL,NULL),('US','UNITED STATES','United States','USA',840),('UY','URUGUAY','Uruguay','URY',858),('UZ','UZBEKISTAN','Uzbekistan','UZB',860),('VA','HOLY SEE (VATICAN CITY STATE)','Holy See (Vatican City State)','VAT',336),('VC','SAINT VINCENT AND THE GRENADINES','Saint Vincent and the Grenadines','VCT',670),('VE','VENEZUELA','Venezuela','VEN',862),('VG','VIRGIN ISLANDS, BRITISH','Virgin Islands, British','VGB',92),('VI','VIRGIN ISLANDS, U.S.','Virgin Islands, U.s.','VIR',850),('VN','VIET NAM','Viet Nam','VNM',704),('VU','VANUATU','Vanuatu','VUT',548),('WF','WALLIS AND FUTUNA','Wallis and Futuna','WLF',876),('WS','SAMOA','Samoa','WSM',882),('YE','YEMEN','Yemen','YEM',887),('YT','MAYOTTE','Mayotte',NULL,NULL),('ZA','SOUTH AFRICA','South Africa','ZAF',710),('ZM','ZAMBIA','Zambia','ZMB',894),('ZW','ZIMBABWE','Zimbabwe','ZWE',716);
/*!40000 ALTER TABLE `hs_hr_country` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_currency_type`
--

DROP TABLE IF EXISTS `hs_hr_currency_type`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_currency_type` (
  `code` int(11) NOT NULL default '0',
  `currency_id` char(3) NOT NULL default '',
  `currency_name` varchar(70) NOT NULL default '',
  PRIMARY KEY  (`currency_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_currency_type`
--

LOCK TABLES `hs_hr_currency_type` WRITE;
/*!40000 ALTER TABLE `hs_hr_currency_type` DISABLE KEYS */;
INSERT INTO `hs_hr_currency_type` VALUES (3,'AED','Utd. Arab Emir. Dirham'),(4,'AFN','Afghanistan Afghani'),(5,'ALL','Albanian Lek'),(6,'ANG','NL Antillian Guilder'),(7,'AOR','Angolan New Kwanza'),(177,'ARP','Argentina Pesos'),(8,'ARS','Argentine Peso'),(10,'AUD','Australian Dollar'),(11,'AWG','Aruban Florin'),(12,'BBD','Barbados Dollar'),(13,'BDT','Bangladeshi Taka'),(15,'BGL','Bulgarian Lev'),(16,'BHD','Bahraini Dinar'),(17,'BIF','Burundi Franc'),(18,'BMD','Bermudian Dollar'),(19,'BND','Brunei Dollar'),(20,'BOB','Bolivian Boliviano'),(21,'BRL','Brazilian Real'),(22,'BSD','Bahamian Dollar'),(23,'BTN','Bhutan Ngultrum'),(24,'BWP','Botswana Pula'),(25,'BZD','Belize Dollar'),(26,'CAD','Canadian Dollar'),(27,'CHF','Swiss Franc'),(28,'CLP','Chilean Peso'),(29,'CNY','Chinese Yuan Renminbi'),(30,'COP','Colombian Peso'),(31,'CRC','Costa Rican Colon'),(32,'CUP','Cuban Peso'),(33,'CVE','Cape Verde Escudo'),(34,'CYP','Cyprus Pound'),(171,'CZK','Czech Koruna'),(37,'DJF','Djibouti Franc'),(38,'DKK','Danish Krona'),(39,'DOP','Dominican Peso'),(40,'DZD','Algerian Dinar'),(41,'ECS','Ecuador Sucre'),(43,'EEK','Estonian Krona'),(44,'EGP','Egyptian Pound'),(46,'ETB','Ethiopian Birr'),(42,'EUR','Euro'),(48,'FJD','Fiji Dollar'),(49,'FKP','Falkland Islands Pound'),(51,'GBP','Pound Sterling'),(52,'GHC','Ghanaian Cedi'),(53,'GIP','Gibraltar Pound'),(54,'GMD','Gambian Dalasi'),(55,'GNF','Guinea Franc'),(57,'GTQ','Guatemalan Quetzal'),(58,'GYD','Guyanan Dollar'),(59,'HKD','Hong Kong Dollar'),(60,'HNL','Honduran Lempira'),(61,'HRK','Croatian Kuna'),(62,'HTG','Haitian Gourde'),(63,'HUF','Hungarian Forint'),(64,'IDR','Indonesian Rupiah'),(66,'ILS','Israeli New Shekel'),(67,'INR','Indian Rupee'),(68,'IQD','Iraqi Dinar'),(69,'IRR','Iranian Rial'),(70,'ISK','Iceland Krona'),(72,'JMD','Jamaican Dollar'),(73,'JOD','Jordanian Dinar'),(74,'JPY','Japanese Yen'),(75,'KES','Kenyan Shilling'),(76,'KHR','Kampuchean Riel'),(77,'KMF','Comoros Franc'),(78,'KPW','North Korean Won'),(79,'KRW','Korean Won'),(80,'KWD','Kuwaiti Dinar'),(81,'KYD','Cayman Islands Dollar'),(82,'KZT','Kazakhstan Tenge'),(83,'LAK','Lao Kip'),(84,'LBP','Lebanese Pound'),(85,'LKR','Sri Lanka Rupee'),(86,'LRD','Liberian Dollar'),(87,'LSL','Lesotho Loti'),(88,'LTL','Lithuanian Litas'),(90,'LVL','Latvian Lats'),(91,'LYD','Libyan Dinar'),(92,'MAD','Moroccan Dirham'),(93,'MGF','Malagasy Franc'),(94,'MMK','Myanmar Kyat'),(95,'MNT','Mongolian Tugrik'),(96,'MOP','Macau Pataca'),(97,'MRO','Mauritanian Ouguiya'),(98,'MTL','Maltese Lira'),(99,'MUR','Mauritius Rupee'),(100,'MVR','Maldive Rufiyaa'),(101,'MWK','Malawi Kwacha'),(102,'MXN','Mexican New Peso'),(172,'MXP','Mexican Peso'),(103,'MYR','Malaysian Ringgit'),(104,'MZM','Mozambique Metical'),(105,'NAD','Namibia Dollar'),(106,'NGN','Nigerian Naira'),(107,'NIO','Nicaraguan Cordoba Oro'),(109,'NOK','Norwegian Krona'),(110,'NPR','Nepalese Rupee'),(111,'NZD','New Zealand Dollar'),(112,'OMR','Omani Rial'),(113,'PAB','Panamanian Balboa'),(114,'PEN','Peruvian Nuevo Sol'),(115,'PGK','Papua New Guinea Kina'),(116,'PHP','Philippine Peso'),(117,'PKR','Pakistan Rupee'),(118,'PLN','Polish Zloty'),(120,'PYG','Paraguay Guarani'),(121,'QAR','Qatari Rial'),(122,'ROL','Romanian Leu'),(123,'RUB','Russian Rouble'),(180,'RUR','Russia Rubles'),(124,'SAR','South African Rand'),(125,'SBD','Solomon Islands Dollar'),(126,'SCR','Seychelles Rupee'),(127,'SDD','Sudanese Dinar'),(128,'SDP','Sudanese Pound'),(129,'SEK','Swedish Krona'),(131,'SGD','Singapore Dollar'),(132,'SHP','St. Helena Pound'),(130,'SKK','Slovak Koruna'),(135,'SLL','Sierra Leone Leone'),(136,'SOS','Somali Shilling'),(137,'SRG','Suriname Guilder'),(138,'STD','Sao Tome/Principe Dobra'),(139,'SVC','El Salvador Colon'),(140,'SYP','Syrian Pound'),(141,'SZL','Swaziland Lilangeni'),(142,'THB','Thai Baht'),(143,'TND','Tunisian Dinar'),(144,'TOP','Tongan Pa\'anga'),(145,'TRL','Turkish Lira'),(146,'TTD','Trinidad/Tobago Dollar'),(147,'TWD','Taiwan Dollar'),(148,'TZS','Tanzanian Shilling'),(149,'UAH','Ukraine Hryvnia'),(150,'UGX','Uganda Shilling'),(151,'USD','United States Dollar'),(152,'UYP','Uruguayan Peso'),(153,'VEB','Venezuelan Bolivar'),(154,'VND','Vietnamese Dong'),(155,'VUV','Vanuatu Vatu'),(156,'WST','Samoan Tala'),(158,'XAF','CFA Franc BEAC'),(159,'XAG','Silver (oz.)'),(160,'XAU','Gold (oz.)'),(161,'XCD','Eastern Caribbean Dollars'),(179,'XDR','IMF Special Drawing Right'),(162,'XOF','CFA Franc BCEAO'),(163,'XPD','Palladium (oz.)'),(164,'XPF','Franc des Comptoirs franÃ§ais du Pacifique'),(165,'XPT','Platinum (oz.)'),(166,'YER','Yemeni Riyal'),(167,'YUM','Yugoslavian Dinar'),(175,'YUN','Yugoslav Dinar'),(168,'ZAR','South African Rand'),(176,'ZMK','Zambian Kwacha'),(169,'ZRN','New Zaire'),(170,'ZWD','Zimbabwe Dollar');
/*!40000 ALTER TABLE `hs_hr_currency_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_custom_export`
--

DROP TABLE IF EXISTS `hs_hr_custom_export`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_custom_export` (
  `export_id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `fields` text,
  `headings` text,
  PRIMARY KEY  (`export_id`),
  KEY `emp_number` (`export_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_custom_export`
--

LOCK TABLES `hs_hr_custom_export` WRITE;
/*!40000 ALTER TABLE `hs_hr_custom_export` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_custom_export` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_custom_fields`
--

DROP TABLE IF EXISTS `hs_hr_custom_fields`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_custom_fields` (
  `field_num` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `type` int(11) NOT NULL,
  `extra_data` varchar(250) default NULL,
  PRIMARY KEY  (`field_num`),
  KEY `emp_number` (`field_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_custom_fields`
--

LOCK TABLES `hs_hr_custom_fields` WRITE;
/*!40000 ALTER TABLE `hs_hr_custom_fields` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_custom_fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_custom_import`
--

DROP TABLE IF EXISTS `hs_hr_custom_import`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_custom_import` (
  `import_id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `fields` text,
  `has_heading` tinyint(1) default '0',
  PRIMARY KEY  (`import_id`),
  KEY `emp_number` (`import_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_custom_import`
--

LOCK TABLES `hs_hr_custom_import` WRITE;
/*!40000 ALTER TABLE `hs_hr_custom_import` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_custom_import` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_customer`
--

DROP TABLE IF EXISTS `hs_hr_customer`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_customer` (
  `customer_id` int(11) NOT NULL,
  `name` varchar(100) default NULL,
  `description` varchar(250) default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_customer`
--

LOCK TABLES `hs_hr_customer` WRITE;
/*!40000 ALTER TABLE `hs_hr_customer` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_db_version`
--

DROP TABLE IF EXISTS `hs_hr_db_version`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_db_version` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(45) default NULL,
  `description` varchar(100) default NULL,
  `entered_date` datetime default NULL,
  `modified_date` datetime default NULL,
  `entered_by` varchar(36) default NULL,
  `modified_by` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `entered_by` (`entered_by`),
  KEY `modified_by` (`modified_by`),
  CONSTRAINT `hs_hr_db_version_ibfk_2` FOREIGN KEY (`modified_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_db_version_ibfk_1` FOREIGN KEY (`entered_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_db_version`
--

LOCK TABLES `hs_hr_db_version` WRITE;
/*!40000 ALTER TABLE `hs_hr_db_version` DISABLE KEYS */;
INSERT INTO `hs_hr_db_version` VALUES ('DVR001','mysql4.1','initial DB','2005-10-10 00:00:00','2005-12-20 00:00:00',NULL,NULL);
/*!40000 ALTER TABLE `hs_hr_db_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_developer`
--

DROP TABLE IF EXISTS `hs_hr_developer`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_developer` (
  `id` varchar(36) NOT NULL default '',
  `first_name` varchar(45) default NULL,
  `last_name` varchar(45) default NULL,
  `reports_to_id` varchar(45) default NULL,
  `description` varchar(200) default NULL,
  `department` varchar(45) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_developer`
--

LOCK TABLES `hs_hr_developer` WRITE;
/*!40000 ALTER TABLE `hs_hr_developer` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_developer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_district`
--

DROP TABLE IF EXISTS `hs_hr_district`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_district` (
  `district_code` varchar(13) NOT NULL default '',
  `district_name` varchar(50) default NULL,
  `province_code` varchar(13) default NULL,
  PRIMARY KEY  (`district_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_district`
--

LOCK TABLES `hs_hr_district` WRITE;
/*!40000 ALTER TABLE `hs_hr_district` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_district` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_education`
--

DROP TABLE IF EXISTS `hs_hr_education`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_education` (
  `edu_code` varchar(13) NOT NULL default '',
  `edu_uni` varchar(100) default NULL,
  `edu_deg` varchar(100) default NULL,
  PRIMARY KEY  (`edu_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_education`
--

LOCK TABLES `hs_hr_education` WRITE;
/*!40000 ALTER TABLE `hs_hr_education` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_education` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_eec`
--

DROP TABLE IF EXISTS `hs_hr_eec`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_eec` (
  `eec_code` varchar(13) NOT NULL default '',
  `eec_desc` varchar(50) default NULL,
  PRIMARY KEY  (`eec_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_eec`
--

LOCK TABLES `hs_hr_eec` WRITE;
/*!40000 ALTER TABLE `hs_hr_eec` DISABLE KEYS */;
INSERT INTO `hs_hr_eec` VALUES ('EEC001','OFFICIALS AND ADMINISTRATORS'),('EEC002','PROFESSIONALS'),('EEC003','TECHNICIANS'),('EEC004','PROTECTIVE SERVICE WORKERS'),('EEC005','PARAPROFESSIONALS'),('EEC006','ADMINISTRATIVE SUPPORT'),('EEC007','SKILLED CRAFT WORKERS'),('EEC008','SERVICE-MAINTENANCE');
/*!40000 ALTER TABLE `hs_hr_eec` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_attachment`
--

DROP TABLE IF EXISTS `hs_hr_emp_attachment`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_attachment` (
  `emp_number` int(7) NOT NULL default '0',
  `eattach_id` decimal(10,0) NOT NULL default '0',
  `eattach_desc` varchar(200) default NULL,
  `eattach_filename` varchar(100) default NULL,
  `eattach_size` int(11) default '0',
  `eattach_attachment` mediumblob,
  `eattach_type` varchar(50) default NULL,
  PRIMARY KEY  (`emp_number`,`eattach_id`),
  CONSTRAINT `hs_hr_emp_attachment_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_attachment`
--

LOCK TABLES `hs_hr_emp_attachment` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_attachment` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_attachment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_basicsalary`
--

DROP TABLE IF EXISTS `hs_hr_emp_basicsalary`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_basicsalary` (
  `emp_number` int(7) NOT NULL default '0',
  `sal_grd_code` varchar(13) NOT NULL default '',
  `currency_id` varchar(6) NOT NULL default '',
  `ebsal_basic_salary` varchar(100) character set latin1 default NULL,
  `payperiod_code` varchar(13) default NULL,
  PRIMARY KEY  (`emp_number`,`sal_grd_code`,`currency_id`),
  KEY `sal_grd_code` (`sal_grd_code`),
  KEY `currency_id` (`currency_id`),
  KEY `payperiod_code` (`payperiod_code`),
  CONSTRAINT `hs_hr_emp_basicsalary_ibfk_4` FOREIGN KEY (`payperiod_code`) REFERENCES `hs_hr_payperiod` (`payperiod_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_basicsalary_ibfk_1` FOREIGN KEY (`sal_grd_code`) REFERENCES `hs_pr_salary_grade` (`sal_grd_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_basicsalary_ibfk_2` FOREIGN KEY (`currency_id`) REFERENCES `hs_hr_currency_type` (`currency_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_basicsalary_ibfk_3` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_basicsalary`
--

LOCK TABLES `hs_hr_emp_basicsalary` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_basicsalary` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_basicsalary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_children`
--

DROP TABLE IF EXISTS `hs_hr_emp_children`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_children` (
  `emp_number` int(7) NOT NULL default '0',
  `ec_seqno` decimal(2,0) NOT NULL default '0',
  `ec_name` varchar(100) default '',
  `ec_date_of_birth` date default NULL,
  PRIMARY KEY  (`emp_number`,`ec_seqno`),
  CONSTRAINT `hs_hr_emp_children_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_children`
--

LOCK TABLES `hs_hr_emp_children` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_children` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_children` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_contract_extend`
--

DROP TABLE IF EXISTS `hs_hr_emp_contract_extend`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_contract_extend` (
  `emp_number` int(7) NOT NULL default '0',
  `econ_extend_id` decimal(10,0) NOT NULL default '0',
  `econ_extend_start_date` datetime default NULL,
  `econ_extend_end_date` datetime default NULL,
  PRIMARY KEY  (`emp_number`,`econ_extend_id`),
  CONSTRAINT `hs_hr_emp_contract_extend_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_contract_extend`
--

LOCK TABLES `hs_hr_emp_contract_extend` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_contract_extend` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_contract_extend` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_dependents`
--

DROP TABLE IF EXISTS `hs_hr_emp_dependents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_dependents` (
  `emp_number` int(7) NOT NULL default '0',
  `ed_seqno` decimal(2,0) NOT NULL default '0',
  `ed_name` varchar(100) default '',
  `ed_relationship` varchar(100) default '',
  PRIMARY KEY  (`emp_number`,`ed_seqno`),
  CONSTRAINT `hs_hr_emp_dependents_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_dependents`
--

LOCK TABLES `hs_hr_emp_dependents` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_dependents` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_dependents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_directdebit`
--

DROP TABLE IF EXISTS `hs_hr_emp_directdebit`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_directdebit` (
  `emp_number` int(7) NOT NULL default '0',
  `dd_seqno` decimal(2,0) NOT NULL default '0',
  `dd_routing_num` int(9) NOT NULL,
  `dd_account` varchar(100) NOT NULL default '',
  `dd_amount` decimal(11,2) NOT NULL,
  `dd_account_type` varchar(20) NOT NULL default '' COMMENT 'CHECKING, SAVINGS',
  `dd_transaction_type` varchar(20) NOT NULL default '' COMMENT 'BLANK, PERC, FLAT, FLATMINUS',
  PRIMARY KEY  (`emp_number`,`dd_seqno`),
  CONSTRAINT `hs_hr_emp_directdebit_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_directdebit`
--

LOCK TABLES `hs_hr_emp_directdebit` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_directdebit` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_directdebit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_education`
--

DROP TABLE IF EXISTS `hs_hr_emp_education`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_education` (
  `emp_number` int(7) NOT NULL default '0',
  `edu_code` varchar(13) NOT NULL default '',
  `edu_major` varchar(100) default NULL,
  `edu_year` decimal(4,0) default NULL,
  `edu_gpa` varchar(25) default NULL,
  `edu_start_date` datetime default NULL,
  `edu_end_date` datetime default NULL,
  PRIMARY KEY  (`edu_code`,`emp_number`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_emp_education_ibfk_2` FOREIGN KEY (`edu_code`) REFERENCES `hs_hr_education` (`edu_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_education_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_education`
--

LOCK TABLES `hs_hr_emp_education` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_education` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_education` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_emergency_contacts`
--

DROP TABLE IF EXISTS `hs_hr_emp_emergency_contacts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_emergency_contacts` (
  `emp_number` int(7) NOT NULL default '0',
  `eec_seqno` decimal(2,0) NOT NULL default '0',
  `eec_name` varchar(100) default '',
  `eec_relationship` varchar(100) default '',
  `eec_home_no` varchar(100) default '',
  `eec_mobile_no` varchar(100) default '',
  `eec_office_no` varchar(100) default '',
  PRIMARY KEY  (`emp_number`,`eec_seqno`),
  CONSTRAINT `hs_hr_emp_emergency_contacts_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_emergency_contacts`
--

LOCK TABLES `hs_hr_emp_emergency_contacts` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_emergency_contacts` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_emergency_contacts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_history_of_ealier_pos`
--

DROP TABLE IF EXISTS `hs_hr_emp_history_of_ealier_pos`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_history_of_ealier_pos` (
  `emp_number` int(7) NOT NULL default '0',
  `emp_seqno` decimal(2,0) NOT NULL default '0',
  `ehoep_job_title` varchar(100) default '',
  `ehoep_years` varchar(100) default '',
  PRIMARY KEY  (`emp_number`,`emp_seqno`),
  CONSTRAINT `hs_hr_emp_history_of_ealier_pos_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_history_of_ealier_pos`
--

LOCK TABLES `hs_hr_emp_history_of_ealier_pos` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_history_of_ealier_pos` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_history_of_ealier_pos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_jobtitle_history`
--

DROP TABLE IF EXISTS `hs_hr_emp_jobtitle_history`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_jobtitle_history` (
  `id` int(11) NOT NULL auto_increment,
  `emp_number` int(7) NOT NULL,
  `code` varchar(15) NOT NULL,
  `name` varchar(250) default NULL,
  `start_date` datetime default NULL,
  `end_date` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_emp_jobtitle_history_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_jobtitle_history`
--

LOCK TABLES `hs_hr_emp_jobtitle_history` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_jobtitle_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_jobtitle_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_language`
--

DROP TABLE IF EXISTS `hs_hr_emp_language`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_language` (
  `emp_number` int(7) NOT NULL default '0',
  `lang_code` varchar(13) NOT NULL default '',
  `elang_type` smallint(6) NOT NULL default '0',
  `competency` smallint(6) default '0',
  PRIMARY KEY  (`emp_number`,`lang_code`,`elang_type`),
  KEY `lang_code` (`lang_code`),
  CONSTRAINT `hs_hr_emp_language_ibfk_2` FOREIGN KEY (`lang_code`) REFERENCES `hs_hr_language` (`lang_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_language_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_language`
--

LOCK TABLES `hs_hr_emp_language` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_language` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_language` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_licenses`
--

DROP TABLE IF EXISTS `hs_hr_emp_licenses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_licenses` (
  `emp_number` int(7) NOT NULL default '0',
  `licenses_code` varchar(100) NOT NULL default '',
  `licenses_date` date default NULL,
  `licenses_renewal_date` date default NULL,
  PRIMARY KEY  (`emp_number`,`licenses_code`),
  KEY `licenses_code` (`licenses_code`),
  CONSTRAINT `hs_hr_emp_licenses_ibfk_2` FOREIGN KEY (`licenses_code`) REFERENCES `hs_hr_licenses` (`licenses_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_licenses_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_licenses`
--

LOCK TABLES `hs_hr_emp_licenses` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_licenses` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_licenses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_location_history`
--

DROP TABLE IF EXISTS `hs_hr_emp_location_history`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_location_history` (
  `id` int(11) NOT NULL auto_increment,
  `emp_number` int(7) NOT NULL,
  `code` varchar(15) NOT NULL,
  `name` varchar(250) default NULL,
  `start_date` datetime default NULL,
  `end_date` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_emp_location_history_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_location_history`
--

LOCK TABLES `hs_hr_emp_location_history` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_location_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_location_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_locations`
--

DROP TABLE IF EXISTS `hs_hr_emp_locations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_locations` (
  `emp_number` int(7) NOT NULL,
  `loc_code` varchar(13) NOT NULL,
  PRIMARY KEY  (`emp_number`,`loc_code`),
  KEY `loc_code` (`loc_code`),
  CONSTRAINT `hs_hr_emp_locations_ibfk_1` FOREIGN KEY (`loc_code`) REFERENCES `hs_hr_location` (`loc_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_locations_ibfk_2` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_locations`
--

LOCK TABLES `hs_hr_emp_locations` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_locations` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_member_detail`
--

DROP TABLE IF EXISTS `hs_hr_emp_member_detail`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_member_detail` (
  `emp_number` int(7) NOT NULL default '0',
  `membship_code` varchar(13) NOT NULL default '',
  `membtype_code` varchar(13) NOT NULL default '',
  `ememb_subscript_ownership` varchar(20) default NULL,
  `ememb_subscript_amount` decimal(15,2) default NULL,
  `ememb_commence_date` datetime default NULL,
  `ememb_renewal_date` datetime default NULL,
  PRIMARY KEY  (`emp_number`,`membship_code`,`membtype_code`),
  KEY `membtype_code` (`membtype_code`),
  KEY `membship_code` (`membship_code`),
  CONSTRAINT `hs_hr_emp_member_detail_ibfk_3` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_member_detail_ibfk_1` FOREIGN KEY (`membtype_code`) REFERENCES `hs_hr_membership_type` (`membtype_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_member_detail_ibfk_2` FOREIGN KEY (`membship_code`) REFERENCES `hs_hr_membership` (`membship_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_member_detail`
--

LOCK TABLES `hs_hr_emp_member_detail` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_member_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_member_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_passport`
--

DROP TABLE IF EXISTS `hs_hr_emp_passport`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_passport` (
  `emp_number` int(7) NOT NULL default '0',
  `ep_seqno` decimal(2,0) NOT NULL default '0',
  `ep_passport_num` varchar(100) NOT NULL default '',
  `ep_passportissueddate` datetime default NULL,
  `ep_passportexpiredate` datetime default NULL,
  `ep_comments` varchar(255) default NULL,
  `ep_passport_type_flg` smallint(6) default NULL,
  `ep_i9_status` varchar(100) default '',
  `ep_i9_review_date` date default NULL,
  `cou_code` varchar(6) default NULL,
  PRIMARY KEY  (`emp_number`,`ep_seqno`),
  CONSTRAINT `hs_hr_emp_passport_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_passport`
--

LOCK TABLES `hs_hr_emp_passport` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_passport` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_passport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_picture`
--

DROP TABLE IF EXISTS `hs_hr_emp_picture`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_picture` (
  `emp_number` int(7) NOT NULL default '0',
  `epic_picture` mediumblob,
  `epic_filename` varchar(100) default NULL,
  `epic_type` varchar(50) default NULL,
  `epic_file_size` varchar(20) default NULL,
  PRIMARY KEY  (`emp_number`),
  CONSTRAINT `hs_hr_emp_picture_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_picture`
--

LOCK TABLES `hs_hr_emp_picture` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_picture` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_picture` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_reportto`
--

DROP TABLE IF EXISTS `hs_hr_emp_reportto`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_reportto` (
  `erep_sup_emp_number` int(7) NOT NULL default '0',
  `erep_sub_emp_number` int(7) NOT NULL default '0',
  `erep_reporting_mode` smallint(6) NOT NULL default '0',
  PRIMARY KEY  (`erep_sup_emp_number`,`erep_sub_emp_number`,`erep_reporting_mode`),
  KEY `erep_sub_emp_number` (`erep_sub_emp_number`),
  CONSTRAINT `hs_hr_emp_reportto_ibfk_2` FOREIGN KEY (`erep_sub_emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_reportto_ibfk_1` FOREIGN KEY (`erep_sup_emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_reportto`
--

LOCK TABLES `hs_hr_emp_reportto` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_reportto` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_reportto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_skill`
--

DROP TABLE IF EXISTS `hs_hr_emp_skill`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_skill` (
  `emp_number` int(7) NOT NULL default '0',
  `skill_code` varchar(13) NOT NULL default '',
  `years_of_exp` decimal(2,0) NOT NULL default '0',
  `comments` varchar(100) NOT NULL default '',
  KEY `emp_number` (`emp_number`),
  KEY `skill_code` (`skill_code`),
  CONSTRAINT `hs_hr_emp_skill_ibfk_2` FOREIGN KEY (`skill_code`) REFERENCES `hs_hr_skill` (`skill_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emp_skill_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_skill`
--

LOCK TABLES `hs_hr_emp_skill` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_skill` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_skill` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_subdivision_history`
--

DROP TABLE IF EXISTS `hs_hr_emp_subdivision_history`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_subdivision_history` (
  `id` int(11) NOT NULL auto_increment,
  `emp_number` int(7) NOT NULL,
  `code` varchar(15) NOT NULL,
  `name` varchar(250) default NULL,
  `start_date` datetime default NULL,
  `end_date` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_emp_subdivision_history_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_subdivision_history`
--

LOCK TABLES `hs_hr_emp_subdivision_history` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_subdivision_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_subdivision_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_us_tax`
--

DROP TABLE IF EXISTS `hs_hr_emp_us_tax`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_us_tax` (
  `emp_number` int(7) NOT NULL default '0',
  `tax_federal_status` varchar(13) default NULL,
  `tax_federal_exceptions` int(2) default '0',
  `tax_state` varchar(13) default NULL,
  `tax_state_status` varchar(13) default NULL,
  `tax_state_exceptions` int(2) default '0',
  `tax_unemp_state` varchar(13) default NULL,
  `tax_work_state` varchar(13) default NULL,
  PRIMARY KEY  (`emp_number`),
  CONSTRAINT `hs_hr_emp_us_tax_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_us_tax`
--

LOCK TABLES `hs_hr_emp_us_tax` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_us_tax` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_us_tax` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emp_work_experience`
--

DROP TABLE IF EXISTS `hs_hr_emp_work_experience`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emp_work_experience` (
  `emp_number` int(7) NOT NULL default '0',
  `eexp_seqno` decimal(10,0) NOT NULL default '0',
  `eexp_employer` varchar(100) default NULL,
  `eexp_jobtit` varchar(120) default NULL,
  `eexp_from_date` datetime default NULL,
  `eexp_to_date` datetime default NULL,
  `eexp_comments` varchar(200) default NULL,
  `eexp_internal` int(1) default NULL,
  PRIMARY KEY  (`emp_number`,`eexp_seqno`),
  CONSTRAINT `hs_hr_emp_work_experience_ibfk_1` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emp_work_experience`
--

LOCK TABLES `hs_hr_emp_work_experience` WRITE;
/*!40000 ALTER TABLE `hs_hr_emp_work_experience` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emp_work_experience` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_employee`
--

DROP TABLE IF EXISTS `hs_hr_employee`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_employee` (
  `emp_number` int(7) NOT NULL default '0',
  `employee_id` varchar(50) default NULL,
  `emp_lastname` varchar(100) NOT NULL default '',
  `emp_firstname` varchar(100) NOT NULL default '',
  `emp_middle_name` varchar(100) NOT NULL default '',
  `emp_nick_name` varchar(100) default '',
  `emp_smoker` smallint(6) default '0',
  `ethnic_race_code` varchar(13) default NULL,
  `emp_birthday` date default NULL,
  `nation_code` varchar(13) default NULL,
  `emp_gender` smallint(6) default NULL,
  `emp_marital_status` varchar(20) default NULL,
  `emp_ssn_num` varchar(100) character set latin1 default '',
  `emp_sin_num` varchar(100) default '',
  `emp_other_id` varchar(100) default '',
  `emp_dri_lice_num` varchar(100) default '',
  `emp_dri_lice_exp_date` date default NULL,
  `emp_military_service` varchar(100) default '',
  `emp_status` varchar(13) default NULL,
  `job_title_code` varchar(13) default NULL,
  `eeo_cat_code` varchar(13) default NULL,
  `work_station` int(6) default NULL,
  `emp_street1` varchar(100) default '',
  `emp_street2` varchar(100) default '',
  `city_code` varchar(100) default '',
  `coun_code` varchar(100) default '',
  `provin_code` varchar(100) default '',
  `emp_zipcode` varchar(20) default NULL,
  `emp_hm_telephone` varchar(50) default NULL,
  `emp_mobile` varchar(50) default NULL,
  `emp_work_telephone` varchar(50) default NULL,
  `emp_work_email` varchar(50) default NULL,
  `sal_grd_code` varchar(13) default NULL,
  `joined_date` date default NULL,
  `emp_oth_email` varchar(50) default NULL,
  `terminated_date` date default NULL,
  `termination_reason` varchar(256) default NULL,
  `custom1` varchar(250) default NULL,
  `custom2` varchar(250) default NULL,
  `custom3` varchar(250) default NULL,
  `custom4` varchar(250) default NULL,
  `custom5` varchar(250) default NULL,
  `custom6` varchar(250) default NULL,
  `custom7` varchar(250) default NULL,
  `custom8` varchar(250) default NULL,
  `custom9` varchar(250) default NULL,
  `custom10` varchar(250) default NULL,
  PRIMARY KEY  (`emp_number`),
  UNIQUE KEY `employee_id` (`employee_id`),
  KEY `work_station` (`work_station`),
  KEY `ethnic_race_code` (`ethnic_race_code`),
  KEY `nation_code` (`nation_code`),
  KEY `job_title_code` (`job_title_code`),
  KEY `emp_status` (`emp_status`),
  KEY `eeo_cat_code` (`eeo_cat_code`),
  CONSTRAINT `hs_hr_employee_ibfk_6` FOREIGN KEY (`eeo_cat_code`) REFERENCES `hs_hr_eec` (`eec_code`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_employee_ibfk_1` FOREIGN KEY (`work_station`) REFERENCES `hs_hr_compstructtree` (`id`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_employee_ibfk_2` FOREIGN KEY (`ethnic_race_code`) REFERENCES `hs_hr_ethnic_race` (`ethnic_race_code`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_employee_ibfk_3` FOREIGN KEY (`nation_code`) REFERENCES `hs_hr_nationality` (`nat_code`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_employee_ibfk_4` FOREIGN KEY (`job_title_code`) REFERENCES `hs_hr_job_title` (`jobtit_code`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_employee_ibfk_5` FOREIGN KEY (`emp_status`) REFERENCES `hs_hr_empstat` (`estat_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_employee`
--

LOCK TABLES `hs_hr_employee` WRITE;
/*!40000 ALTER TABLE `hs_hr_employee` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_employee_leave_quota`
--

DROP TABLE IF EXISTS `hs_hr_employee_leave_quota`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_employee_leave_quota` (
  `year` year(4) NOT NULL,
  `leave_type_id` varchar(13) NOT NULL,
  `employee_id` int(7) NOT NULL,
  `no_of_days_allotted` decimal(6,2) default NULL,
  `leave_taken` decimal(6,2) default '0.00',
  `leave_brought_forward` decimal(6,2) default '0.00',
  PRIMARY KEY  (`leave_type_id`,`employee_id`,`year`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `hs_hr_employee_leave_quota_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_employee_leave_quota_ibfk_1` FOREIGN KEY (`leave_type_id`) REFERENCES `hs_hr_leavetype` (`leave_type_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_employee_leave_quota`
--

LOCK TABLES `hs_hr_employee_leave_quota` WRITE;
/*!40000 ALTER TABLE `hs_hr_employee_leave_quota` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_employee_leave_quota` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_employee_timesheet_period`
--

DROP TABLE IF EXISTS `hs_hr_employee_timesheet_period`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_employee_timesheet_period` (
  `timesheet_period_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  PRIMARY KEY  (`timesheet_period_id`,`employee_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `hs_hr_employee_timesheet_period_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_employee_timesheet_period_ibfk_2` FOREIGN KEY (`timesheet_period_id`) REFERENCES `hs_hr_timesheet_submission_period` (`timesheet_period_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_employee_timesheet_period`
--

LOCK TABLES `hs_hr_employee_timesheet_period` WRITE;
/*!40000 ALTER TABLE `hs_hr_employee_timesheet_period` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_employee_timesheet_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_employee_workshift`
--

DROP TABLE IF EXISTS `hs_hr_employee_workshift`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_employee_workshift` (
  `workshift_id` int(11) NOT NULL,
  `emp_number` int(11) NOT NULL,
  PRIMARY KEY  (`workshift_id`,`emp_number`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_employee_workshift_ibfk_1` FOREIGN KEY (`workshift_id`) REFERENCES `hs_hr_workshift` (`workshift_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_employee_workshift_ibfk_2` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_employee_workshift`
--

LOCK TABLES `hs_hr_employee_workshift` WRITE;
/*!40000 ALTER TABLE `hs_hr_employee_workshift` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_employee_workshift` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_emprep_usergroup`
--

DROP TABLE IF EXISTS `hs_hr_emprep_usergroup`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_emprep_usergroup` (
  `userg_id` varchar(13) NOT NULL default '',
  `rep_code` varchar(13) NOT NULL default '',
  PRIMARY KEY  (`userg_id`,`rep_code`),
  KEY `rep_code` (`rep_code`),
  CONSTRAINT `hs_hr_emprep_usergroup_ibfk_2` FOREIGN KEY (`rep_code`) REFERENCES `hs_hr_empreport` (`rep_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_emprep_usergroup_ibfk_1` FOREIGN KEY (`userg_id`) REFERENCES `hs_hr_user_group` (`userg_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_emprep_usergroup`
--

LOCK TABLES `hs_hr_emprep_usergroup` WRITE;
/*!40000 ALTER TABLE `hs_hr_emprep_usergroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_emprep_usergroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_empreport`
--

DROP TABLE IF EXISTS `hs_hr_empreport`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_empreport` (
  `rep_code` varchar(13) NOT NULL default '',
  `rep_name` varchar(60) default NULL,
  `rep_cridef_str` varchar(200) default NULL,
  `rep_flddef_str` varchar(200) default NULL,
  PRIMARY KEY  (`rep_code`),
  UNIQUE KEY `rep_name` (`rep_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_empreport`
--

LOCK TABLES `hs_hr_empreport` WRITE;
/*!40000 ALTER TABLE `hs_hr_empreport` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_empreport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_empstat`
--

DROP TABLE IF EXISTS `hs_hr_empstat`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_empstat` (
  `estat_code` varchar(13) NOT NULL default '',
  `estat_name` varchar(50) default NULL,
  PRIMARY KEY  (`estat_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_empstat`
--

LOCK TABLES `hs_hr_empstat` WRITE;
/*!40000 ALTER TABLE `hs_hr_empstat` DISABLE KEYS */;
INSERT INTO `hs_hr_empstat` VALUES ('EST000','Terminated'),('EST001','Full Time Contract'),('EST002','Full Time Internship'),('EST003','Full Time Permanent'),('EST004','Part Time Contract'),('EST005','Part Time Internship'),('EST006','Part Time Permanent');
/*!40000 ALTER TABLE `hs_hr_empstat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_ethnic_race`
--

DROP TABLE IF EXISTS `hs_hr_ethnic_race`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_ethnic_race` (
  `ethnic_race_code` varchar(13) NOT NULL default '',
  `ethnic_race_desc` varchar(50) default NULL,
  PRIMARY KEY  (`ethnic_race_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_ethnic_race`
--

LOCK TABLES `hs_hr_ethnic_race` WRITE;
/*!40000 ALTER TABLE `hs_hr_ethnic_race` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_ethnic_race` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_file_version`
--

DROP TABLE IF EXISTS `hs_hr_file_version`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_file_version` (
  `id` varchar(36) NOT NULL default '',
  `altered_module` varchar(36) default NULL,
  `description` varchar(200) default NULL,
  `entered_date` datetime default NULL,
  `modified_date` datetime default NULL,
  `entered_by` varchar(36) default NULL,
  `modified_by` varchar(36) default NULL,
  `name` varchar(50) default NULL,
  PRIMARY KEY  (`id`),
  KEY `altered_module` (`altered_module`),
  KEY `entered_by` (`entered_by`),
  KEY `modified_by` (`modified_by`),
  CONSTRAINT `hs_hr_file_version_ibfk_3` FOREIGN KEY (`modified_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_file_version_ibfk_1` FOREIGN KEY (`altered_module`) REFERENCES `hs_hr_module` (`mod_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_file_version_ibfk_2` FOREIGN KEY (`entered_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_file_version`
--

LOCK TABLES `hs_hr_file_version` WRITE;
/*!40000 ALTER TABLE `hs_hr_file_version` DISABLE KEYS */;
INSERT INTO `hs_hr_file_version` VALUES ('FVR001',NULL,'Release 1','2006-03-15 00:00:00','2006-03-15 00:00:00',NULL,NULL,'file_ver_01');
/*!40000 ALTER TABLE `hs_hr_file_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_geninfo`
--

DROP TABLE IF EXISTS `hs_hr_geninfo`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_geninfo` (
  `code` varchar(13) NOT NULL default '',
  `geninfo_keys` varchar(200) default NULL,
  `geninfo_values` varchar(800) default NULL,
  PRIMARY KEY  (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_geninfo`
--

LOCK TABLES `hs_hr_geninfo` WRITE;
/*!40000 ALTER TABLE `hs_hr_geninfo` DISABLE KEYS */;
INSERT INTO `hs_hr_geninfo` VALUES ('001','','');
/*!40000 ALTER TABLE `hs_hr_geninfo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_holidays`
--

DROP TABLE IF EXISTS `hs_hr_holidays`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_holidays` (
  `holiday_id` int(11) NOT NULL,
  `description` text,
  `date` date default NULL,
  `recurring` tinyint(1) default '0',
  `length` int(2) default NULL,
  UNIQUE KEY `holiday_id` (`holiday_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_holidays`
--

LOCK TABLES `hs_hr_holidays` WRITE;
/*!40000 ALTER TABLE `hs_hr_holidays` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_holidays` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_hsp`
--

DROP TABLE IF EXISTS `hs_hr_hsp`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_hsp` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `benefit_year` date default NULL,
  `hsp_value` decimal(10,2) NOT NULL,
  `total_acrued` decimal(10,2) NOT NULL,
  `accrued_last_updated` date default NULL,
  `amount_per_day` decimal(10,2) NOT NULL,
  `edited_status` tinyint(4) default '0',
  `termination_date` date default NULL,
  `halted` tinyint(4) default '0',
  `halted_date` date default NULL,
  `terminated` tinyint(4) default '0',
  PRIMARY KEY  (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `hs_hr_hsp_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_hsp`
--

LOCK TABLES `hs_hr_hsp` WRITE;
/*!40000 ALTER TABLE `hs_hr_hsp` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_hsp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_hsp_payment_request`
--

DROP TABLE IF EXISTS `hs_hr_hsp_payment_request`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_hsp_payment_request` (
  `id` int(11) NOT NULL,
  `hsp_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `date_incurred` date NOT NULL,
  `provider_name` varchar(100) default NULL,
  `person_incurring_expense` varchar(100) default NULL,
  `expense_description` varchar(250) default NULL,
  `expense_amount` decimal(10,2) NOT NULL,
  `payment_made_to` varchar(100) default NULL,
  `third_party_account_number` varchar(50) default NULL,
  `mail_address` varchar(250) default NULL,
  `comments` varchar(250) default NULL,
  `date_paid` date default NULL,
  `check_number` varchar(50) default NULL,
  `status` tinyint(4) default '0',
  `hr_notes` varchar(250) default NULL,
  PRIMARY KEY  (`id`),
  KEY `employee_id` (`employee_id`),
  KEY `hsp_id` (`hsp_id`),
  CONSTRAINT `hs_hr_hsp_payment_request_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_hsp_payment_request`
--

LOCK TABLES `hs_hr_hsp_payment_request` WRITE;
/*!40000 ALTER TABLE `hs_hr_hsp_payment_request` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_hsp_payment_request` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_hsp_summary`
--

DROP TABLE IF EXISTS `hs_hr_hsp_summary`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_hsp_summary` (
  `summary_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `hsp_plan_id` tinyint(2) NOT NULL,
  `hsp_plan_year` int(6) NOT NULL,
  `hsp_plan_status` tinyint(2) NOT NULL default '0',
  `annual_limit` decimal(10,2) NOT NULL default '0.00',
  `employer_amount` decimal(10,2) NOT NULL default '0.00',
  `employee_amount` decimal(10,2) NOT NULL default '0.00',
  `total_accrued` decimal(10,2) NOT NULL default '0.00',
  `total_used` decimal(10,2) NOT NULL default '0.00',
  PRIMARY KEY  (`summary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_hsp_summary`
--

LOCK TABLES `hs_hr_hsp_summary` WRITE;
/*!40000 ALTER TABLE `hs_hr_hsp_summary` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_hsp_summary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_job_application`
--

DROP TABLE IF EXISTS `hs_hr_job_application`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_job_application` (
  `application_id` int(11) NOT NULL,
  `vacancy_id` int(11) NOT NULL,
  `lastname` varchar(100) NOT NULL default '',
  `firstname` varchar(100) NOT NULL default '',
  `middlename` varchar(100) NOT NULL default '',
  `street1` varchar(100) default '',
  `street2` varchar(100) default '',
  `city` varchar(100) default '',
  `country_code` varchar(100) default '',
  `province` varchar(100) default '',
  `zip` varchar(20) default NULL,
  `phone` varchar(50) default NULL,
  `mobile` varchar(50) default NULL,
  `email` varchar(50) default NULL,
  `qualifications` text,
  `status` smallint(2) default '0',
  `applied_datetime` datetime default NULL,
  `emp_number` int(7) default NULL,
  `resume_name` varchar(100) default NULL,
  `resume_data` mediumblob,
  PRIMARY KEY  (`application_id`),
  KEY `vacancy_id` (`vacancy_id`),
  CONSTRAINT `hs_hr_job_application_ibfk_1` FOREIGN KEY (`vacancy_id`) REFERENCES `hs_hr_job_vacancy` (`vacancy_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_job_application`
--

LOCK TABLES `hs_hr_job_application` WRITE;
/*!40000 ALTER TABLE `hs_hr_job_application` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_job_application` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_job_application_events`
--

DROP TABLE IF EXISTS `hs_hr_job_application_events`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_job_application_events` (
  `id` int(11) NOT NULL,
  `application_id` int(11) NOT NULL,
  `created_time` datetime default NULL,
  `created_by` varchar(36) default NULL,
  `owner` int(7) default NULL,
  `event_time` datetime default NULL,
  `event_type` smallint(2) default NULL,
  `status` smallint(2) default '0',
  `notes` text,
  PRIMARY KEY  (`id`),
  KEY `application_id` (`application_id`),
  KEY `created_by` (`created_by`),
  KEY `owner` (`owner`),
  CONSTRAINT `hs_hr_job_application_events_ibfk_1` FOREIGN KEY (`application_id`) REFERENCES `hs_hr_job_application` (`application_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_job_application_events_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_job_application_events_ibfk_3` FOREIGN KEY (`owner`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_job_application_events`
--

LOCK TABLES `hs_hr_job_application_events` WRITE;
/*!40000 ALTER TABLE `hs_hr_job_application_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_job_application_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_job_spec`
--

DROP TABLE IF EXISTS `hs_hr_job_spec`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_job_spec` (
  `jobspec_id` int(11) NOT NULL default '0',
  `jobspec_name` varchar(50) default NULL,
  `jobspec_desc` text,
  `jobspec_duties` text,
  PRIMARY KEY  (`jobspec_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_job_spec`
--

LOCK TABLES `hs_hr_job_spec` WRITE;
/*!40000 ALTER TABLE `hs_hr_job_spec` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_job_spec` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_job_title`
--

DROP TABLE IF EXISTS `hs_hr_job_title`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_job_title` (
  `jobtit_code` varchar(13) NOT NULL default '',
  `jobtit_name` varchar(50) default NULL,
  `jobtit_desc` varchar(200) default NULL,
  `jobtit_comm` varchar(400) default NULL,
  `sal_grd_code` varchar(13) default NULL,
  `jobspec_id` int(11) default NULL,
  PRIMARY KEY  (`jobtit_code`),
  KEY `sal_grd_code` (`sal_grd_code`),
  KEY `jobspec_id` (`jobspec_id`),
  CONSTRAINT `hs_hr_job_title_ibfk_2` FOREIGN KEY (`jobspec_id`) REFERENCES `hs_hr_job_spec` (`jobspec_id`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_job_title_ibfk_1` FOREIGN KEY (`sal_grd_code`) REFERENCES `hs_pr_salary_grade` (`sal_grd_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_job_title`
--

LOCK TABLES `hs_hr_job_title` WRITE;
/*!40000 ALTER TABLE `hs_hr_job_title` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_job_title` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_job_vacancy`
--

DROP TABLE IF EXISTS `hs_hr_job_vacancy`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_job_vacancy` (
  `vacancy_id` int(11) NOT NULL,
  `jobtit_code` varchar(13) default NULL,
  `manager_id` int(7) default NULL,
  `active` tinyint(1) NOT NULL default '0',
  `description` text,
  PRIMARY KEY  (`vacancy_id`),
  KEY `jobtit_code` (`jobtit_code`),
  KEY `manager_id` (`manager_id`),
  CONSTRAINT `hs_hr_job_vacancy_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_job_vacancy_ibfk_2` FOREIGN KEY (`jobtit_code`) REFERENCES `hs_hr_job_title` (`jobtit_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_job_vacancy`
--

LOCK TABLES `hs_hr_job_vacancy` WRITE;
/*!40000 ALTER TABLE `hs_hr_job_vacancy` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_job_vacancy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_jobtit_empstat`
--

DROP TABLE IF EXISTS `hs_hr_jobtit_empstat`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_jobtit_empstat` (
  `jobtit_code` varchar(13) NOT NULL default '',
  `estat_code` varchar(13) NOT NULL default '',
  PRIMARY KEY  (`jobtit_code`,`estat_code`),
  KEY `estat_code` (`estat_code`),
  CONSTRAINT `hs_hr_jobtit_empstat_ibfk_2` FOREIGN KEY (`estat_code`) REFERENCES `hs_hr_empstat` (`estat_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_jobtit_empstat_ibfk_1` FOREIGN KEY (`jobtit_code`) REFERENCES `hs_hr_job_title` (`jobtit_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_jobtit_empstat`
--

LOCK TABLES `hs_hr_jobtit_empstat` WRITE;
/*!40000 ALTER TABLE `hs_hr_jobtit_empstat` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_jobtit_empstat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_language`
--

DROP TABLE IF EXISTS `hs_hr_language`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_language` (
  `lang_code` varchar(13) NOT NULL default '',
  `lang_name` varchar(120) default NULL,
  PRIMARY KEY  (`lang_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_language`
--

LOCK TABLES `hs_hr_language` WRITE;
/*!40000 ALTER TABLE `hs_hr_language` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_language` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_leave`
--

DROP TABLE IF EXISTS `hs_hr_leave`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_leave` (
  `leave_id` int(11) NOT NULL,
  `leave_date` date default NULL,
  `leave_length_hours` decimal(6,2) unsigned default NULL,
  `leave_length_days` decimal(4,2) unsigned default NULL,
  `leave_status` smallint(6) default NULL,
  `leave_comments` varchar(256) default NULL,
  `leave_request_id` int(11) NOT NULL,
  `leave_type_id` varchar(13) NOT NULL,
  `employee_id` int(7) NOT NULL,
  `start_time` time default NULL,
  `end_time` time default NULL,
  PRIMARY KEY  (`leave_id`,`leave_request_id`,`leave_type_id`,`employee_id`),
  KEY `leave_request_id` (`leave_request_id`,`leave_type_id`,`employee_id`),
  KEY `leave_type_id` (`leave_type_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `hs_hr_leave_ibfk_1` FOREIGN KEY (`leave_request_id`, `leave_type_id`, `employee_id`) REFERENCES `hs_hr_leave_requests` (`leave_request_id`, `leave_type_id`, `employee_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_leave`
--

LOCK TABLES `hs_hr_leave` WRITE;
/*!40000 ALTER TABLE `hs_hr_leave` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_leave` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_leave_requests`
--

DROP TABLE IF EXISTS `hs_hr_leave_requests`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_leave_requests` (
  `leave_request_id` int(11) NOT NULL,
  `leave_type_id` varchar(13) NOT NULL,
  `leave_type_name` char(20) default NULL,
  `date_applied` date NOT NULL,
  `employee_id` int(7) NOT NULL,
  PRIMARY KEY  (`leave_request_id`,`leave_type_id`,`employee_id`),
  KEY `employee_id` (`employee_id`),
  KEY `leave_type_id` (`leave_type_id`),
  CONSTRAINT `hs_hr_leave_requests_ibfk_2` FOREIGN KEY (`leave_type_id`) REFERENCES `hs_hr_leavetype` (`leave_type_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_leave_requests_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_leave_requests`
--

LOCK TABLES `hs_hr_leave_requests` WRITE;
/*!40000 ALTER TABLE `hs_hr_leave_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_leave_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_leavetype`
--

DROP TABLE IF EXISTS `hs_hr_leavetype`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_leavetype` (
  `leave_type_id` varchar(13) NOT NULL,
  `leave_type_name` varchar(20) default NULL,
  `available_flag` smallint(6) default NULL,
  PRIMARY KEY  (`leave_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_leavetype`
--

LOCK TABLES `hs_hr_leavetype` WRITE;
/*!40000 ALTER TABLE `hs_hr_leavetype` DISABLE KEYS */;
INSERT INTO `hs_hr_leavetype` VALUES ('LTY001','Casual',1),('LTY002','Medical',1);
/*!40000 ALTER TABLE `hs_hr_leavetype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_licenses`
--

DROP TABLE IF EXISTS `hs_hr_licenses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_licenses` (
  `licenses_code` varchar(13) NOT NULL default '',
  `licenses_desc` varchar(50) default NULL,
  PRIMARY KEY  (`licenses_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_licenses`
--

LOCK TABLES `hs_hr_licenses` WRITE;
/*!40000 ALTER TABLE `hs_hr_licenses` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_licenses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_location`
--

DROP TABLE IF EXISTS `hs_hr_location`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_location` (
  `loc_code` varchar(13) NOT NULL default '',
  `loc_name` varchar(100) default NULL,
  `loc_country` varchar(3) default NULL,
  `loc_state` varchar(50) default NULL,
  `loc_city` varchar(50) default NULL,
  `loc_add` varchar(100) default NULL,
  `loc_zip` varchar(10) default NULL,
  `loc_phone` varchar(30) default NULL,
  `loc_fax` varchar(30) default NULL,
  `loc_comments` varchar(100) default NULL,
  PRIMARY KEY  (`loc_code`),
  KEY `loc_country` (`loc_country`),
  CONSTRAINT `hs_hr_location_ibfk_1` FOREIGN KEY (`loc_country`) REFERENCES `hs_hr_country` (`cou_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_location`
--

LOCK TABLES `hs_hr_location` WRITE;
/*!40000 ALTER TABLE `hs_hr_location` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_mailnotifications`
--

DROP TABLE IF EXISTS `hs_hr_mailnotifications`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_mailnotifications` (
  `user_id` varchar(36) NOT NULL,
  `notification_type_id` int(11) NOT NULL,
  `status` int(2) NOT NULL,
  KEY `user_id` (`user_id`),
  KEY `notification_type_id` (`notification_type_id`),
  CONSTRAINT `hs_hr_mailnotifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_mailnotifications`
--

LOCK TABLES `hs_hr_mailnotifications` WRITE;
/*!40000 ALTER TABLE `hs_hr_mailnotifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_mailnotifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_membership`
--

DROP TABLE IF EXISTS `hs_hr_membership`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_membership` (
  `membship_code` varchar(13) NOT NULL default '',
  `membtype_code` varchar(13) default NULL,
  `membship_name` varchar(120) default NULL,
  PRIMARY KEY  (`membship_code`),
  KEY `membtype_code` (`membtype_code`),
  CONSTRAINT `hs_hr_membership_ibfk_1` FOREIGN KEY (`membtype_code`) REFERENCES `hs_hr_membership_type` (`membtype_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_membership`
--

LOCK TABLES `hs_hr_membership` WRITE;
/*!40000 ALTER TABLE `hs_hr_membership` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_membership` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_membership_type`
--

DROP TABLE IF EXISTS `hs_hr_membership_type`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_membership_type` (
  `membtype_code` varchar(13) NOT NULL default '',
  `membtype_name` varchar(120) default NULL,
  PRIMARY KEY  (`membtype_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_membership_type`
--

LOCK TABLES `hs_hr_membership_type` WRITE;
/*!40000 ALTER TABLE `hs_hr_membership_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_membership_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_module`
--

DROP TABLE IF EXISTS `hs_hr_module`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_module` (
  `mod_id` varchar(36) NOT NULL default '',
  `name` varchar(45) default NULL,
  `owner` varchar(45) default NULL,
  `owner_email` varchar(100) default NULL,
  `version` varchar(36) default NULL,
  `description` text,
  PRIMARY KEY  (`mod_id`),
  KEY `version` (`version`),
  CONSTRAINT `hs_hr_module_ibfk_1` FOREIGN KEY (`version`) REFERENCES `hs_hr_versions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_module`
--

LOCK TABLES `hs_hr_module` WRITE;
/*!40000 ALTER TABLE `hs_hr_module` DISABLE KEYS */;
INSERT INTO `hs_hr_module` VALUES ('MOD001','Admin','Koshika','koshika@beyondm.net','VER001','HR Admin'),('MOD002','PIM','Koshika','koshika@beyondm.net','VER001','HR Functions'),('MOD004','Report','Koshika','koshika@beyondm.net','VER001','Reporting'),('MOD005','Leave','Mohanjith','mohanjith@beyondm.net','VER001','Leave Tracking'),('MOD006','Time','Mohanjith','mohanjith@orangehrm.com','VER001','Time Tracking'),('MOD007','Benefits','Gayanath','gayanath@orangehrm.com','VER001','Benefits Tracking'),('MOD008','Recruitment','OrangeHRM','info@orangehrm.com','VER001','Recruitment');
/*!40000 ALTER TABLE `hs_hr_module` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_nationality`
--

DROP TABLE IF EXISTS `hs_hr_nationality`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_nationality` (
  `nat_code` varchar(13) NOT NULL default '',
  `nat_name` varchar(120) default NULL,
  PRIMARY KEY  (`nat_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_nationality`
--

LOCK TABLES `hs_hr_nationality` WRITE;
/*!40000 ALTER TABLE `hs_hr_nationality` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_nationality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_pay_period`
--

DROP TABLE IF EXISTS `hs_hr_pay_period`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_pay_period` (
  `id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `close_date` date NOT NULL,
  `check_date` date NOT NULL,
  `timesheet_aproval_due_date` date NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_pay_period`
--

LOCK TABLES `hs_hr_pay_period` WRITE;
/*!40000 ALTER TABLE `hs_hr_pay_period` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_pay_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_payperiod`
--

DROP TABLE IF EXISTS `hs_hr_payperiod`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_payperiod` (
  `payperiod_code` varchar(13) NOT NULL default '',
  `payperiod_name` varchar(100) default NULL,
  PRIMARY KEY  (`payperiod_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_payperiod`
--

LOCK TABLES `hs_hr_payperiod` WRITE;
/*!40000 ALTER TABLE `hs_hr_payperiod` DISABLE KEYS */;
INSERT INTO `hs_hr_payperiod` VALUES ('1','Weekly'),('2','Bi Weekly'),('3','Semi Monthly'),('4','Monthly'),('5','Monthly on first pay of month.');
/*!40000 ALTER TABLE `hs_hr_payperiod` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_project`
--

DROP TABLE IF EXISTS `hs_hr_project`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_project` (
  `project_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `name` varchar(100) default NULL,
  `description` varchar(250) default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`project_id`,`customer_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `hs_hr_project_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `hs_hr_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_project`
--

LOCK TABLES `hs_hr_project` WRITE;
/*!40000 ALTER TABLE `hs_hr_project` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_project_activity`
--

DROP TABLE IF EXISTS `hs_hr_project_activity`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_project_activity` (
  `activity_id` int(11) NOT NULL,
  `project_id` int(11) NOT NULL,
  `name` varchar(100) default NULL,
  `deleted` tinyint(1) default '0',
  PRIMARY KEY  (`activity_id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `hs_hr_project_activity_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `hs_hr_project` (`project_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_project_activity`
--

LOCK TABLES `hs_hr_project_activity` WRITE;
/*!40000 ALTER TABLE `hs_hr_project_activity` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_project_activity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_project_admin`
--

DROP TABLE IF EXISTS `hs_hr_project_admin`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_project_admin` (
  `project_id` int(11) NOT NULL,
  `emp_number` int(11) NOT NULL,
  PRIMARY KEY  (`project_id`,`emp_number`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_project_admin_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `hs_hr_project` (`project_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_project_admin_ibfk_2` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_project_admin`
--

LOCK TABLES `hs_hr_project_admin` WRITE;
/*!40000 ALTER TABLE `hs_hr_project_admin` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_project_admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_province`
--

DROP TABLE IF EXISTS `hs_hr_province`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_province` (
  `id` int(11) NOT NULL auto_increment,
  `province_name` varchar(40) NOT NULL default '',
  `province_code` char(2) NOT NULL default '',
  `cou_code` char(2) NOT NULL default 'us',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_province`
--

LOCK TABLES `hs_hr_province` WRITE;
/*!40000 ALTER TABLE `hs_hr_province` DISABLE KEYS */;
INSERT INTO `hs_hr_province` VALUES (1,'Alaska','AK','US'),(2,'Alabama','AL','US'),(3,'American Samoa','AS','US'),(4,'Arizona','AZ','US'),(5,'Arkansas','AR','US'),(6,'California','CA','US'),(7,'Colorado','CO','US'),(8,'Connecticut','CT','US'),(9,'Delaware','DE','US'),(10,'District of Columbia','DC','US'),(11,'Federated States of Micronesia','FM','US'),(12,'Florida','FL','US'),(13,'Georgia','GA','US'),(14,'Guam','GU','US'),(15,'Hawaii','HI','US'),(16,'Idaho','ID','US'),(17,'Illinois','IL','US'),(18,'Indiana','IN','US'),(19,'Iowa','IA','US'),(20,'Kansas','KS','US'),(21,'Kentucky','KY','US'),(22,'Louisiana','LA','US'),(23,'Maine','ME','US'),(24,'Marshall Islands','MH','US'),(25,'Maryland','MD','US'),(26,'Massachusetts','MA','US'),(27,'Michigan','MI','US'),(28,'Minnesota','MN','US'),(29,'Mississippi','MS','US'),(30,'Missouri','MO','US'),(31,'Montana','MT','US'),(32,'Nebraska','NE','US'),(33,'Nevada','NV','US'),(34,'New Hampshire','NH','US'),(35,'New Jersey','NJ','US'),(36,'New Mexico','NM','US'),(37,'New York','NY','US'),(38,'North Carolina','NC','US'),(39,'North Dakota','ND','US'),(40,'Northern Mariana Islands','MP','US'),(41,'Ohio','OH','US'),(42,'Oklahoma','OK','US'),(43,'Oregon','OR','US'),(44,'Palau','PW','US'),(45,'Pennsylvania','PA','US'),(46,'Puerto Rico','PR','US'),(47,'Rhode Island','RI','US'),(48,'South Carolina','SC','US'),(49,'South Dakota','SD','US'),(50,'Tennessee','TN','US'),(51,'Texas','TX','US'),(52,'Utah','UT','US'),(53,'Vermont','VT','US'),(54,'Virgin Islands','VI','US'),(55,'Virginia','VA','US'),(56,'Washington','WA','US'),(57,'West Virginia','WV','US'),(58,'Wisconsin','WI','US'),(59,'Wyoming','WY','US'),(60,'Armed Forces Africa','AE','US'),(61,'Armed Forces Americas (except Canada)','AA','US'),(62,'Armed Forces Canada','AE','US'),(63,'Armed Forces Europe','AE','US'),(64,'Armed Forces Middle East','AE','US'),(65,'Armed Forces Pacific','AP','US');
/*!40000 ALTER TABLE `hs_hr_province` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_rights`
--

DROP TABLE IF EXISTS `hs_hr_rights`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_rights` (
  `userg_id` varchar(36) NOT NULL default '',
  `mod_id` varchar(36) NOT NULL default '',
  `addition` smallint(5) unsigned default '0',
  `editing` smallint(5) unsigned default '0',
  `deletion` smallint(5) unsigned default '0',
  `viewing` smallint(5) unsigned default '0',
  PRIMARY KEY  (`mod_id`,`userg_id`),
  KEY `userg_id` (`userg_id`),
  CONSTRAINT `hs_hr_rights_ibfk_2` FOREIGN KEY (`userg_id`) REFERENCES `hs_hr_user_group` (`userg_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_rights_ibfk_1` FOREIGN KEY (`mod_id`) REFERENCES `hs_hr_module` (`mod_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_rights`
--

LOCK TABLES `hs_hr_rights` WRITE;
/*!40000 ALTER TABLE `hs_hr_rights` DISABLE KEYS */;
INSERT INTO `hs_hr_rights` VALUES ('USG001','MOD001',1,1,1,1),('USG001','MOD002',1,1,1,1),('USG001','MOD004',1,1,1,1),('USG001','MOD005',1,1,1,1),('USG001','MOD006',1,1,1,1),('USG001','MOD007',1,1,1,1),('USG001','MOD008',1,1,1,1);
/*!40000 ALTER TABLE `hs_hr_rights` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_skill`
--

DROP TABLE IF EXISTS `hs_hr_skill`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_skill` (
  `skill_code` varchar(13) NOT NULL default '',
  `skill_name` varchar(120) default NULL,
  `skill_description` text,
  PRIMARY KEY  (`skill_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_skill`
--

LOCK TABLES `hs_hr_skill` WRITE;
/*!40000 ALTER TABLE `hs_hr_skill` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_skill` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_time_event`
--

DROP TABLE IF EXISTS `hs_hr_time_event`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_time_event` (
  `time_event_id` int(11) NOT NULL,
  `project_id` int(11) NOT NULL,
  `activity_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `timesheet_id` int(11) NOT NULL,
  `start_time` datetime default NULL,
  `end_time` datetime default NULL,
  `reported_date` datetime default NULL,
  `duration` int(11) default NULL,
  `description` varchar(250) default NULL,
  PRIMARY KEY  (`time_event_id`,`project_id`,`employee_id`,`timesheet_id`),
  KEY `project_id` (`project_id`),
  KEY `activity_id` (`activity_id`),
  KEY `employee_id` (`employee_id`),
  KEY `timesheet_id` (`timesheet_id`),
  CONSTRAINT `hs_hr_time_event_ibfk_1` FOREIGN KEY (`timesheet_id`) REFERENCES `hs_hr_timesheet` (`timesheet_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_time_event_ibfk_2` FOREIGN KEY (`activity_id`) REFERENCES `hs_hr_project_activity` (`activity_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_time_event_ibfk_3` FOREIGN KEY (`project_id`) REFERENCES `hs_hr_project` (`project_id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_time_event_ibfk_4` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_time_event`
--

LOCK TABLES `hs_hr_time_event` WRITE;
/*!40000 ALTER TABLE `hs_hr_time_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_time_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_timesheet`
--

DROP TABLE IF EXISTS `hs_hr_timesheet`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_timesheet` (
  `timesheet_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `timesheet_period_id` int(11) NOT NULL,
  `start_date` datetime default NULL,
  `end_date` datetime default NULL,
  `status` int(11) default NULL,
  `comment` varchar(250) default NULL,
  PRIMARY KEY  (`timesheet_id`,`employee_id`,`timesheet_period_id`),
  KEY `employee_id` (`employee_id`),
  KEY `timesheet_period_id` (`timesheet_period_id`),
  CONSTRAINT `hs_hr_timesheet_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_timesheet_ibfk_2` FOREIGN KEY (`timesheet_period_id`) REFERENCES `hs_hr_timesheet_submission_period` (`timesheet_period_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_timesheet`
--

LOCK TABLES `hs_hr_timesheet` WRITE;
/*!40000 ALTER TABLE `hs_hr_timesheet` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_timesheet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_timesheet_submission_period`
--

DROP TABLE IF EXISTS `hs_hr_timesheet_submission_period`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_timesheet_submission_period` (
  `timesheet_period_id` int(11) NOT NULL,
  `name` varchar(100) default NULL,
  `frequency` int(11) NOT NULL,
  `period` int(11) default '1',
  `start_day` int(11) default NULL,
  `end_day` int(11) default NULL,
  `description` varchar(250) default NULL,
  PRIMARY KEY  (`timesheet_period_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_timesheet_submission_period`
--

LOCK TABLES `hs_hr_timesheet_submission_period` WRITE;
/*!40000 ALTER TABLE `hs_hr_timesheet_submission_period` DISABLE KEYS */;
INSERT INTO `hs_hr_timesheet_submission_period` VALUES (1,'week',7,1,0,6,'Weekly');
/*!40000 ALTER TABLE `hs_hr_timesheet_submission_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_unique_id`
--

DROP TABLE IF EXISTS `hs_hr_unique_id`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_unique_id` (
  `id` int(11) NOT NULL auto_increment,
  `last_id` int(10) unsigned NOT NULL,
  `table_name` varchar(50) NOT NULL,
  `field_name` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `table_field` (`table_name`,`field_name`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_unique_id`
--

LOCK TABLES `hs_hr_unique_id` WRITE;
/*!40000 ALTER TABLE `hs_hr_unique_id` DISABLE KEYS */;
INSERT INTO `hs_hr_unique_id` VALUES (1,0,'hs_hr_nationality','nat_code'),(2,0,'hs_hr_language','lang_code'),(3,0,'hs_hr_customer','customer_id'),(4,0,'hs_hr_job_title','jobtit_code'),(5,6,'hs_hr_empstat','estat_code'),(6,8,'hs_hr_eec','eec_code'),(7,0,'hs_hr_licenses','licenses_code'),(8,0,'hs_hr_employee','emp_number'),(9,0,'hs_hr_location','loc_code'),(10,0,'hs_hr_membership','membship_code'),(11,0,'hs_hr_membership_type','membtype_code'),(12,8,'hs_hr_module','mod_id'),(13,0,'hs_hr_education','edu_code'),(14,0,'hs_hr_ethnic_race','ethnic_race_code'),(15,0,'hs_hr_skill','skill_code'),(16,1,'hs_hr_user_group','userg_id'),(17,1,'hs_hr_users','id'),(18,0,'hs_pr_salary_grade','sal_grd_code'),(19,0,'hs_hr_empreport','rep_code'),(20,0,'hs_hr_leave','leave_id'),(21,2,'hs_hr_leavetype','leave_type_id'),(22,0,'hs_hr_holidays','holiday_id'),(23,0,'hs_hr_project','project_id'),(24,0,'hs_hr_timesheet','timesheet_id'),(25,0,'hs_hr_timesheet_submission_period','timesheet_period_id'),(26,0,'hs_hr_time_event','time_event_id'),(27,1,'hs_hr_compstructtree','id'),(28,0,'hs_hr_leave_requests','leave_request_id'),(29,0,'hs_hr_project_activity','activity_id'),(30,0,'hs_hr_workshift','workshift_id'),(31,0,'hs_hr_custom_export','export_id'),(32,0,'hs_hr_custom_import','import_id'),(33,0,'hs_hr_pay_period','id'),(34,0,'hs_hr_hsp_summary','summary_id'),(35,0,'hs_hr_hsp_payment_request','id'),(36,0,'hs_hr_job_spec','jobspec_id'),(37,0,'hs_hr_job_vacancy','vacancy_id'),(38,0,'hs_hr_job_application','application_id'),(39,0,'hs_hr_job_application_events','id'),(40,0,'hs_hr_attendance','attendance_id');
/*!40000 ALTER TABLE `hs_hr_unique_id` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_user_group`
--

DROP TABLE IF EXISTS `hs_hr_user_group`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_user_group` (
  `userg_id` varchar(36) NOT NULL default '',
  `userg_name` varchar(45) default NULL,
  `userg_repdef` smallint(5) unsigned default '0',
  PRIMARY KEY  (`userg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_user_group`
--

LOCK TABLES `hs_hr_user_group` WRITE;
/*!40000 ALTER TABLE `hs_hr_user_group` DISABLE KEYS */;
INSERT INTO `hs_hr_user_group` VALUES ('USG001','Admin',1);
/*!40000 ALTER TABLE `hs_hr_user_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_users`
--

DROP TABLE IF EXISTS `hs_hr_users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_users` (
  `id` varchar(36) NOT NULL default '',
  `user_name` varchar(40) default '',
  `user_password` varchar(40) default NULL,
  `first_name` varchar(45) default NULL,
  `last_name` varchar(45) default NULL,
  `emp_number` int(7) default NULL,
  `user_hash` varchar(32) default NULL,
  `is_admin` char(3) default NULL,
  `receive_notification` char(1) default NULL,
  `description` text,
  `date_entered` datetime default NULL,
  `date_modified` datetime default NULL,
  `modified_user_id` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `title` varchar(50) default NULL,
  `department` varchar(50) default NULL,
  `phone_home` varchar(45) default NULL,
  `phone_mobile` varchar(45) default NULL,
  `phone_work` varchar(45) default NULL,
  `phone_other` varchar(45) default NULL,
  `phone_fax` varchar(45) default NULL,
  `email1` varchar(100) default NULL,
  `email2` varchar(100) default NULL,
  `status` varchar(25) default NULL,
  `address_street` varchar(150) default NULL,
  `address_city` varchar(150) default NULL,
  `address_state` varchar(100) default NULL,
  `address_country` varchar(25) default NULL,
  `address_postalcode` varchar(10) default NULL,
  `user_preferences` text,
  `deleted` tinyint(1) NOT NULL default '0',
  `employee_status` varchar(25) default NULL,
  `userg_id` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `user_name` USING BTREE (`user_name`),
  KEY `modified_user_id` (`modified_user_id`),
  KEY `created_by` (`created_by`),
  KEY `userg_id` (`userg_id`),
  KEY `emp_number` (`emp_number`),
  CONSTRAINT `hs_hr_users_ibfk_4` FOREIGN KEY (`emp_number`) REFERENCES `hs_hr_employee` (`emp_number`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_users_ibfk_1` FOREIGN KEY (`modified_user_id`) REFERENCES `hs_hr_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_users_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `hs_hr_users_ibfk_3` FOREIGN KEY (`userg_id`) REFERENCES `hs_hr_user_group` (`userg_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_users`
--

LOCK TABLES `hs_hr_users` WRITE;
/*!40000 ALTER TABLE `hs_hr_users` DISABLE KEYS */;
-- INSERT INTO `hs_hr_users` VALUES ('USR001','Admin','e3afed0047b08059d0fada10f400c1e5','Admin','',NULL,'','Yes','1','',NULL,NULL,NULL,NULL,'','','','','','','','','','Enabled','','','','','','',0,'','USG001');
INSERT INTO `hs_hr_users` VALUES ('USR001','Admin', md5('[-ORANGEHRM_ADMIN_PASSWORD-]'),'Admin','',NULL,'','Yes','1','',NULL,NULL,NULL,NULL,'','','','','','','','','','Enabled','','','','','','',0,'','USG001');
/*!40000 ALTER TABLE `hs_hr_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_versions`
--

DROP TABLE IF EXISTS `hs_hr_versions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_versions` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(45) default NULL,
  `entered_date` datetime default NULL,
  `modified_date` datetime default NULL,
  `modified_by` varchar(36) default NULL,
  `created_by` varchar(36) default NULL,
  `deleted` tinyint(4) NOT NULL default '0',
  `db_version` varchar(36) default NULL,
  `file_version` varchar(36) default NULL,
  `description` text,
  PRIMARY KEY  (`id`),
  KEY `modified_by` (`modified_by`),
  KEY `created_by` (`created_by`),
  KEY `db_version` (`db_version`),
  KEY `file_version` (`file_version`),
  CONSTRAINT `hs_hr_versions_ibfk_4` FOREIGN KEY (`file_version`) REFERENCES `hs_hr_file_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_versions_ibfk_1` FOREIGN KEY (`modified_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_versions_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `hs_hr_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hs_hr_versions_ibfk_3` FOREIGN KEY (`db_version`) REFERENCES `hs_hr_db_version` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_versions`
--

LOCK TABLES `hs_hr_versions` WRITE;
/*!40000 ALTER TABLE `hs_hr_versions` DISABLE KEYS */;
INSERT INTO `hs_hr_versions` VALUES ('VER001','Release 1','2006-03-15 00:00:00','2006-03-15 00:00:00',NULL,NULL,0,'DVR001','FVR001','version 1.0');
/*!40000 ALTER TABLE `hs_hr_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_weekends`
--

DROP TABLE IF EXISTS `hs_hr_weekends`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_weekends` (
  `day` int(2) NOT NULL,
  `length` int(2) NOT NULL,
  UNIQUE KEY `day` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_weekends`
--

LOCK TABLES `hs_hr_weekends` WRITE;
/*!40000 ALTER TABLE `hs_hr_weekends` DISABLE KEYS */;
INSERT INTO `hs_hr_weekends` VALUES (1,0),(2,0),(3,0),(4,0),(5,0),(6,8),(7,8);
/*!40000 ALTER TABLE `hs_hr_weekends` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_hr_workshift`
--

DROP TABLE IF EXISTS `hs_hr_workshift`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_hr_workshift` (
  `workshift_id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `hours_per_day` decimal(4,2) NOT NULL,
  PRIMARY KEY  (`workshift_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_hr_workshift`
--

LOCK TABLES `hs_hr_workshift` WRITE;
/*!40000 ALTER TABLE `hs_hr_workshift` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_hr_workshift` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_pr_salary_currency_detail`
--

DROP TABLE IF EXISTS `hs_pr_salary_currency_detail`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_pr_salary_currency_detail` (
  `sal_grd_code` varchar(13) NOT NULL default '',
  `currency_id` varchar(6) NOT NULL default '',
  `salcurr_dtl_minsalary` double default NULL,
  `salcurr_dtl_stepsalary` double default NULL,
  `salcurr_dtl_maxsalary` double default NULL,
  PRIMARY KEY  (`sal_grd_code`,`currency_id`),
  KEY `currency_id` (`currency_id`),
  CONSTRAINT `hs_pr_salary_currency_detail_ibfk_2` FOREIGN KEY (`sal_grd_code`) REFERENCES `hs_pr_salary_grade` (`sal_grd_code`) ON DELETE CASCADE,
  CONSTRAINT `hs_pr_salary_currency_detail_ibfk_1` FOREIGN KEY (`currency_id`) REFERENCES `hs_hr_currency_type` (`currency_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_pr_salary_currency_detail`
--

LOCK TABLES `hs_pr_salary_currency_detail` WRITE;
/*!40000 ALTER TABLE `hs_pr_salary_currency_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_pr_salary_currency_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_pr_salary_grade`
--

DROP TABLE IF EXISTS `hs_pr_salary_grade`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hs_pr_salary_grade` (
  `sal_grd_code` varchar(13) NOT NULL default '',
  `sal_grd_name` varchar(60) default NULL,
  PRIMARY KEY  (`sal_grd_code`),
  UNIQUE KEY `sal_grd_name` (`sal_grd_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hs_pr_salary_grade`
--

LOCK TABLES `hs_pr_salary_grade` WRITE;
/*!40000 ALTER TABLE `hs_pr_salary_grade` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_pr_salary_grade` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-11-14 20:07:54
