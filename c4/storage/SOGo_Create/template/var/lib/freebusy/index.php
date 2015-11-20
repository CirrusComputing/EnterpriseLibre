<?php
if(isset($_GET['u'])) {
	// create a new cURL resource
	$user = $_GET['u'];
	$ch = curl_init();
	$username="system-freebusy";
	$password="[-SOGO_PASSWORD_FREEBUSY-]";

	// set URL and other appropriate options
	curl_setopt($ch, CURLOPT_URL, "http://webmail.[-DOMAIN-]/SOGo/dav/$user/freebusy.ifb");
	curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
	curl_setopt($ch,CURLOPT_USERPWD,"$username:$password");

	// grab URL and pass it to the browser
	header('content-type: text/calendar');
	curl_exec($ch);

	// close cURL resource, and free up system resources
	curl_close($ch);
}
else {
	header( 'Location: /SOGo/so/' ) ;
}
?>
