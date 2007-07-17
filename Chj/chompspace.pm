# Wed Aug  4 13:05:02 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::chompspace

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::chompspace;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(chompspace);
#@EXPORT_OK=qw();
use strict;

sub chompspace($ ) {
    my ($str)=@_;
    $str=~ s/^\s+//s;
    $str=~ s/\s+\z//s;
    $str
}

*Chj::chompspace= \&chompspace;

1;
