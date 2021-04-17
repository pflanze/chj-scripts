# Fri Aug 20 02:03:24 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Shelllike::touch_r

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Shelllike::touch_r;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(touch_r);
use strict;
use Carp;

sub touch_r($ $ ) {
    my ($from,$to)=@_;
    my @s=stat $from  # lstat? no, touch -r takes the target time. and sets the time of the target of the target item. which utime is doing, heh.
      or croak "touch_r: stat '$from': $!";##(sollte ich mein quote ding nehmen überall nun?)
    utime $s[8],$s[9],$to
      or croak "touch_r: utime '$to': $!";
}

1;
