#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::pid - overridable process id

=head1 SYNOPSIS

 use Chj::pid; # exports 'pid'

 my $pid= pid; # same as $$
 use Chj::pid '$pid';
 local $pid= 1234;
 my $pid1= pid; # 1234

=head1 DESCRIPTION


=cut


package Chj::pid;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pid);
@EXPORT_OK=qw($pid);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

our $pid;

sub pid () {
    $pid // $$
}

1
