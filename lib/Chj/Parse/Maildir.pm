#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parse::Maildir

=head1 SYNOPSIS

 use Chj::Parse::Maildir 'maildir_stream_open';
 use Chj::FP2::Stream ":all";
 stream_for_each sub {
    my ($t,$lines,$cursor)= @{$_[0]};
    ... @$lines ...
    # $cursor is a Chj::Parse::Maildir::Cursor object
 }, maildir_open_stream XXX "some/path"


=head1 DESCRIPTION

NOTE: the stream is *not* sorted by any part of the filenames or
contents. It is returned in the order that the operating system
returns the files from readdir, while, in the care of standard
Maildirs, first returning the entries in new/ then in cur/. Similarly
for other dirs like ezmlm archives, it doesn't enforce any ordering.

=cut


package Chj::Parse::Maildir;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(maildir_open_stream
	      maildirP
	      ezmlm_archiveP);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::FP2::IOStream ':all'; # xopendir_pathstream etc.
use Chj::FP2::Stream;
use Chj::FP2::Lazy;
use Chj::FP2::List ':all';
use Chj::xperlfunc 'basename';
use Chj::Parse::Maildir::Cursor;
use Chj::NoteWarn;


sub maildirP ($) {
    my ($dirpath)=@_;
    -d "$dirpath/new" and -d "$dirpath/cur"
      # XX careful: can contain other maildirs, too, so don't just
      # maildir_open_stream $dirpath and be done with it... XXX ah:
      # should extend maildir_open_stream to recurse itself?
}

sub ezmlm_archiveP ($) {
    my ($dirpath)=@_;
    -d "$dirpath/0"
      # and -f "$dirpath/0/01" or so?
      # readdir and stat and look at filenames and no subdirs?
}

sub _mappath {
    my ($path)=@_;
    my $name= basename $path;
    my ($maybe_t)= $name=~ m|^(\d{8-11})\.|;
    # (^ year-xx problem in ~1970, and then in ~2200 or something?)
    my $lines= undef; ## or is it really used ?
    my $cursor= Chj::Parse::Maildir::Cursor->new($path);
    [$maybe_t,$lines,$cursor]
}

sub _stream_mappath ($) {
    my ($s)=@_;
    stream_map \&_mappath, $s
}

sub maildir_open_stream ($) {
    my ($maildirpath)=@_;
    # is it a normal Maildir or something like a ezmlm archive?
    if (maildirP $maildirpath) {
	_stream_mappath
	  stream_append (xopendir_pathstream "$maildirpath/new",
			 xopendir_pathstream "$maildirpath/cur");
    } elsif (ezmlm_archiveP $maildirpath) {
	(stream_fold_right sub {
	     my ($item0,$rest)=@_;
	     (stream_fold_right sub {
		  my ($item,$rest)=@_;
		  my $path= "$maildirpath/$item0/$item";
		  if ($item eq "index") {
		      # ignore
		      $rest
		  } elsif ($item=~ /^\d{2,}$/s) {
		      cons _mappath($path), $rest
		  } else {
		      WARN "apparent ezmlm archive contains unusual file, ignored: '$path'";
		      $rest
		  }
	      },
	      $rest,
	      xopendir_stream "$maildirpath/$item0")
	 },
	 undef,
	 xopendir_stream $maildirpath)
    } else {
	NOTE "dir seems to be neither a standard Maildir nor an ezmlm archive: '$maildirpath'";
	_stream_mappath
	    xopendir_pathstream $maildirpath;
	# OR recurse through all subdirs but stop recursing deeper
	# than where files are found?
    }
}


1
