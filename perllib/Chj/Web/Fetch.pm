# Fri Sep  2 03:11:04 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Web::Fetch

=head1 SYNOPSIS

 use Chj::Web::Fetch 'get_remote_file';# or get_remote_file_ref
 my $content= get_remote_file $uri_object_or_string | $HTTP_Request_object [, $defaultcharset ];
 my $contentref= get_remote_file_ref ...;#same thing

=head1 DESCRIPTION

wrapper around LWP to simplify life a bit. Throws exceptions (well, currently only dies :/) on errors.
(written for EiD)

=cut


package Chj::Web::Fetch;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(get_remote_file get_remote_file_ref);

use strict;

# use HTTP::GHTTP;
# sub get_remote_file {
#     my ($uri)=@_;
#     my $f= new HTTP::GHTTP;
#     $f->set_uri($uri);
#     $f->process_request;
#     my ($retcode,$errmsg)= $f->get_status;
#     if ($retcode==200) {
# 	$f->get_body
#     } else {
# 	die "ghttp_get('$uri'): $retcode $errmsg / ".($f->get_error);
#     }
# }

use LWP;
use HTTP::Request;
use LWP::UserAgent;
#use Chj::Backtrace;
use Carp;
use Encode;
use HTTP::Status 'RC_NOT_MODIFIED';
use Chj::singlequote;

our $USER_AGENT_STR= "LWP/Chj-Web-Fetch <jaeger\@ethlife.ethz.ch>";

our $not_modified_in_scalar_context_error= sub{
    my $uri_or_request=shift;
    croak "get_remote_file(".singlequote($uri_or_request)."): got 'not modified' response in scalar context";
};
our $not_success_error= sub{
    my ($uri_or_request,$res)=@_;
    die "get_remote_file(".singlequote($uri_or_request)."): ".$res->status_line;
};


sub dflt_response_needs_charset_encoding_p {
    my ($response)=@_;
    # dann encoding, wenn es text/* irgendwas ist. egal ob es charset hat dort. ok?.
    $response->content_type =~ /text/i
}

sub get_remote_file {
    my ($uri_or_request, $default_response_encoding, $response_needs_charset_encoding_p,
	$opt_give_ref)=@_;
    $response_needs_charset_encoding_p||= \&dflt_response_needs_charset_encoding_p;

    my $ag= new LWP::UserAgent;
    $ag->agent($USER_AGENT_STR);
    my $request= do{
	if ($uri_or_request->isa("HTTP::Request")) {
	    $uri_or_request
	} else {
	    # assuming URI object. Well actually:
	    # "The $uri argument can be either a string, or a reference to a "URI" object."
	    #$r = HTTP::Request->new( $method, $uri )
	    #$r = HTTP::Request->new( $method, $uri, $header )
	    #$r = HTTP::Request->new( $method, $uri, $header, $content )
	    #Constructs a new "HTTP::Request" object describing a request on the object $uri using
	    #method $method.  The $method argument must be a string.  The $uri argument can be
	    #either a string, or a reference to a "URI" object.  The optional $header argument
	    #should be a reference to an "HTTP::Headers" object or a plain array reference of
	    #key/value pairs.  The optional $content argument should be a string of bytes.
	    HTTP::Request->new(GET=> $uri_or_request);
	}
    };
    #$DB::single=1;
    my $res= $ag->request($request); # ->HTTP::Response

    #$r->is_info
    #$r->is_success
    #$r->is_redirect
    #$r->is_error

    if ($res->is_success) {
	# not-modified doesn't get here
	#my $method= $response_needs_charset_encoding_p->($res) ? "decoded_content" : "content";
	#my $ref= $res->$method(
	#ah die eine nimmt keine optionen sigh.
	my $response_needs_charset_encoding= $response_needs_charset_encoding_p->($res);
	my $ref= $response_needs_charset_encoding ?
	  $res->decoded_content(
				(($default_response_encoding) ?
				 (default_charset => $default_response_encoding) : ()),
				# raise_error=> 1,
				(ref => 1)
			       )
	    : $res->content_ref;

	if ($opt_give_ref){
	    if (wantarray) {
		($ref,$res,$response_needs_charset_encoding)
	    } else {
		$ref
	    }
	} else {
	    if (wantarray) {
		($$ref,$res,$response_needs_charset_encoding)
	    } else {
		$$ref
	    }
	}
#     } elsif ($res->is_info) {
# 	if (wantarray) {
# 	    (undef,$res)
# 	} else {
# 	    croak "get_remote_file('$uri_or_request'): got info result in scalar context";
# 	}
#     } elsif ($res->is_error) {
# 	if (wantarray) {
# 	    (undef,$res)
# 	} else {
# 	    croak "get_remote_file('$uri_or_request'): got error result in scalar context";
# 	}
#     } elsif ($res->is_redirect) {
# 	if (wantarray) {
# 	    (undef,$res)
# 	} else {
# 	    croak "get_remote_file('$uri_or_request'): got redirect in scalar context";
# 	}
    } elsif ($res->code  == RC_NOT_MODIFIED) {
	if (wantarray) {
	    (undef,$res)
	} else {
	    $not_modified_in_scalar_context_error->($uri_or_request);
	}
    } else {
	$not_success_error->($uri_or_request,$res);
    }
}

sub get_remote_file_ref {
    get_remote_file($_[0],$_[1],$_[2],
		    1)
}
