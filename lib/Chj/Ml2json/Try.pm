#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Ml2json::Try

=head1 SYNOPSIS

 use Chj::Ml2json::Try;
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


package Chj::Ml2json::Try;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Try);
@EXPORT_OK=qw(IfTryScalar);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Data::Dumper;
use Carp;

sub global::warn {
    carp @_;
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
	    carp "WARN[$ctxstr]: @_";
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
    IfTryScalar $thunk,$ctx, \&noop,\&noop
}



1
