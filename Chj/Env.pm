# Sun Oct  9 07:54:23 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Env

=head1 SYNOPSIS

=head1 DESCRIPTION

stuff like in my cj-env module hehe.

=cut


package Chj::Env;
@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
@EXPORT=qw(
	   pp_through
	   min
	   max
	   zip
	   zipall
	  );

use strict;
use Data::Dumper;
use Carp;

sub pp_through {
    carp "pp_through:  <-";
    print STDERR Dumper @_;
    wantarray ? @_ : $_[-1] ##hmnm
}

sub max {
    return () unless @_;
    my $res=shift;
    for (@_) {
	if ($_>$res) {
	    $res=$_
	}
    }
    $res
}

sub min {
    return () unless @_;
    my $res=shift;
    for (@_) {
	if ($_<$res) {
	    $res=$_
	}
    }
    $res
}

sub _Mkzip {
    my ($minmax)=@_;
    sub {
	my $width=@_;
	my $len= &$minmax( map { scalar @$_ } @_ );
	my @res;
	for (my $i=0; $i<$len; $i++) {
	    push @res, [ map { $$_[$i] } @_ ]
	}
	\@res
    }
}

*zip= _Mkzip \&min;
*zipall= _Mkzip \&max;



1
