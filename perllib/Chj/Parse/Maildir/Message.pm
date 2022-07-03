#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Parse::Maildir::Message

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Maildir::Message;

use strict; use warnings FATAL => 'uninitialized';

use Chj::FP::Predicates;

use Chj::Struct [[instance_ofP("Chj::Parse::MailboxCursor"), "cursor"],
		 "maybe_mailbox_unixtime",
		 [\&nonnullstringP, "index"]],
  "Chj::Parse::MailboxMessage";
# index is multi-level when coming from ezmlm archives: e.g. "0-01",
# or the "13733_13" part for a file like 1414796255.13733_13.mbox

sub as_string {
    my $s=shift;
    $s->cursor->message_as_string
}


_END_
