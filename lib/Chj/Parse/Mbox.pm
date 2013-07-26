#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parse::Mbox

=head1 SYNOPSIS

 use Chj::Parse::Mbox 'mbox_stream_open';
 use Chj::FP2::Stream ":all";
 stream_for_each sub {
    my ($t,$lines,$cursor)= @{$_[0]};
    ... @$lines ...
    # $cursor is a Chj::Parse::Mbox::Cursor object
 }, mbox_stream_open "some/path.txt"

=head1 DESCRIPTION

Mbox parser that

 - does not have problems dealing with pseudo mboxes holding some
   mailing list archives

 - parses the date in the "From " separator lines if present and
   parseable

It delivers the result as a stream (lazy list).

It does not turn occurrences of '>From ' into 'From ' as some other
mbox parsers do, because that's not a safe operation to do (it is not
a form of escaping, it is mangling (non-reversible)). A plain text
body parser receiving the output of Chj::Parse::Mbox can be better
prepared to decide whether a particular '>' needs to be removed or
not, depending on context.

It uses /\nFrom .*\n/ as the separator format, unlike /\n\nFrom .*\n/
as jwz recommends; some of the archives do *not* have an empty line
before the next separator thus the former has to be done (also
interestingly, this seems to be what Mail::Box::Mbox does, at least
both lead to the same amount of trailing newlines in the parsed
messages).

=cut


package Chj::Parse::Mbox;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(mbox_stream_read mbox_stream_open);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use Chj::xopen 'xopen_read';
use Chj::FP2::List ':all';
#use Chj::FP2::Stream ':all';
use Chj::FP2::Lazy;
use Chj::Chomp;
use Date::Parse 'str2time';
use Chj::Parse::Mbox::Section;


sub msgchomp {
    # remove the last newline since it is really part of the
    # separator; destructive op
    my ($lines)=@_;
    if ($$lines[-1] =~ /^\r?\n\z/s) {
	pop @$lines;
    } else {
	$$lines[-1]=~ s/\r?\n\z//s
    }
    $lines
}

sub mbox_stream_read {
    my ($f, $maybe_lastline, $startpos)=@_;
    Delay {
	my $sep= $maybe_lastline || <$f>;
	if (defined $sep) {
	    my ($rest)= $sep=~ /^From (.*)/
	      or die "expected separator, got: '".Chomp($sep)."'";
	    my $t= (sub {
		if (my ($rest1)= $rest=~ /^\s*\S+\@\S+\s+(.*)/) {
		    if (my $t=str2time $rest1) {
			return $t
		    }
		}
		undef
	    })->();
	    my @lines;
	    my $pos= $startpos + length($sep);
	    local $_;
	    my $endofmessage= sub {
		my ($lastline)=@_;
		my $section= Chj::Parse::Mbox::Section->new_
		  (mboxpath=> $f->path,
		   from=> $startpos,
		   to=> $pos);
		return cons( [$t, msgchomp(\@lines), $section],
			     mbox_stream_read ($f, $lastline, $pos));
	    };
	    while (<$f>) {
		if (/^From /) {
		    @_=($_); goto $endofmessage;
		}
		push @lines, $_;
		$pos+= length($_);
	    }
	    @_=(undef); goto $endofmessage
	} else {
	    $f->xclose;
	    undef
	}
    }
}

sub mbox_stream_open {
    my ($path)=@_;
    mbox_stream_read( xopen_read $path);
}


1
