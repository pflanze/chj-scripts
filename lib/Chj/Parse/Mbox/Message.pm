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

use strict;

use Chj::Struct ["cursor", "lines", "maybe_mailbox_unixtime", "index"];
# cursor will actually be a Chj::Parse::Mbox::Section

sub as_string {
    my $s=shift;
    join("", @{$s->lines})
}

_END_;
#XXX would aliasing through ref work?before _END_.?
#*maybe_t= *t; # [with no Just wrapper..]

1
