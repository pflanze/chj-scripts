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

use Chj::Struct ["cursor", "maybe_mailbox_unixtime", "maybe_index"];
# index is multi-level when coming from ezmlm archives: e.g. "0-01"

sub as_string {
    my $s=shift;
    $s->cursor->message_as_string
}

sub index {
    my $s=shift;
    # can '//' be used now?
    $s->maybe_index // die "message does not have an index"
}

_END_
