# Sat Mar 31 14:39:23 2007  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::VserverSettings

=head1 SYNOPSIS

=head1 DESCRIPTION

Some basic values for accessing Vserver data.

=cut


package Chj::VserverSettings;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      $etcbase
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

our $etcbase= "/etc/vservers";


1
