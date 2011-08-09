#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Logtimed

=head1 SYNOPSIS

=head1 DESCRIPTION

Exactly same as Chj::Logsimple, but prefixes each line with the
current unix time.

=cut


package Chj::Logtimed;
@ISA="Chj::Logsimple"; require Chj::Logsimple;

use strict;

sub x {
    my $s=shift;
    $s->SUPER::x(scalar time,@_)
}

1
