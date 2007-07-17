# Sun Apr 24 13:08:42 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::schemestring

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::schemestring;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(schemestring);

use strict;

sub schemestring{
    my ($s)=@_;
    $s=~ s/\\/\\\\/sg;
    $s=~ s/\"/\\\"/sg;
    "\"$s\""
}

*Chj::schemestring= \&schemestring;

1
