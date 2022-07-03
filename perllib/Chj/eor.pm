# Fri Jan 21 22:14:28 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::eor

=head1 SYNOPSIS

 use Chj::eor;
 my $opt_toggle=shift;
 my $dosomething=(shift eq 'fun');
 if (eor( $opt_flag , $dosomething)) {
     print "nice\n";
 }

=head1 DESCRIPTION

Some like assembler. Dunno what do do else.

=cut


package Chj::eor;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(eor);

use strict;

sub eor {
    my $t;#=shift;
    while (@_) {
        my $s=shift;
        $t=  ($t and $s)? 0 : ($t or $s);
    }
    $t
}

*Chj::eor= \&eor;

1
