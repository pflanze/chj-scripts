# Mon May 24 17:15:23 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vservers

=head1 SYNOPSIS

 my @vservers= Chj::Vservers->new->all_running;
 # or even: since we don't really have any data to put into the Vservers object:
 # my @vservers= Chj::Vservers->all_running;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item all_running

Returns list of all running vservers as Chj::Vserver objects in list context,
or an iterator in scalar context.

=back

=cut


package Chj::Vservers;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
use strict;

use Class::Array -fields=> ();

sub all_running {
    my $proto=shift;
    

1;
