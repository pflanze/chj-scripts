# Sat Oct  8 18:53:42 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::username

=head1 SYNOPSIS

=head1 DESCRIPTION

Weil (grrr) unter cron $ENV{USER} nicht gesetzt ist, eben dies hier machen.
Das $< verwendet wenn env nicht gesetzt. (oder andere env vars anschaut evtl.)

=cut


package Chj::username;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(username);

use strict;

sub username {
    $ENV{USER} || scalar getpwuid($<)
}
