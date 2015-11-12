package RKmeansClustering::RKmeansClusteringClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

RKmeansClustering::RKmeansClusteringClient

=head1 DESCRIPTION


A KBase module: RKmeansClustering


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => RKmeansClustering::RKmeansClusteringClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
        else
        {
	    #
	    # All methods in this module require authentication. In this case, if we
	    # don't have a token, we can't continue.
	    #
	    die "Authentication failed: " . $token->error_message;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 estimate_k

  $output_ref = $obj->estimate_k($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RKmeansClustering.EstimateKParams
$output_ref is a RKmeansClustering.ws_estimatekresult_id
EstimateKParams is a reference to a hash where the following keys are defined:
	input_matrix has a value which is a RKmeansClustering.ws_matrix_id
	min_k has a value which is an int
	max_k has a value which is an int
	criterion has a value which is a string
	usepam has a value which is a RKmeansClustering.boolean
	alpha has a value which is a float
	diss has a value which is a RKmeansClustering.boolean
	random_seed has a value which is an int
	out_workspace has a value which is a string
	out_estimate_result has a value which is a string
ws_matrix_id is a string
boolean is an int
ws_estimatekresult_id is a string

</pre>

=end html

=begin text

$params is a RKmeansClustering.EstimateKParams
$output_ref is a RKmeansClustering.ws_estimatekresult_id
EstimateKParams is a reference to a hash where the following keys are defined:
	input_matrix has a value which is a RKmeansClustering.ws_matrix_id
	min_k has a value which is an int
	max_k has a value which is an int
	criterion has a value which is a string
	usepam has a value which is a RKmeansClustering.boolean
	alpha has a value which is a float
	diss has a value which is a RKmeansClustering.boolean
	random_seed has a value which is an int
	out_workspace has a value which is a string
	out_estimate_result has a value which is a string
ws_matrix_id is a string
boolean is an int
ws_estimatekresult_id is a string


=end text

=item Description

Used as an analysis step before generating clusters using K-means clustering,
this method provides an estimate of K by [...]

=back

=cut

 sub estimate_k
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function estimate_k (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to estimate_k:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'estimate_k');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "RKmeansClustering.estimate_k",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'estimate_k',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method estimate_k",
					    status_line => $self->{client}->status_line,
					    method_name => 'estimate_k',
				       );
    }
}
 


=head2 cluster_k_means

  $output_ref = $obj->cluster_k_means($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a RKmeansClustering.ClusterKMeansParams
$output_ref is a RKmeansClustering.ws_featureclusters_id
ClusterKMeansParams is a reference to a hash where the following keys are defined:
	k has a value which is an int
	input_data has a value which is a RKmeansClustering.ws_matrix_id
	n_start has a value which is an int
	max_iter has a value which is an int
	random_seed has a value which is an int
	algorithm has a value which is a string
	out_workspace has a value which is a string
	out_clusterset_id has a value which is a string
ws_matrix_id is a string
ws_featureclusters_id is a string

</pre>

=end html

=begin text

$params is a RKmeansClustering.ClusterKMeansParams
$output_ref is a RKmeansClustering.ws_featureclusters_id
ClusterKMeansParams is a reference to a hash where the following keys are defined:
	k has a value which is an int
	input_data has a value which is a RKmeansClustering.ws_matrix_id
	n_start has a value which is an int
	max_iter has a value which is an int
	random_seed has a value which is an int
	algorithm has a value which is a string
	out_workspace has a value which is a string
	out_clusterset_id has a value which is a string
ws_matrix_id is a string
ws_featureclusters_id is a string


=end text

=item Description

Clusters features by K-means clustering.

=back

=cut

 sub cluster_k_means
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function cluster_k_means (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to cluster_k_means:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'cluster_k_means');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "RKmeansClustering.cluster_k_means",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'cluster_k_means',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method cluster_k_means",
					    status_line => $self->{client}->status_line,
					    method_name => 'cluster_k_means',
				       );
    }
}
 
  

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "RKmeansClustering.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'cluster_k_means',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method cluster_k_means",
            status_line => $self->{client}->status_line,
            method_name => 'cluster_k_means',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for RKmeansClustering::RKmeansClusteringClient\n";
    }
    if ($sMajor == 0) {
        warn "RKmeansClustering::RKmeansClusteringClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

Indicates true or false values, false = 0, true = 1
@range [0,1]


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 ws_matrix_id

=over 4



=item Description

A workspace ID that references a Float2DMatrix wrapper data object.
@id ws KBaseFeatureValues.ExpressionMatrix KBaseFeatureValues.SingleKnockoutFitnessMatrix


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ws_estimatekresult_id

=over 4



=item Description

The workspace ID of a FeatureClusters data object.
@id ws KBaseFeatureValues.EstimateKResult


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ws_featureclusters_id

=over 4



=item Description

The workspace ID of a FeatureClusters data object.
@id ws KBaseFeatureValues.FeatureClusters


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 EstimateKParams

=over 4



=item Description

Output object will have type KBaseFeatureValues.EstimateKResult


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_matrix has a value which is a RKmeansClustering.ws_matrix_id
min_k has a value which is an int
max_k has a value which is an int
criterion has a value which is a string
usepam has a value which is a RKmeansClustering.boolean
alpha has a value which is a float
diss has a value which is a RKmeansClustering.boolean
random_seed has a value which is an int
out_workspace has a value which is a string
out_estimate_result has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_matrix has a value which is a RKmeansClustering.ws_matrix_id
min_k has a value which is an int
max_k has a value which is an int
criterion has a value which is a string
usepam has a value which is a RKmeansClustering.boolean
alpha has a value which is a float
diss has a value which is a RKmeansClustering.boolean
random_seed has a value which is an int
out_workspace has a value which is a string
out_estimate_result has a value which is a string


=end text

=back



=head2 ClusterKMeansParams

=over 4



=item Description

Output object will have type KBaseFeatureValues.FeatureClusters


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
k has a value which is an int
input_data has a value which is a RKmeansClustering.ws_matrix_id
n_start has a value which is an int
max_iter has a value which is an int
random_seed has a value which is an int
algorithm has a value which is a string
out_workspace has a value which is a string
out_clusterset_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
k has a value which is an int
input_data has a value which is a RKmeansClustering.ws_matrix_id
n_start has a value which is an int
max_iter has a value which is an int
random_seed has a value which is an int
algorithm has a value which is a string
out_workspace has a value which is a string
out_clusterset_id has a value which is a string


=end text

=back



=cut

package RKmeansClustering::RKmeansClusteringClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
