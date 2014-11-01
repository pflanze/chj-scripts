#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parse::Maildir

=head1 SYNOPSIS

 use Chj::Parse::Maildir 'maildir_open_stream';
 use Chj::FP2::Stream ":all";
 stream_for_each sub {
    my ($m)= @_;
    # a Chj::Parse::Maildir::Message object
 }, maildir_open_stream "some/path" #, $sorting_comparison


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
	      ezmlm_archiveP
	      maildir_mtime);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::FP2::IOStream ':all'; # xopendir_pathstream etc.
use Chj::FP2::Stream;
use Chj::FP2::Lazy;
use Chj::FP2::List ':all';
use Chj::xperlfunc 'basename', 'xLmtimed', 'max';
use Chj::Parse::Maildir::Cursor;
use Chj::Parse::Maildir::Message;
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

sub maildir_mtime ($) {
    my ($dirpath)=@_;
    if (maildirP $dirpath) {
	# XX careful, same as comment for maildirP
	max map {
	    my $path= "$dirpath/$_";
	    my $s= xLmtimed $path;
	    $s->is_dir or die "not a dir: $path";
	    $s->mtime
	} "new", "cur" # , "tmp" ?
    }
    elsif (ezmlm_archiveP $dirpath) {
	max (map {
	    my ($subdirpath)= $_;
	    my $s= xLmtimed($subdirpath);
	    if ($s->is_dir) {
		$s->mtime
	    } else {
		WARN "ignoring non-dir item in ezmlm archive: '$subdirpath'"
	    }
	} glob "$dirpath/*")
    }
    else {
	die "don't know how to get mtime for '$dirpath'";
    }
}

sub _mappath {
    my ($path, $maybe_index)=@_;
    my $name= basename $path;
    my ($maybe_t, $maybe_index2)= $name=~ m|^(\d{8,11})\.([0-9_]+)?|;
    # (^ year-xx problem in ~1970, and then in ~2200 or something?)
    Chj::Parse::Maildir::Message->new_
	(cursor=> Chj::Parse::Maildir::Cursor->new($path),
	 maybe_mailbox_unixtime=> $maybe_t,
	 # XXX: $maybe_index2 is not independent from other Maildirs,
	 # thus using it won't be safe in general!
	 index=> $maybe_index // $maybe_index2)
}

sub _stream_mappath ($) {
    my ($s)=@_;
    stream_map \&_mappath, $s
}

sub maildir_open_stream ($;$) {
    my ($maildirpath,$maybe_sort_cmp)=@_;
    # is it a normal Maildir or something like a ezmlm archive?
    if (maildirP $maildirpath) {
	_stream_mappath
	  # XXX this breaks sorting on the new/cur boundary
	  stream_append (xopendir_pathstream ("$maildirpath/new",$maybe_sort_cmp),
			 xopendir_pathstream ("$maildirpath/cur",$maybe_sort_cmp));
    } elsif (ezmlm_archiveP $maildirpath) {
	(stream_fold_right sub {
	     my ($item0,$rest)=@_;
	     if ($item0=~ /^\d{1,}$/s) {
		 (stream_fold_right sub {
		      my ($item,$rest)=@_;
		      my $path= "$maildirpath/$item0/$item";
		      if ($item eq "index") {
			  # ignore
			  $rest
		      } elsif ($item=~ /^\d{2,}$/s) {
			  cons _mappath($path, "$item0-$item"), $rest
		      } else {
			  WARN "apparent ezmlm archive contains unusual file, ignored: '$path'";
			  $rest
		      }
		  },
		  $rest,
		  xopendir_stream "$maildirpath/$item0", $maybe_sort_cmp)
	     } else {
		 WARN "apparent ezmlm archive contains unusual subdir/item, ignored: '$item0'";
		 $rest
	     }
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
