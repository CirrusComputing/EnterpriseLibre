<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'pgsql.[-DOMAIN-]';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodle';
$CFG->dbpass    = '[-DB_PASSWORD_MOODLE-]';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => 5432,
  'dbsocket' => '',
);

// Added so that domain config option 2.3 works
if (isset($_SERVER['HTTP_HOST'])) { $CFG->wwwroot = 'http://'.$_SERVER['HTTP_HOST']; }

$CFG->dataroot  = '/var/lib/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

require_once(dirname(__FILE__) . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

// Added so that moodle doesn't show update notifications - Nimesh Jethwa 01/08/2014
$CFG->disableupdatenotifications = true;
