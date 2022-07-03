#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Parse::Maildir::Cursor

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Maildir::Cursor;

use strict; use warnings FATAL => 'uninitialized';

use Chj::xopen 'xopen_read';

use Chj::Struct ["itempath"], "Chj::Parse::MailboxCursor";

sub xsendfile_to {
    my $s=shift;
    my ($fd)=@_;
    my $in= xopen_read ($s->itempath);
    $in->xsendfile_to($fd);
    $in->xclose;
}

sub message_as_string {
    my $s=shift;
    my $in= xopen_read ($s->itempath);
    my $cntref= $in->xcontentref;
    $in->xclose;
    $$cntref
}

_END_
