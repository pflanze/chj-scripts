# Mon Dec 18 00:46:37 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Stream

=head1 SYNOPSIS

=head1 DESCRIPTION

function library


=cut


package Chj::FP::Stream;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      Port2stream
	     );

use strict;
#use Chj::FP::lazy 'Delay';#lustig ist funktion bei perl.  wobei geht schneller direkt
use Chj::FP::Promise;

# to avoid having to use local recursive functions an weak reference
# tricks, use the thing lambda-lifted
sub _direct_p2s { # uses getc, not method calls on the port
    my ($port)=@_;
    # this is all hacky, only for performance reasons inlined here.
    bless [
	   0, #unevaluated
	   sub {
	       warn "getting..";
	       my $c= getc($port);
	       warn "got '$c'";
	       if (defined $c) {
		   #OH shit gc problems?kommen to mind
		   bless [$c, _direct_p2s($port)], "Chj::FP::Pair"
	       } else {
		   if ($!) {
		       die "Port2stream($port): $!";#
		   } else {
		       $Chj::FP::EmptyList
		   };
	       }
	   }
	  ], "Chj::FP::StreamPromise";
}


sub Port2stream {
    my ($port)=@_;
    my $maybe_getc= UNIVERSAL::can($port,"getc");
    if ($maybe_getc) {
	die "method version of this not yet implemented";
    } else {
	_direct_p2s($port)
    }
}


{
    # so as to provide car and cdr directly on the stream?: (stream-car/-cdr)
    package Chj::FP::StreamPromise;
    use Carp;
    use Chj::FP::Promise -extend=>();
    sub mk {
	my ($field)=@_;
	sub {
	    my $s=shift;
	    my $v=
	      # copy of Chj/FP/Promise.pm
	      $$s[Evaluated] ? $$s[Value]
		: do {
		    $$s[Value]= &{$$s[Value]}; #ps gets $s as argument hehe ehr no, the arguments of force. whatever.
		    $$s[Evaluated]=1;
		    $$s[Value]
		};
	    if (UNIVERSAL::isa($v,"Chj::FP::Pair")) {
		$v->[$field]
	    } else {
		croak "not a pair: $v";
	    }
	}
    }
    *car= mk(Chj::FP::Pair::Car);
    *cdr= mk(Chj::FP::Pair::Cdr);
    # hm other functions from Chj::FP::Pair like cadr missing but well?.
    # (not setters, though)
}


1
