# Fri Sep  2 03:47:16 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Cluckall

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Cluckall;

use strict;
use Carp 'cluck';

$SIG{__WARN__}= sub {
    print STDERR "(warn) ";
    cluck @_;
};

1
