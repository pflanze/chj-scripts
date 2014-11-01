#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Parse::MailboxMessage

=head1 SYNOPSIS

=head1 DESCRIPTION

baseclass for Chj/Parse/*/Message.pm

=cut


package Chj::Parse::MailboxMessage;

use strict; use warnings FATAL => 'uninitialized';

use Chj::Struct [];

sub mailbox_unixtime {
    my $s=shift;
    $s->maybe_mailbox_unixtime // die "message does not carry a mailbox_unixtime"
}


_END_
