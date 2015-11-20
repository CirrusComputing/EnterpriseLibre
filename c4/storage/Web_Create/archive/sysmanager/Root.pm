package CirrusOpen::AccountManager::Controller::Root;
use Moose;
use XML::Simple;
use RPC::XML;
use RPC::XML::Client;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CirrusOpen::AccountManager::Controller::Root - Root Controller for CirrusOpen::AccountManager

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;
	#This controller method is used to forward to appropriate actions based on the arriving XML
	my $body_handle = $c->request->body;
	my $c3_procedure_prefix = 'net.eseri.';
	if ($c->request->content_type eq 'text/xml' and $c->request->method eq 'POST'){
	    my $xml_ref = XMLin($body_handle);
	    #Set the content-type of our response appropriately
	    $c->res->content_type('text/xml');
	    #Switch based on the element contained in the root
	    my %result;
	    my $xs = XML::Simple->new( XMLDecl => "<?xml version=\"1.0\" encoding=\"utf-8\"?>", SuppressEmpty => undef, RootName => "result", NoAttr => 1);
	    if (exists $xml_ref->{'isAdmin'}){
		#Check to see if the authenticated user is admin for the organization
		if ($c->model->isAdmin($c->req->remote_user)){
		    #Return an "accepted" message
		    $result{'accepted'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    #Return a "rejected" message
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'listUsers'}){
		# This is needed and called by eseriCreatePamObcConf.py
		#Return a list of all the users in the organization, only if the calling user is an admin
		if ($c->model->isAdmin($c->req->remote_user)){
		    #List all users and return to the GUI
		    my $result_ref = $c->model->getAllUsers($c->req->remote_user);
		    $c->res->body( $xs->XMLout( $result_ref ));
	        }
	        else {
		    #Return a "rejected" message
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
	        }
	    }
	    elsif (exists $xml_ref->{'addUser'}){
		#Make XML-RPC call to create a new user, only if the calling user is an admin
		if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'addUser'}->{'username'};
		    my $desired_email_prefix = $xml_ref->{'addUser'}->{'desired_email_prefix'};
		    my $firstname = $xml_ref->{'addUser'}->{'firstname'};
		    my $lastname = $xml_ref->{'addUser'}->{'lastname'};
		    my $email = $xml_ref->{'addUser'}->{'email'};
		    my $type = 'full';
		    if ($xml_ref->{'addUser'}->{'type'} eq 'Full'){
			$type = 'full';
		    }
		    elsif ($xml_ref->{'addUser'}->{'type'} eq 'Email Only'){
			$type = 'email_only';
		    }

		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'createNewUser', $username, $desired_email_prefix, lc($realm), $firstname, $lastname, $email, $type);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'archiveUser'}){
		#Make an XML-RPC call to archive an existing active user, only if the calling user is an admin
		if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'archiveUser'}->{'username'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'archiveUser', $username, lc($realm));
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'activateUser'}){
		#Make an XML-RPC call to activate an existing archived user, only if the calling user is an admin
		if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'activateUser'}->{'username'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'restoreUser', $username, lc($realm));
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'rebootUser'}){
		#Make an XML-RPC call to reboot an existing user's desktop
		if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'rebootUser'}->{'username'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'resetDesktop', $username, lc($realm));
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'resetUser'}){
		#Make an XML-RPC call to reset the password of an existing user's desktop
		if ( exists $xml_ref->{'resetUser'}->{'username'} && ! $c->model->isAdmin($c->req->remote_user)){
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
	        }
		if ( exists $xml_ref->{'resetUser'}->{'username'} ){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'resetUser'}->{'username'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    my $password = ( exists $xml_ref->{'resetUser'}->{'password'} ) ? $xml_ref->{'resetUser'}->{'password'} : '';
		    $client->send_request($c3_procedure_prefix.'changeUserPassword', $username, lc($realm), $password);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
	        }
		else {
		    my ($username, $realm) = split(/@/, $c->req->remote_user);
		    my $client = RPC::XML::Client->new($self->{c3});
		    my $password = ( exists $xml_ref->{'resetUser'}->{'password'} ) ? $xml_ref->{'resetUser'}->{'password'} : '';
		    $client->send_request($c3_procedure_prefix.'changeUserPassword', $username, lc($realm), $password);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'changeDLOption'}){
	        #Make an XML-RPC call to change the Double-Lock Option for an existing user
	        if ( $xml_ref->{'changeDLOption'}->{'dloption'} eq 'ON_LOCKED' && ! $c->model->isAdmin($c->req->remote_user)){
	            $result{'rejected'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
	        else {
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    if ( exists $xml_ref->{'changeDLOption'}->{'username'} ){
			$user = $xml_ref->{'changeDLOption'}->{'username'};
		    }

	            my $client = RPC::XML::Client->new($self->{c3});
	            my $dl_option = $xml_ref->{'changeDLOption'}->{'dloption'};
		    mylog($user);
		    mylog($dl_option);
	            $client->send_request($c3_procedure_prefix.'changeDLOption', $user, lc($realm), $dl_option); 
	            $result{'accepted'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
	    }
	    elsif (exists $xml_ref->{'changeExternalEmail'}){
	        #Make an XML-RPC call to change the Double-Lock Address for an existing user
	        if ( exists $xml_ref->{'changeExternalEmail'}->{'username'} && ! $c->model->isAdmin($c->req->remote_user)){
	            $result{'rejected'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
		if ( exists $xml_ref->{'changeExternalEmail'}->{'username'}){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
	            my $username = $xml_ref->{'changeExternalEmail'}->{'username'};
	            my $client = RPC::XML::Client->new($self->{c3});
	            my $external_email = $xml_ref->{'changeExternalEmail'}->{'email'};
	            $client->send_request($c3_procedure_prefix.'changeExternalEmail', $username, lc($realm), $external_email);
	            $result{'accepted'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
		else{
		    my ($username, $realm) = split(/@/, $c->req->remote_user);
                    my $client = RPC::XML::Client->new($self->{c3});
                    my $external_email = $xml_ref->{'changeExternalEmail'}->{'email'};
                    $client->send_request($c3_procedure_prefix.'changeExternalEmail', $username, lc($realm), $external_email);
                    $result{'accepted'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
		}
	    } 
	    elsif (exists $xml_ref->{'changeDomainConfig'}){
	        #Make an XML-RPC call to change the Double-Lock Address for an existing user
	        if ($c->model->isAdmin($c->req->remote_user)){
	            my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $new_config_version =  $xml_ref->{'changeDomainConfig'}->{'new_config_version'};
		    my @domain_config_array;
		    push (@domain_config_array, $xml_ref->{'changeDomainConfig'}->{'new_email_domain'});
		    push (@domain_config_array, $xml_ref->{'changeDomainConfig'}->{'new_imap_server'});
		    push (@domain_config_array, $xml_ref->{'changeDomainConfig'}->{'new_alias_domain'});
		    push (@domain_config_array, $xml_ref->{'changeDomainConfig'}->{'new_website_ip'});
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'changeDomainConfig', lc($realm), $new_config_version, \@domain_config_array);
	            $result{'accepted'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
	        else{
	            $result{'rejected'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
	    }
	    elsif (exists $xml_ref->{'insertCloudManagerReq'}){
                #Insert cloud req in database
                if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $hash = $xml_ref->{'insertCloudManagerReq'}->{'hash'};
		    my $data = $xml_ref->{'insertCloudManagerReq'}->{'data'};
		    $data =~ s|utype>Email Only</|utype>email_only</|g;
		    $data =~ s|utype>Full</|utype>full</|g;
		    my $new_string = $xml_ref->{'insertCloudManagerReq'}->{'new_string'};
		    my $amount = $xml_ref->{'insertCloudManagerReq'}->{'amount'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'insertCloudManagerReq', lc($realm), $hash, $data, $new_string, "$amount");
                    $result{'accepted'} = '';
                    $c->res->body( $xs->XMLout( \%result ));
                }
                else {
                    #Return a "rejected" message
                    $result{'rejected'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
                }
            }
            elsif (exists $xml_ref->{'changeTimezoneConfig'}){
		if ( (exists $xml_ref->{'changeTimezoneConfig'}->{'username'} || $xml_ref->{'changeTimezoneConfig'}->{'server_user'} eq 'server') && ! $c->model->isAdmin($c->req->remote_user )){
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		my ($user, $realm) = split(/@/, $c->req->remote_user);
		if ( exists $xml_ref->{'changeTimezoneConfig'}->{'username'} ){
		    $user = $xml_ref->{'changeTimezoneConfig'}->{'username'};
		}
                #Make an XML-RPC call to do the appropriate for changing server/user timezone
		my $server_user = $xml_ref->{'changeTimezoneConfig'}->{'server_user'};
		my $new_timezone = $xml_ref->{'changeTimezoneConfig'}->{'new_timezone'};
		my $client = RPC::XML::Client->new($self->{c3});
		$client->send_request($c3_procedure_prefix.'changeTimezoneConfig', lc($realm), $new_timezone, $server_user, $user);
		$result{'accepted'} = '';
		$c->res->body( $xs->XMLout( \%result ) );
            }
	    elsif (exists $xml_ref->{'getCloudUserDetails'}){
	        #Return the details for a cloud and its users, based on who is calling (ie. admin or normal user)
		my $result_ref = $c->model->getCloudUserDetails($c->req->remote_user);
		$c->res->body( $xs->XMLout( $result_ref ));
	    }
	    elsif (exists $xml_ref->{'changeFirewallProxyConfig'}){
                #Make an XML-RPC call to do the appropriate for changing the firewall and proxy config
                if ($c->model->isAdmin($c->req->remote_user)){
                    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my @capability;
		    my @external_name;
		    my @ssl;
		    my $i=0;
		    while (1){
			if (defined $xml_ref->{'changeFirewallProxyConfig'}->{'detail'}[$i]->{'capability'}){
			    push (@capability, $xml_ref->{'changeFirewallProxyConfig'}->{'detail'}[$i]->{'capability'});
			    push (@external_name, $xml_ref->{'changeFirewallProxyConfig'}->{'detail'}[$i]->{'external_name'});
			    push (@ssl, $xml_ref->{'changeFirewallProxyConfig'}->{'detail'}[$i]->{'ssl'});			    
			    $i++;
			}
			else{
			    last;
			}
		    }
                    my $client = RPC::XML::Client->new($self->{c3});
                    my $res = $client->send_request($c3_procedure_prefix.'changeFirewallProxyConfig', lc($realm), \@capability, \@external_name, \@ssl);
		    $result{'accepted'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
                }
                else{
                    $result{'rejected'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
                }
            }
	    elsif (exists $xml_ref->{'cloudReboot'}){
		#Make an XML-RPC call to reboot the cloud containers
		if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my $username = $xml_ref->{'cloudReboot'}->{'username'};
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'cloudReboot', lc($realm));
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else {
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'changeUserAliasConfig'}){
		#Make an XML-RPC call to configure user aliases
		my ($user, $realm) = split(/@/, $c->req->remote_user);
		my $option = $xml_ref->{'changeUserAliasConfig'}->{'option'};
		my $username;
		if ($c->model->isAdmin($c->req->remote_user)){
		    $username = $xml_ref->{'changeUserAliasConfig'}->{'username'};
		}
		else{
		    $username = $user;
		}
		my $alias = $xml_ref->{'changeUserAliasConfig'}->{'alias'};
		my $client = RPC::XML::Client->new($self->{c3});
		$client->send_request($c3_procedure_prefix.'changeUserAliasConfig', lc($realm), $option, $username, $alias);
		$result{'accepted'} = '';
		$c->res->body( $xs->XMLout( \%result ) );
	    }
	    elsif (exists $xml_ref->{'changeUserPrimaryEmailConfig'}){
		#Make an XML-RPC call to configure user primary email. The superuser is not allowed though.
		if ($c->model->isAdmin($c->req->remote_user)){
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else{
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    push (my (@username), $user);
		    push (my (@old_email), $xml_ref->{'changeUserPrimaryEmailConfig'}->{'old_email'});
		    push (my (@new_email), $xml_ref->{'changeUserPrimaryEmailConfig'}->{'new_email'});
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'changeUserPrimaryEmailConfig', lc($realm), \@username, \@old_email, \@new_email);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'changeUserFullnameConfig'}){
		#Make an XML-RPC call to configure user fullname.
		my ($user, $realm) = split(/@/, $c->req->remote_user);
		push (my (@username), $user);
		push (my (@old_firstname), $xml_ref->{'changeUserFullnameConfig'}->{'old_firstname'});
		push (my (@old_lastname), $xml_ref->{'changeUserFullnameConfig'}->{'old_lastname'});
		push (my (@new_firstname), $xml_ref->{'changeUserFullnameConfig'}->{'new_firstname'});
		push (my (@new_lastname), $xml_ref->{'changeUserFullnameConfig'}->{'new_lastname'});
		my $client = RPC::XML::Client->new($self->{c3});
		$client->send_request($c3_procedure_prefix.'changeUserFullnameConfig', lc($realm), \@username, \@old_firstname, \@old_lastname, \@new_firstname, \@new_lastname);
		$result{'accepted'} = '';
		$c->res->body( $xs->XMLout( \%result ) );
	    }
	    elsif (exists $xml_ref->{'changeCloudCapabilityConfig'}){
                #Make an XML-RPC call to do the appropriate for enabling / disabling capabilities
                if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    my @capability;
		    my @enable;
		    my $i=0;
		    while (1){
			if (defined $xml_ref->{'changeCloudCapabilityConfig'}->{'detail'}[$i]->{'capability'}){
			    push (@capability, $xml_ref->{'changeCloudCapabilityConfig'}->{'detail'}[$i]->{'capability'});
			    push (@enable, $xml_ref->{'changeCloudCapabilityConfig'}->{'detail'}[$i]->{'enable'});	
			    $i++;
			}
			else{
			    last;
			}
		    }
                    my $client = RPC::XML::Client->new($self->{c3});
                    my $res = $client->send_request($c3_procedure_prefix.'changeCloudCapabilityConfig', lc($realm), \@capability, \@enable);
		    $result{'accepted'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
                }
                else{
                    $result{'rejected'} = '';
                    $c->res->body( $xs->XMLout( \%result ) );
                }
            }
	    elsif (exists $xml_ref->{'changeUserType'}){
		if ($c->model->isAdmin($c->req->remote_user)){
		    #Make an XML-RPC call to change user type.
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    push (my (@params), $xml_ref->{'changeUserType'}->{'username'});
		    if ($xml_ref->{'changeUserType'}->{'new_utype'} eq 'Full'){
			push (@params, 'full');
		    }
		    elsif ($xml_ref->{'changeUserType'}->{'new_utype'} eq 'Email Only'){
			push (@params, 'email_only');
		    }
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'changeUserType', lc($realm), \@params);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else{
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'changeFirewallPortConfig'}){
		#Make an XML-RPC call to change firewall port configuration in shorewall.
		my ($user, $realm) = split(/@/, $c->req->remote_user);
		push (my (@params), $xml_ref->{'changeFirewallPortConfig'}->{'username'});
		push (@params, $xml_ref->{'changeFirewallPortConfig'}->{'port'});
		my $client = RPC::XML::Client->new($self->{c3});
		$client->send_request($c3_procedure_prefix.'changeFirewallPortConfig', lc($realm), \@params);
		$result{'accepted'} = '';
		$c->res->body( $xs->XMLout( \%result ) );
	    }
	    elsif (exists $xml_ref->{'changeBackupConfig'}){
		if ($c->model->isAdmin($c->req->remote_user)){
		    #Make an XML-RPC call to change backup configuration.
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    push (my (@params), $xml_ref->{'changeBackupConfig'}->{'option'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'profile_id'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'name'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'frequency_number'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'frequency_duration'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'time'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'target_url'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'enabled'});
		    push (@params, $xml_ref->{'changeBackupConfig'}->{'snapshot'});
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'changeBackupConfig', lc($realm), \@params);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else{
		    $result{'rejected'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
	    }
	    elsif (exists $xml_ref->{'restoreFilePath'}){
		#Make an XML-RPC call to restore a file path from backup configuration.
		my ($user, $realm) = split(/@/, $c->req->remote_user);
		push (my (@params), $user);
		push (@params, $xml_ref->{'restoreFilePath'}->{'profile_id'});
		push (@params, $xml_ref->{'restoreFilePath'}->{'time'});
		push (@params, $xml_ref->{'restoreFilePath'}->{'source'});
		push (@params, $xml_ref->{'restoreFilePath'}->{'destination'});
		my $client = RPC::XML::Client->new($self->{c3});
		$client->send_request($c3_procedure_prefix.'restoreFilePath', lc($realm), \@params);
		$result{'accepted'} = '';
		$c->res->body( $xs->XMLout( \%result ) );
	    }
	    elsif (exists $xml_ref->{'changeSystemAnchorConfig'}){
		#Make an XML-RPC call to change the system anchor domain and system anchor ip
	        if ($c->model->isAdmin($c->req->remote_user)){
		    my ($user, $realm) = split(/@/, $c->req->remote_user);
		    push (my (@system_anchor_config_array), $xml_ref->{'changeSystemAnchorConfig'}->{'new_system_anchor_domain'});
		    push (@system_anchor_config_array, $xml_ref->{'changeSystemAnchorConfig'}->{'new_system_anchor_ip'});
		    push (@system_anchor_config_array, $xml_ref->{'changeSystemAnchorConfig'}->{'new_system_anchor_netmask'});
		    my $client = RPC::XML::Client->new($self->{c3});
		    $client->send_request($c3_procedure_prefix.'changeSystemAnchorConfig', lc($realm), \@system_anchor_config_array);
		    $result{'accepted'} = '';
		    $c->res->body( $xs->XMLout( \%result ) );
		}
		else{
	            $result{'rejected'} = '';
	            $c->res->body( $xs->XMLout( \%result ) );
	        }
	    }
	}
	else{
		$c->response->body( 'Page not found' );
		$c->response->status(404);
	}
}

sub mylog{
    my $output = shift;
    my $now = localtime;
    open (MYFILE, '>>/tmp/controller_root.log');
    print MYFILE "$now $output\n";
    close (MYFILE);
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Wolgemuth Greg, Nimesh Jethwa

=head1 LICENSE

Free Open Source Solutions Inc. owns and reserves all rights, title, and
interest in and to this software in both machine and human readable
forms.

=cut

__PACKAGE__->meta->make_immutable;

1;
