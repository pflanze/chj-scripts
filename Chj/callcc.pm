#
# Copyright 2009 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::callcc

=head1 SYNOPSIS

 use Chj::callcc;
 my $rec;
 callcc
   (sub {
	my ($exit)=@_;
	$rec= sub {
        ....
    },
    # optional cleanup:
    sub {
	undef $rec;#free storage
    })


=head1 DESCRIPTION

A one-shot call-with-current-continuation implementation (built using
die).

=cut


package Chj::callcc;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(callcc);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub callcc { # outwards only.
    (@_>=1 and @<=2) or die "wrong number of values";
    # not taking @cleanup_args, 'since that would be C style', well, rather: since we *can* pass closures, this is to be the right, eh preferred way (heh, Python is doing it OO (wl aka C style) not closure here (since non-modifiable bindings))
    my ($cont,$maybe_cleanup)=@_; #well. cont to pass cont, so to say.
    my $marker= []; #use for identity checking.
    #^ fill in something to help debugging?
    my $is_marker= sub {
	my ($v)=@_;
	ref ($v) eq "ARRAY" and $v eq $marker
    };
    my $is_return_exception= sub {
	my ($v)=@_;
	ref ($v) eq "ARRAY" and @$v==2 and &$is_marker($$v[0])
    };
    my $not_exception=0;
    my $wantarray=wantarray;
    my $res= eval { #well do the usual wantarray circus ?
	my @res= do {
	    my $exit= sub {
		@_==1 or die "expecting 1 value";
		#wel accept any number of values  ? but then, how to  cdr ... (nest arrays? why not: flat like noncurried procs)
		my ($v)=@_;
		die [$marker, $v]
	    };
	    if ($wantarray) {
		&$cont ($exit)
	    } else {
		scalar &$cont ($exit)
	    }
	};
	$not_exception=1;
	\@res
    };
    my $e=$@;
    if ($maybe_cleanup) {
	&$maybe_cleanup()
    }
    if ($not_exception) {
	$wantarray ? @$res : $$res[-1] #correct -1?
    } else {	
	if (ref($e) or $e) {
	    if (&$is_return_exception($e)) {
		$$e[1]
	    } else {
		die $e
	    }
	} else {
	    die "lost an exception"
	}
    }
}


1
