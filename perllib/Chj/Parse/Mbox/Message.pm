#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Parse::Mbox::Message

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Mbox::Message;

use strict; use warnings FATAL => 'uninitialized';

use Chj::Struct ["cursor", "lines", "maybe_mailbox_unixtime", "index"],
  # cursor will actually be a Chj::Parse::Mbox::Section
  "Chj::Parse::MailboxMessage";

sub as_string {
    my $s=shift;
    join("", @{$s->lines})
}

_END_
