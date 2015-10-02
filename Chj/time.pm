#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::time - overridable time

=head1 SYNOPSIS

 use Chj::time; # exports 'time'

 my $t= time; # real time (integer unix epoch seconds value)
 use Chj::time '$time';
 local $time= $t - 1000;
 my $t1= time; # 1000 seconds in the past
 sleep 10;
 my $t2= time; # same as $t1, now 1010 seconds in the past

=head1 DESCRIPTION


=cut


package Chj::time;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(time);
@EXPORT_OK=qw($time);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

our $time;

sub time () {
    $time // CORE::time()
}

1
