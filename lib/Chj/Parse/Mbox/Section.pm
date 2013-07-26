#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parse::Mbox::Section

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a section of an mbox by way of reference (file path and
positions within the file); assumes that the source file doesn't
change!

=cut


package Chj::Parse::Mbox::Section;

use strict;

use Chj::xopen 'xopen_read';

use Chj::Struct ["mboxpath",
		 "from", # incl
		 "to", # excl
		];


sub xsendfile_to {
    my $s=shift;
    my ($fd)=@_;
    my $in= xopen_read ($s->mboxpath);
    #$in->xsendfile_to($fd, $s->from, ($s->to - $s->from));
    #XX BUG in xsendfile_to; try instead:
    $in->xseek($s->from);
    $in->xsendfile_to($fd, 0, ($s->to - $s->from));
    $in->xclose;
}


_END_
