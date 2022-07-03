# Thu Jan 22 01:37:33 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Algo::CircularWraparound

=head1 SYNOPSIS

=head1 DESCRIPTION

#The given inputs must support the <, >, + and - operations. The result of the - operation must be a number.
more precisely: numify must return a number, which is used for distance calculations.
< and > can be saved, it just uses the numify value.

#"The max and min values are inclusive"  ?
note that you are responsible for giving values inside range. and note that if you use both boundary values, that they are *not* treated equal, thus circwrap(max,min,max,min) returns 1, not 0.

=cut


#package Chj::Algo::Number::CircularWraparound;
package Chj::Algo::CircularWraparound;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      circularwraparound
	      circwrap
	     );
use strict;
use utf8;


sub circularwraparound {# circular_wraparound.  circwrap.
    my ($old,$new,$max,$min);
    # numify:
    if (@_>=4) {
	($old,$new,$max,$min)=map { $_ + 0 } @_;
    } else {
	($old,$new,$max)=map { $_ + 0 } @_[0..2];
	$min=0;
    }

    #$new= $new % $max;
    #$old= $old % $max;
    # ach ne: dann wird 12 zu 0 und (12,2) gibt keinen wrap mehr an.

    if ($new > $old) {
	my $distance= $new - $old;
	if ($distance > (($max-$min)/2)) {
	    # downwrap
	    -1
	} else {
	    0
	}
    } else {
	my $distance= ($new + ($max-$min)) - $old;
	if ($distance > (($max-$min)/2)) {
	    0
	} else {
	    # upwrap
	    1
	}
    }
}
*circwrap= \&circularwraparound;



1;
__END__
    # muss checken ob die argumente im bereich liegen?  12 > 0 ist bei max==12 bereits schlecht. denn 12 ist nicht < max.
    #if ($new < $max) {
    ## ok
    #} else {
    ##hmmm.
    # na, behelfskrücke unten machen?  aber hey, distance rechnen muss eh zahlen ausgeben. also:
