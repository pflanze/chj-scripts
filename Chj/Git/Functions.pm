# Sun Jun 15 19:57:53 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Git::Functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Git::Functions;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
	      maybe_git_rev_parse
	      xgit_rev_parse
	      xgit_name_rev
	      is_ancestor_of
	      maybe_git_dir
	      xgit_dir
	      git_merge_base__all
	     );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::singlequote "singlequote_many";
use Carp;
sub _UndefThrowing ( $ $ ) {
    my ($routine, $message)= @_;
    sub {
	# assuming scalar context
	my $res= &$routine; # Oerr..but not the function I wrote there..
	defined ($res) ? $res : croak $message.singlequote_many(@_)
    }
}

use Chj::IO::Command;

sub maybe_git_rev_parse ( $ ) {
    my ($str)=@_;
    my $in= Chj::IO::Command->new_combinedsender
      ('git','rev-parse', '--verify', $str);
    my $cnt= $in->xcontent;
    my $rv= $in->xfinish;
    if ($rv == 0) {
	chomp $cnt;
	$cnt;
    } elsif ($rv == 128<<8) {
	## strange that blobs also do parse successfully. anyway,
	## leave it at that for now.
	undef
    } else {
	croak "git rev-parse exited with error $rv"
    }
}

*xgit_rev_parse= _UndefThrowing(\&maybe_git_rev_parse,
				"given revision could not be resolved");
##is this a good message? "fatal: Needed a single revision" is what
##git-rev-parse returns


##grr almost copy-paste of the above:
sub xgit_name_rev ( $ ) {
    my ($str)=@_;
    my $in= Chj::IO::Command->new_combinedsender('git','name-rev', $str);
    my $cnt= $in->xcontent;
    my $rv= $in->xfinish;
    if ($rv == 0) {
	chomp $cnt;
	$cnt;
    } else {
	croak "git name-rev exited with error $rv"
    }# actually *shold* do as nice as above right.
}

sub is_ancestor_of {
    my ($commit1,$commit2,$verbose)=@_;
    ($commit1,$commit2)=
      map { xgit_rev_parse ($_) }
	($commit1,$commit2);

    if ($verbose) {
	print( "     searching for: ".xgit_name_rev($commit1)."\n".
	       " in the history of: ".xgit_name_rev($commit2), "\n");# or die;
    }

    my $in= Chj::IO::Command->new_sender('git', 'log',
					 '--pretty=format:%H %P', $commit2);
    ## ^ HMMMM could just have used git rev-list instead ?! (ok my %P
    ## trick will short cut it a bit in some cases)
    while (<$in>) {
	chomp;
	for my $sha1 (split /\s+/, $_) {
	    if ($commit1 eq $sha1) {
		my $rv= $in->xfinish;
		# bad, basically COPY from cj-git-l (and yep the state
		# keeping there is weird hehe)
		($rv == 0
		 or $rv == 141<<8
		 or $rv == 13)
		  or die "git-log exited with status $rv";
		return 1
	    }
	}
    }
    $in->xxfinish;
    return 0;
}


sub maybe_git_dir () {
    my @cmd= qw(git rev-parse --git-dir);
    my $in= Chj::IO::Command->new_combinedsender(@cmd);
    my $cnt= $in->xcontent;
    my $rv= $in->xfinish;
    # again this dispatch, hm.
    if ($rv == 0) {
	chomp $cnt;
	$cnt
    } elsif ($rv == 128<<8) {
	$cnt=~ /not a git rep/i or die "non-expected failure message '$cnt'";
	undef
    } else {
	die "command @cmd failed with exit code $rv";
    }
}

*xgit_dir= _UndefThrowing (\&maybe_git_dir,
			   "not a git repository");


sub git_merge_base__all ($ $ ) {
    my ($a,$b)=@_;
    my $cmd= Chj::IO::Command->new_sender
      ("git", "merge-base", "--all", $a, $b);
    my @ancest= <$cmd>;
    chomp @ancest;
    my $res= $cmd->xfinish;
    $res==0 or $res==256 or die "merge-base gave $res";
    @ancest
}

1
