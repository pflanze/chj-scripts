#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::callcc2

=head1 SYNOPSIS

=head1 DESCRIPTION

Another implementation of one-shot continuations (see Chj::callcc);
forgot about the first one.

TODO: eliminate one of them some time.

(This one also provides cont_capture and cont_invoke.)

=cut


package Chj::callcc2;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(callcc);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;


sub cont_capture ( $ ) {
    my ($pass)=@_;
    my $token= [ "CONT" ];
    my $do= sub {
	&$pass ($token)
    };
    if (wantarray) {
	my @res;
	if (eval {
	    @res= &$do;
	    1
	}) {
	    @res
	} else {
	    my $e=$@;
	    if (ref($e) eq "ARRAY"
		and @$e
		and $$e[0] == $token) {
		shift @$e;
		return @$e
	    } else {
		die $e
	    }
	}
    } else {
	my $res;
	if (eval {
	    $res= &$do;
	    1
	}) {
	    $res
	} else {
	    my $e=$@;
	    if (ref($e) eq "ARRAY"
		and @$e
		and $$e[0] == $token) {
		return $$e[1] # XX: why the first of the vals and not the last?
	    } else {
		die $e
	    }
	}
    }
}

sub cont_invoke {
    my ($exit,@vals)=@_;
    die [$exit, @vals];
}

sub callcc ( $ ) {
    my ($proc)=@_;
    cont_capture sub {
	my ($exit)=@_;
	&$proc (sub {
		    my (@vals)=@_;
		    cont_invoke $exit,@vals
		});
    };
}



1
