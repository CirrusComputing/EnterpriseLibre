<?php
class Conf {

	var $smtphost;
	var $dbhost;
	var $dbport;
	var $dbname;
	var $dbuser;
	var $version;

	function Conf() {

		$this->dbhost	= 'mysql.[-DOMAIN-]';
		$this->dbport 	= '3306';
		$this->dbname	= 'orangehrm';
		$this->dbuser	= 'orangehrm';
		$this->dbpass	= '[-DB_PASSWORD_ORANGEHRM-]';
		$this->version = '2.4.0.1';

		$this->emailConfiguration = dirname(__FILE__).'/mailConf.php';
		$this->errorLog =  realpath(dirname(__FILE__).'/../logs/').'/';
	}
}
?>
