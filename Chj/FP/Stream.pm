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
@EXPORT_OK=(
	    'Port2stream', # streams of chars
	      'Port2linestream', # streams of lines
	   );

use strict;
#use Chj::FP::lazy 'Delay';#lustig ist funktion bei perl.  wobei geht schneller direkt
use Chj::FP::Promise;
# to avoid having to use the thing lambda-lifted, use weak references:
use WeakRef;

sub p2s {
    my ($port,$portget,$fnname)=@_; # "coderef", msgstr
    my $lp;
    $lp= sub {#<--TODO!!!:fix LEAK
	# this is all hacky, only for performance reasons inlined here.
	bless [
	       0, #unevaluated
	       sub {
		   #warn "getting..";
		   my $c= $portget->($port);
		   #warn "got '$c'";
		   if (defined $c) {
		       #OH shit gc problems?kommen to mind
		       bless [$c, &$lp], "Chj::FP::Pair"
		   } else {
		       if (eof($port)) {
			   $Chj::FP::EmptyList
		       } else {
			   die "$fnname($port): $!";#
		       };
		   }
	       }
	      ], "Chj::FP::StreamPromise";
    };
    my $_lp=$lp; weaken $lp;
    &$_lp
}

sub mk_P2s {
    my ($default_getc,$getc_methodname,$fnname)=@_;
    sub {
	my ($port)=@_;
	my $maybe_getc= UNIVERSAL::can($port,$getc_methodname);
	p2s($port, $maybe_getc||$default_getc, $fnname)
    }
}

*Port2stream= mk_P2s(sub{ getc($_[0]) }, "getc", "Port2stream");
*Port2linestream= mk_P2s(sub{ readline($_[0]) }, "readline", "Port2linestream");


{
    # so as to provide car and cdr directly on the stream?: (stream-car/-cdr)
    package Chj::FP::StreamPromise;
    use Carp;
    use Chj::FP::Promise -extend=>();
    use Chj::FP::Pair;
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
