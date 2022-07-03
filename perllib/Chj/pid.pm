#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::pid - overridable process id

=head1 SYNOPSIS

 use Chj::pid; # exports 'pid'

 my $pid= pid; # same as $$

 use Chj::pid qw(pid set_pid);
 set_pid 1234;
 # or dynamically scoped:
 with_pid 1234, sub {
     my $pid1= pid; # 1234
 };

=head1 DESCRIPTION

Overridable process id value for deterministic testing.

=head1 SEE ALSO

L<Chj::time>

=cut


package Chj::pid;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pid);
@EXPORT_OK=qw($pid set_pid);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

our $pid;

sub pid () {
    $pid // $$
}

sub set_pid ($) {
    ($pid)=@_;
}

sub with_pid ($$) {
    my($v,$thunk)=@_;
    local $pid=$v;
    &$thunk()
}

1
