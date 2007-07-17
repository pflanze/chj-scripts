# Mon Apr 21 23:29:43 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::defined_and_length

=head1 SYNOPSIS

 use Chj::defined_and_length;
 if (defined_and_length(@ARGV)) {
    # there are no empty or undefined inputs
 }

=head1 DESCRIPTION

Returns only true, if the given arguments are *all* defined *and*
have a string length > 0.

The false value is "" or () (depending on context), the true value
is all input values (or the first input value in case of list context).

=cut


package Chj::defined_and_length;
@ISA="Exporter";
require Exporter;
@EXPORT="defined_and_length";
use strict;

#sub defined_and_length {
#    !scalar grep { !defined or !length } @_
#}

sub defined_and_length {
    if (!scalar grep { !defined or !length } @_) {
	wantarray ? @_ : $_[0]
    } else {
	wantarray ? () : ""
    }
}

1;
