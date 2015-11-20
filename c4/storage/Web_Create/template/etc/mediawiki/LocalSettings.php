<?php

# This file was automatically generated by the MediaWiki installer.
# If you make manual changes, please keep track in case you need to
# recreate them later.
#
# See includes/DefaultSettings.php for all configurable settings
# and their default values, but don't forget to make changes in _this_
# file, not there.
#
# Further documentation for configuration settings may be found at:
# http://www.mediawiki.org/wiki/Manual:Configuration_settings

# If you customize your file layout, set $IP to the directory that contains
# the other MediaWiki files. It will be used as a base to locate files.

# We define this to allow the configuration file to be explicitly 
# located in /etc/mediawiki.
# Change this if you are setting up multisite wikis on your server.
define('MW_INSTALL_PATH','/var/lib/mediawiki');

if( defined( 'MW_INSTALL_PATH' ) ) {
	$IP = MW_INSTALL_PATH;
} else {
	$IP = dirname( __FILE__ );
}

$path = array( $IP, "$IP/includes", "$IP/languages" );
set_include_path( implode( PATH_SEPARATOR, $path ) . PATH_SEPARATOR . get_include_path() );

require_once( "$IP/includes/DefaultSettings.php" );

# If PHP's memory limit is very low, some operations may fail.
# ini_set( 'memory_limit', '20M' );

if ( $wgCommandLineMode ) {
	if ( isset( $_SERVER ) && array_key_exists( 'REQUEST_METHOD', $_SERVER ) ) {
		die( "This script must be run from the command line\n" );
	}
}
## Uncomment this to disable output compression
# $wgDisableOutputCompression = true;

$wgSitename         = "Wiki";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs please see:
## http://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath       = "";
$wgScriptExtension  = ".php";

## UPO means: this is also a user preference option

$wgEnableEmail      = true;
$wgEnableUserEmail  = true; # UPO

$wgEmergencyContact = "webmaster@[-DOMAIN-]";
$wgPasswordSender = "webmaster@[-DOMAIN-]";

$wgEnotifUserTalk = true; # UPO
$wgEnotifWatchlist = true; # UPO
$wgEmailAuthentication = false;

## Database settings
$wgDBtype           = "postgres";
$wgDBserver         = "pgsql.[-DOMAIN-]";
$wgDBname           = "wikidb";
$wgDBuser           = "wikiuser";
$wgDBpassword       = "[-DB_PASSWORD_WIKI-]";

# Postgres specific settings
$wgDBport           = "5432";
$wgDBmwschema       = "mediawiki";
$wgDBts2schema      = "public";

## Shared memory settings
$wgMainCacheType = CACHE_NONE;
$wgMemCachedServers = array();

## To enable image uploads, make sure the 'images' directory
## is writable, then set this to true:
$wgEnableUploads       = true;
$wgUseImageResize      = true;
# $wgUseImageMagick = true;
# $wgImageMagickConvertCommand = "/usr/bin/convert";

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "en_US.utf8";

## If you want to use image uploads under safe mode,
## create the directories images/archive, images/thumb and
## images/temp, and make them all writable. Then uncomment
## this, if it's not already uncommented:
# $wgHashedUploadDirectory = false;

## If you have the appropriate support software installed
## you can enable inline LaTeX equations:
$wgUseTeX           = false;

$wgLocalInterwiki   = strtolower( $wgSitename );

$wgLanguageCode = "en";

$wgSecretKey = "a919fa48931148cdf0c664f39673bf92fbcba690523c04b38bcbf20ce1c5c45d";

## Default skin: you can change the default skin. Use the internal symbolic
## names, ie 'standard', 'nostalgia', 'cologneblue', 'monobook':
$wgDefaultSkin = 'monobook';

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.
# $wgEnableCreativeCommonsRdf = true;
$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl = "";
$wgRightsText = "";
$wgRightsIcon = "";
# $wgRightsCode = ""; # Not yet used

$wgDiff3 = "/usr/bin/diff3";

# debian specific include:
if (is_file("/etc/mediawiki-extensions/extensions.php")) {
        include( "/etc/mediawiki-extensions/extensions.php" );
}

# When you make changes to this configuration file, this will make
# sure that cached pages are cleared.
$wgCacheEpoch = max( $wgCacheEpoch, gmdate( 'YmdHis', @filemtime( __FILE__ ) ) );

# Eseri specific settings
$wgLogo             = "$wgUploadPath/eseri-logo.png";

$wgDefaultSkin = "modern";

$wgSMTP = array( 
 'host'     => "smtp.[-DOMAIN-]",
 'IDHost'   => "[-DOMAIN-]",
 'port'     => 10026,
 'auth'     => false,
 'username' => "",
 'password' => ""
);

$wgSysopUserBans = true; # Allow sysops to ban logged-in users
$wgSysopRangeBans = true; # Allow sysops to ban IP ranges
$wgAutoblockExpiry = 86400; # Number of seconds before autoblock entries expire
$wgBlockAllowsUTEdit = false; # Blocks allow users to edit their own user talk page
$wgGroupPermissions['*'    ]['createaccount']   = false;
$wgGroupPermissions['*'    ]['read']            = true;
$wgGroupPermissions['*'    ]['edit']            = false;
$wgGroupPermissions['*'    ]['createpage']      = false;
$wgGroupPermissions['*'    ]['createtalk']      = false;

# Debug purposes
#$wgShowExceptionDetails = true;

# Timezone
$wgLocaltimezone = "[-TIMEZONE-]";
$oldtz = getenv("TZ");
putenv("TZ=$wgLocaltimezone");
# Versions before 1.7.0 used $wgLocalTZoffset as hours.
# After 1.7.0 offset as minutes
$wgLocalTZoffset = date("Z") / 60;
putenv("TZ=$oldtz");

$wgRightsPage = "MediaWiki:Copyright";

# Kerberos & LDAP GSSAPI Authentication
require_once("AuthPlugin.php");
require_once( "$IP/extensions/LdapAutoAuthentication.php" );
require_once( "$IP/extensions/LdapAuthentication.php" );

$wgLDAPDomainNames = array("customer");
$wgLDAPServerNames = array("customer"=>"aphrodite.[-DOMAIN-]");
$wgLDAPEncryptionType = array("customer"  => "ssl");
$wgLDAPProxyAgent = array("customer" => "cn=mediawiki,ou=applications,ou=system,[-LDAP_BASE_DN-]");
$wgLDAPProxyAgentPassword = array("customer" => "[-LDAP_PASSWORD_WIKI-]");
$wgLDAPBaseDNs = array("customer" => "[-LDAP_BASE_DN-]");
$wgLDAPSearchAttributes = array("customer"=>"uid");
$wgLDAPAutoAuthDomain = "customer";
$wgLDAPAutoAuthUsername = preg_replace( '/@.*/', '', $_SERVER["REMOTE_USER"] );
$wgLDAPPreferences = array("customer"=>array( "email"=>"mail","realname"=>"displayname","nickname"=>"cn","language"=>"preferredLanguage"));
$wgAutoCreateFirstUserAsBureaucrat = true;

#$wgLDAPDebug=4;

AutoAuthSetup();

#require_once("$IP/extensions/Renameuser/SpecialRenameuser.php");

#require_once( "$IP/extensions/UserMerge/UserMerge.php" );
#$wgGroupPermissions['bureaucrat']['usermerge'] = true;

#optional - default is array( 'sysop' )
#$wgUserMergeProtectedGroups = array( 'groupname' );
?>
