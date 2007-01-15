# Mon Jan 15 13:45:53 2007  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Collection

=head1 SYNOPSIS

=head1 DESCRIPTION

Interface common ?  for  minus etc handling.  on hashes foretc.

..but: we're using functions now (multidispatch as alternative?), so how call it an interface. well how call it in the firstplac.?

yep only works on hashes for now.

Does not modify it's arguments.

=cut


package Chj::Collection;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(Collection_add Collection_subtract);
%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;


sub Collection_add {
    return {} unless @_;
    my $first= shift;
    return $first unless @_;
    my $second= shift;
    @_=({ %$first, %$second },@_);
    goto \&Collection_add;
}

sub Collection_subtract {
    die "not enough arguments" unless @_>=1;
    # now unlike (- x) which returns -x this will return the argument unchanged.
    my $first= shift;
    return $first unless @_;
    my $res={ %$first };
    for (@_) {
	for my $key (%$_) {
	    delete $$res{$key}
	}
    }
    $res
}

1
