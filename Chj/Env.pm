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
@EXPORT=qw(pp_through);

use strict;
use Data::Dumper;
use Carp;

sub pp_through {
    carp "pp_through:  <-";
    print STDERR Dumper @_;
    wantarray ? @_ : $_[-1] ##hmnm
}


1
