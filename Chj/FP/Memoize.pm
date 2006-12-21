# Fri Oct 28 23:58:24 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Memoize

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 SEE ALSO

for a non-functional (and bigger) variant: Memoize.pm

=cut


package Chj::FP::Memoize;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(memoize_thunk memoize_1ary);

use strict;
use Carp;

sub memoize_thunk {
    @_==1 or croak "expecting 1 argument, got ".@_;
    my ($L)=@_;
    my $value;
    my $did_calculate;
    sub {
	$did_calculate ?
	  $value
	    : do { $value= &$L; $did_calculate=1; $value };
    }
}

sub memoize_1ary {
    my ($L)=@_;
    my %value;
    sub {
	(exists $value{$_[0]}) ?
	  $value{$_[0]}
	    : ($value{$_[0]}= &$L);
    }
}


1
