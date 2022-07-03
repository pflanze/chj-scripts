# Tue May 27 23:39:22 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Linux::Time

=head1 SYNOPSIS

=head1 DESCRIPTION

Access to special time values from linux (mainly /proc).

=head1 FUNCTIONS

=over 4

=item uptime()

=item jiffies()

=back

=cut


package Chj::Linux::Time;
@ISA="Exporter";
@EXPORT_OK=qw(uptime jiffies);
require Exporter;
use strict;
use Chj::xopen;

sub uptime {
    my (@times)= (xopen "/proc/uptime")->xcontent =~ /(\d+\.\d*)\s*(\d+\.\d*)/ or die "invalid /proc/uptime format";
    wantarray ? @times : @times[0]  ##  JA was sind die beiden schon wieder?
}

sub jiffies {
    die "unimplemented"
}

1;
