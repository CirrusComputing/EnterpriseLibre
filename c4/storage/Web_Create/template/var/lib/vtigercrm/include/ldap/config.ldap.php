<?php
/*+**********************************************************************************
 * The contents of this file are subject to the vtiger CRM Public License Version 1.0
 * ("License"); You may not use this file except in compliance with the License
 * The Original Code is:  vtiger CRM Open Source
 * The Initial Developer of the Original Code is vtiger.
 * Portions created by vtiger are Copyright (C) vtiger.
 * All Rights Reserved.
 * @Contributor - Elmue 2008
 ************************************************************************************/

// Login Type may be: 'LDAP' or 'AD' or 'SQL'
// 'SQL' is the default (native) login method used by vtiger
// 'LDAP' is used by openLDAP or Active Directory
// 'AD' is not implemented yet, therefore use 'LDAP'
$AUTHCFG['authType']      = 'LDAP';

// ----------- Configuration LDAP -------------
$AUTHCFG['ldap_host']     = 'ldaps://aphrodite.[-DOMAIN-]'; //localhost, IP, hostname, FQHN, etc...
$AUTHCFG['ldap_port']     = '636'; //port of the ldap service

// The LDAP branch which stores the User Information
// This branch may have subfolders. PHP will search in all subfolders.
$AUTHCFG['ldap_basedn']   = 'ou=people,[-LDAP_BASE_DN-]';

// The account on the LDAP server which has permissions to read the branch specified in ldap_basedn
// If using an account outside the ldap_basedn to search in LDAP (for ex. a read only account), uncomment the next line
$AUTHCFG['ldap_username'] = 'cn=vtiger,ou=applications,ou=system,[-LDAP_BASE_DN-]';
// if the above line is uncommented, comment out the next line by adding // to the beginning
//$AUTHCFG['ldap_username'] = 'mydomainname\\username';   // set = NULL if not required
$AUTHCFG['ldap_pass']     = '[-LDAP_PASSWORD_VTIGER-]'; // set = NULL if not required

// Predefined LDAP fields (these settings work on Win 2003 Domain Controler)
$AUTHCFG['ldap_objclass']    = 'objectClass';
//samAccountName works with AD and is just the username (no domain included) for ldap_account
//userPrincipalName works with AD2003+ and newer LDAP and the username is username@domain for ldap_account
$AUTHCFG['ldap_account']     = 'uid';
$AUTHCFG['ldap_forename']    = 'givenName';
$AUTHCFG['ldap_lastname']    = 'sn';
$AUTHCFG['ldap_fullname']    = 'cn'; // or "name" or "displayName"
$AUTHCFG['ldap_email']       = 'mail';
$AUTHCFG['ldap_tel_work']    = 'telephoneNumber';
$AUTHCFG['ldap_mobile']      = 'mobile';
$AUTHCFG['ldap_fax']         = 'facsimileTelephoneNumber';
$AUTHCFG['ldap_home_phone']  = 'homePhone';
$AUTHCFG['ldap_other_phone'] = 'otherTelephone';
$AUTHCFG['ldap_department']  = 'department';
$AUTHCFG['ldap_description'] = 'notes';
$AUTHCFG['ldap_title']       = 'title';
$AUTHCFG['ldap_street_address'] = 'streetAddress';
$AUTHCFG['ldap_city']        = 'l'; //city
$AUTHCFG['ldap_state_province'] = 'st'; //state or province
$AUTHCFG['ldap_postalcode']  = 'postalCode'; //zip code
//'c' is the abbreviated country name, 'co' is the full country name, 'countryCode' is the numerical value of the countryCode
$AUTHCFG['ldap_countrycode'] = 'co';
$AUTHCFG['sql_accounts']     = array("admin");  //the users whose authentication will be from database instead of from ldap

// Required to search users: the array defined in ldap_objclass must contain at least one of the following values
$AUTHCFG['ldap_userfilter']  = 'user|person|organizationalPerson|account';

// ------------ Configuration AD (Active Directory) --------------

$AUTHCFG['ad_accountSuffix'] = '@localhost.localdomain';
$AUTHCFG['ad_basedn']        = 'DC=localhost,DC=localdomain';
$AUTHCFG['ad_dc']            = array ( "dc.localhost.localdomain" ); //array of domain controllers
$AUTHCFG['ad_username']      = NULL; //optional user/pass for searching
$AUTHCFG['ad_pass']          = NULL;
$AUTHCFG['ad_realgroup']     = true; //AD does not return the primary group.  Setting this to false will fudge "Domain Users" and is much faster.  True will resolve the real primary group, but may be resource intensive.

// #########################################################################
?>
