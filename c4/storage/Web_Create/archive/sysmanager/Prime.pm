package CirrusOpen::AccountManager::Model::Prime;

use strict;
use warnings;
use parent 'Catalyst::Model::DBI';

sub isAdmin{
	my ($self, $username) = @_;
	my $dbh = $self->dbh;
	#Split the username into a Kerberos realm plus username
	my ($user, $realm) = split(/@/, $username);
	#Get the db id of the user
	if($user eq "eseriman/admin"){
		return (1);
	}
	else{
		my $user_id_result = $dbh->selectall_arrayref("SELECT id FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) AND username = ?", {}, (lc($realm), $user));
		my $user_id = @{$user_id_result}[0]->[0];
		#Now get the minimum user id for this org
		my $min_id_result = $dbh->selectall_arrayref("SELECT min(id) FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {}, (lc($realm)));
		my $min_id = @{$min_id_result}[0]->[0];
		return ($user_id == $min_id);
	}
}

# eseriCreatePamObcConf.py needs this sub.
sub getAllUsers{
	my ($self, $username) = @_;
	my $dbh = $self->dbh;
	my ($user, $realm) = split(/@/, $username);
	my $users = $dbh->selectall_arrayref("SELECT username, email_prefix, first_name, last_name, real_email, status, double_lock_option, timezone FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) order by username", { Slice => {} }, (lc($realm)));
	#Get an array of all the users, then point to them from
	#the result hash ref under the label 'user'
	my @user_list;
	for my $user (@{$users}){
		push(@user_list, $user);
	}
	my %result;
	$result{'user'} = \@user_list;
	return \%result;
}

sub getAllDomainConfigDetails{
        my ($self, $username) = @_;
        my $dbh = $self->dbh;
        my ($user, $realm) = split(/@/, $username);
        my $details = $dbh->prepare("SELECT email_domain FROM network.organization WHERE network_name != ? AND email_domain != ''");
	$details->bind_param(1, lc($realm));
        $details->execute();
        my @details_list;
	while ( my $detail = $details->fetchrow_hashref() ) {
		push(@details_list, "\L$detail->{'email_domain'}");
	}
        my %result;
        $result{'email_domain'} = \@details_list;
        return \%result;
}

sub getCloudUserDetails{
    my ($self, $username) = @_;
    my $dbh = $self->dbh;
    my ($user, $realm) = split(/@/, $username);
    my $is_admin = isAdmin($self, $username);

    my $get_system_anchor_details = $dbh->selectall_arrayref("SELECT a.network_name AS system_anchor_domain, b.address AS system_anchor_ip, inet(b.netmask) AS system_anchor_netmask FROM network.organization AS a, network.address_pool AS b WHERE a.id = b.organization AND a.id = 1", {Slice => {} });

    my $cloud_processing_status_details = $dbh->selectall_arrayref("SELECT dc AS dc_status, ccc AS ccc_status, tzc AS tzc_status, fpc AS fpc_status, bc AS bc_status FROM network.organization_config_status WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {Slice => {} }, (lc($realm)));
    
    my $user_processing_status_details = $dbh->selectall_arrayref("SELECT COUNT(status) AS user_processing_status FROM network.eseri_user_public WHERE (status = 'PROCESSING' OR status = 'ARCHIVING' or status = 'ACTIVATING' or status = 'UPDATING') AND organization = (SELECT id FROM network.organization WHERE network_name = ?)", {Slice => {} }, (lc($realm)));

    my $billing_details = $dbh->selectall_arrayref("SELECT a.cloud_type AS b_cloud_type, b.amount AS b_paid_amount FROM network.billing AS a, loginsite.paypal AS b WHERE ((a.latest_subscr_id = b.subscr_id OR ((a.latest_subscr_id IS NULL OR a.latest_subscr_id = '') AND (b.subscr_id IS NULL OR b.subscr_id = '')))) AND b.amount > 0 AND a.organization = (SELECT id FROM network.organization WHERE network_name = ?) AND a.organization = b.organization GROUP BY a.cloud_type, b.amount", {Slice => {} }, (lc($realm)));

    my $dc_details = $dbh->selectall_arrayref("SELECT a.config_version AS dc_config_version, a.email_domain AS dc_email_domain, a.imap_server AS dc_imap_server, a.alias_domain AS dc_alias_domain, a.website_ip AS dc_website_ip , b.address AS dc_cloud_ip FROM network.domain_config AS a, network.address_pool AS b WHERE a.organization = b.organization AND a.organization = (SELECT id FROM network.organization WHERE network_name = ?)", {Slice => {} }, (lc($realm)));

    my $domain_list1 = $dbh->selectall_arrayref("SELECT email_domain FROM network.organization WHERE network_name != ? AND email_domain != ''", { Slice => {} }, (lc($realm)));

    my $domain_list2 = $dbh->selectall_arrayref("SELECT domain FROM network.domain_restricted", { Slice => {} });

    my $timezone_details = $dbh->selectall_arrayref("SELECT timezone AS tzc_timezone FROM network.timezone_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?)", {Slice => {} }, (lc($realm)));

    my $user_details = $dbh->selectall_arrayref("SELECT a.first_name AS user_first_name, a.last_name AS user_last_name, a.email_prefix AS user_email_prefix, b.email_domain AS user_email_domain, a.real_email AS user_real_email, a.double_lock_option AS user_dl_option, a.timezone AS user_timezone FROM network.eseri_user_public AS a, network.organization AS b WHERE a.username = ? AND a.organization = b.id AND b.network_name = ?", {Slice => {}}, ($user, lc($realm)));

    my $user_list = $dbh->selectall_arrayref("SELECT username, email_prefix, first_name, last_name, real_email, status, double_lock_option, timezone, CASE WHEN type = 'full' THEN 'Full' WHEN type = 'email_only' THEN 'Email Only' END AS type FROM network.eseri_user_public WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) order by username", { Slice => {} }, (lc($realm)));

    my $categories = $dbh->selectall_arrayref("SELECT a.name AS category_name, b.name AS capability_name, b.description1 AS capability_description1, b.description2 AS capability_description2, b.price AS capability_price, b.type AS capability_type FROM packages.categories AS a, packages.capabilities AS b, packages.categorycapabilities AS c WHERE a.catid = c.catid AND b.capid = c.capid AND a.catid < 500 ORDER BY b.type, a.name, b.description1, b.description2 ASC", {Slice => {} });

    my $special_categories = $dbh->selectall_arrayref("SELECT a.name AS category_name, b.name AS capability_name, b.description1 AS capability_description1, b.description2 AS capability_description2, b.price AS capability_price, b.type AS capability_type FROM packages.categories AS a, packages.capabilities AS b, packages.categorycapabilities AS c WHERE a.catid = c.catid AND b.capid = c.capid AND a.catid > 500 ORDER BY b.type, a.name, b.description1, b.description2 ASC", {Slice => {} });

    my $capabilities_enabled = $dbh->selectall_arrayref("SELECT a.name AS capability_name, b.enabled AS capability_enabled FROM packages.capabilities AS a, packages.organizationcapabilities AS b WHERE a.capid = b.capability AND b.organization = (SELECT id FROM network.organization WHERE network_name = ?)", {Slice => {} }, (lc($realm)));

    my $fpc_list = $dbh->selectall_arrayref("SELECT a.capid, a.name, a.description, b.external_name, b.external_access, b.ssl FROM packages.capabilities AS a, packages.organizationcapabilities AS b WHERE b.organization = (SELECT id FROM network.organization WHERE network_name = ?) AND a.capid = b.capability AND a.external_access = ? AND b.enabled = ? order by a.description", {Slice => {} }, (lc($realm)), ('t'), ('t'));

    my $backup_list = $dbh->selectall_arrayref("SELECT profile_id, name, frequency, time, target_url, enabled FROM network.backup_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY profile_id", {Slice => {} }, (lc($realm)));

    my $backup_user_details = $dbh->selectall_arrayref("SELECT profile_id, name FROM network.backup_config WHERE organization = (SELECT id FROM network.organization WHERE network_name = ?) ORDER BY profile_id", {Slice => {} }, (lc($realm)));
    
    my $backup_frequencies = $dbh->selectall_arrayref("SELECT f_number AS frequency_number, f_duration AS frequency_duration FROM network.backup_frequencies ORDER BY f_id", {Slice => {} });

    my $backup_schemes = $dbh->selectall_arrayref("SELECT s_abbreviation AS scheme_abbreviation, s_name AS scheme_name, s_target_url AS scheme_target_url FROM network.backup_schemes ORDER BY scheme_name", {Slice => {} });

    my @ccc_list;
    for my $detail (@{$categories}){
	for my $enabled(@{$capabilities_enabled}){
	    if ($enabled->{'capability_name'} eq $detail->{'capability_name'}){
		$detail->{'capability_enabled'} = $enabled->{'capability_enabled'};
		last;
	    }
	}
	if (!defined $detail->{'capability_enabled'}){
	    $detail->{'capability_enabled'} = 0;
	}
	push(@ccc_list, $detail);
    }

    for my $detail (@{$special_categories}){
	for my $enabled(@{$capabilities_enabled}){
	    if ($enabled->{'capability_name'} eq $detail->{'capability_name'}){
		$detail->{'capability_enabled'} = $enabled->{'capability_enabled'};
		last;
	    }
	}
	if (!defined $detail->{'capability_enabled'}){
	    $detail->{'capability_enabled'} = 0;
	}
	push(@ccc_list, $detail);
    }

    my @restricted_domain_list;
    for my $detail (@{$domain_list1}){
	push(@restricted_domain_list, $detail->{'email_domain'});
    }
    for my $detail (@{$domain_list2}){
	push(@restricted_domain_list, $detail->{'domain'});
    }

    my @list1 = ($get_system_anchor_details->[0], $cloud_processing_status_details->[0], $user_processing_status_details->[0], $user_details->[0]);
    if ($is_admin eq '1'){
	push (@list1, $dc_details->[0]);
	push (@list1, $billing_details->[0]);
	push (@list1, $timezone_details->[0]); 
    }

    my %result;
    ($is_admin eq '1') ? ($result{'is_admin'} = '1') : ($result{'is_admin'} = '0');
    for (my $i=0; $i<scalar @list1; $i++){
	%result = (%result, %{$list1[$i]});
    }

    my %list2;
    if ($is_admin eq '1'){
	$list2{'restricted_domain_list'} = \@restricted_domain_list;
	$list2{'user_list'} = $user_list;
	$list2{'ccc_list'} = \@ccc_list;
	$list2{'fpc_list'} = $fpc_list;
	$list2{'backup_list'} = $backup_list;
	$list2{'backup_frequencies'} = $backup_frequencies;
	$list2{'backup_schemes'} = $backup_schemes;	
    }
    
    $list2{'backup_user_details'} = $backup_user_details;

    while ( my ($key, $value) = each %list2 ){
	my %organize_hash;
	$organize_hash{'detail'} = $value;
	$result{$key} = \%organize_hash;
    }

    return \%result;
}

sub mylog{
    my $output = shift;
    my $now = localtime;
    open (MYFILE, '>>/tmp/model_prime.log');
    print MYFILE "$now $output\n";
    close (MYFILE);
}

=head1 NAME

CirrusOpen::AccountManager::Model::Prime - DBI Model Class

=head1 SYNOPSIS

See L<CirrusOpen::AccountManager>

=head1 DESCRIPTION

DBI Model Class.

=head1 AUTHOR

Wolgemuth Greg, Nimesh Jethwa

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
