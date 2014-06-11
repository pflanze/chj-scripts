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

use strict;

use Chj::Struct ["cursor", "maybe_t"];

sub as_string {
    my $s=shift;
    $s->cursor->message_as_string
}

_END_
