# Sun Feb 11 21:09:24 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Socket::SSL

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Socket::SSL;

use strict;
use utf8;

use Class::Array -fields=>
  -publica=>
  (
   'socket', # socket glob
   'verifyresults', #ary
   #'socketerrors', #ary; should always be empty since I die otherwise --well I always die now so no use for this.
   'valid_thinks', # what IO::Socket::SSL thinks about the validity (does not take into account whether the certificate matches the  host name)
   #'valid', #bool cache  --well warum.
   'host', #string, saved from options
  )
  ;


use IO::Socket::SSL;
use Chj::singlequote 'singlequote_many','singlequote';

sub new_host_port {
    my ($class,$host,$port)=@_;
    $class->new (PeerAddr=>$host, PeerPort=>$port);
}

sub new {
    my $class=shift;
    my (%options)=@_;#slow wie immer aber wierum mir draufan oder was.

    local our $valid=1;
    local our $verify_results=[];
    my $verify_callback= sub {
	push @$verify_results,[@_];
	#warn "INVALID CERTIFICATE?"; ehfALSCH,
	#warn "MANUALTESTING, REMOVE!"; #GRRR und dann kein way, um an das fremde cert zu gelangen.gagl
	#1
	#AHA Nein:
	my ($thinks_valid,@rest)=@_;
	$valid=0 unless $thinks_valid;
	#$thinks_valid
	1
    };
    #local our $socket_errors=[];
    my $error_trap= sub {
	#push @$socket_errors,[@_];
	#warn "error_trap called: ".singlequote_many (@_);
	#use Chj::repl;;repl;
	#1#nütznisx
	my ($socket, $msg)=@_;
	chomp $msg;
	die $msg;
    };

    my @opts=
      (
       #SSL_version=> 'SSLv2',
       SSL_ca_path=> "/usr/share/ca-certificates/", #geht nid allein
       SSL_ca_file=> "/etc/ssl/certs/ca-certificates.crt",#geht
       SSL_verify_mode=> 1,
       SSL_verify_callback=> $verify_callback,
       SSL_check_crl=> 1, #gibt weder ohne oder mit SSL_ca_path angabe einen fehler. thus dunno if works.
       #SSL_reuse_ctx  für speed wohl, aber für hier irrelevant
       #SSL_session_cache_size  ah oder eher dies für speed?
       SSL_error_trap=> $error_trap, #für normalsocketlayerlevel anschau
      );
    while(@opts) {
	my $key= shift @opts;
	my $val= shift @opts;
	#unless (exists $$options{$key}) {
	unless (defined $options{$key}) {
	    $options{$key}=$val;
	}
    }

    my $host= $options{PeerHost}||$options{PeerAddr};
    local our $socket= IO::Socket::SSL->new (%options)
      #or die "???bug?". "error: ".IO::Socket::SSL::errstr;#oder nicht exception?, nah nun eh oben schon exception.
      # errstr is ALWAYS so senseless
      #or die "error: ".IO::Socket::INET::errstr; doesn't exist
      or die "could not connect to '$host' port ".singlequote($options{PeerPort}).": $!";# nope, 'Das Argument ist ungültig' only. unrelated?. kack, lib macht spiele mmit $! beschreiben, geht ev nid

    my $s= $class->SUPER::new;
    $$s[Socket]=$socket;
    $$s[Verifyresults]= $verify_results;
    #$$s[Socketerrors]= $socket_errors;
    $$s[Valid_thinks]=$valid;
    $$s[Host]= $host;
    $s
}

sub peer_certificate_subject {
    my $s=shift;
    $s->socket->peer_certificate ("subject")  # an alternative would maybe be to parse the last item in verifyresults
}

sub peer_certificate_subject_CN {
    my $s=shift;
    my $subj= $s->peer_certificate_subject;
    chomp $subj;
    $subj=~ m{/CN=(.*?)(?:/\w+=|\z)} or die "bug?, missing CN in '$subj'";
    $1
}

sub cn_matches {
    my $s=shift;
    lc($s->peer_certificate_subject_CN) eq lc($s->host)
}

sub valid {
    my $s=shift;
    #defined ($$s[Valid]) ? $$s[Valid]
    #  : ($$s[Valid]=
    $s->valid_thinks && $s->cn_matches
}

sub xvalid {
    my $s=shift;
    $s->valid or do {
	# nun rekonstruieren was falsch war sodoof?
	if ($s->valid_thinks) {
	    die "certificate has valid signature but it's CN doesn't match hostname: ".singlequote ($s->peer_certificate_subject_CN)." vs. ".singlequote ($s->host);
	} else {
	    die "certificate has no valid signature: ".singlequote ($s->peer_certificate_subject);
	}
    }
}

end Class::Array;
