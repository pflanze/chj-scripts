#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Try

=head1 SYNOPSIS

 use Chj::Try;
 Try {
    global::warn("hello");
    die "bar";
    global::warn("baz");
 } "foo"; # "foo" could be an object with an 'identify' method
 global::warn "done";

 #=>
 # WARN['foo']: hello
 # ERROR['foo']: bar
 # done

=head1 DESCRIPTION


=cut


package Chj::Try;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Try);
@EXPORT_OK=qw(IfTryScalar);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Data::Dumper;
use Carp;

sub global::warn {
    my $first= $_[0];
    if (defined $first and ref ($first) eq "KIND") {
	my $kind= $$first;
	shift;
	carp "${kind}: ", @_;
    } else {
	carp @_;
    }
}

sub ctx2str {
    my ($ctx)=@_;
    if (my $identify= UNIVERSAL::can($ctx,"identify")) {
	&$identify($ctx)
    } else {
	my $str= Dumper($ctx);
	$str=~ s/^\$VAR1 = //;
	$str=~ s/;\n\z//s;
	$str
    }
}

sub IfTryScalar {
    my ($thunk,$ctx,$success,$fail)=@_;
    my $ctxstr;
    my $res;
    if (eval {
	no warnings 'redefine';
	local *global::warn= sub {
	    $ctxstr||= ctx2str ($ctx);
	    my $first= $_[0];
	    my ($kind,@rest)=
	      ((defined $first and ref ($first) eq "KIND")
	       ? ($$first, @_[1..$#_])
	       : ("WARN", @_));
	    carp "${kind}[$ctxstr]: ",@rest;
	};
	$res= &$thunk;
	1
    }) {
	@_=($res); goto $success
    } else {
	my $e=$@;
	$ctxstr||= ctx2str ($ctx);
	carp "ERROR[$ctxstr]: $e";
	@_=(); goto $fail
    }
}

sub noop {
    ()
}

sub Try (&$) {
    my ($thunk,$ctx)=@_;
    my $wantarray= wantarray;
    if (defined $wantarray) {
	IfTryScalar sub {
	    $wantarray ? [&$thunk] : scalar &$thunk
	}, $ctx, sub {
	    my ($a)=@_;
	    $wantarray ? @$a : $a
	},\&noop
    } else {
	IfTryScalar $thunk,$ctx, \&noop,\&noop
    }
}

# main> :d @foo=(1,3,4); Try { @foo } "foo"
# $VAR1 = 1;
# $VAR2 = 3;
# $VAR3 = 4;
# main> :d @foo=(1,3,4); scalar Try { @foo } "foo"
# $VAR1 = 3;


1
