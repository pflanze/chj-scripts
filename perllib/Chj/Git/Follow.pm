#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Git::Follow

=head1 SYNOPSIS

 Chj::Git::Follow->new_path("./.links2")->paths

=head1 DESCRIPTION

Walk git history to find renames of a given path. Needs to be given
the *current* (newest) path.

=cut


package Chj::Git::Follow;

use strict;

use Class::Array -fields=>
  -publica=>
  'fd', # glg
  ;


our $do_follow_copies=1;
# 0 doesn't make sense?: git will follow copies anyway afterwards (hm
# huh why?), but it will miss outputting the new paths of copies? 
# totally bogus, I mean. hu. (CPU costs are basically the same, for a
# bigger dir anyway.)

use Chj::IO::Command;

sub new_path {
    my $cl=shift;
    @_==1 or die "need path";
    my ($path)=@_;
    my $s= $cl->SUPER::new;
    $$s[Fd]= Chj::IO::Command->new_sender
      ("git","log",
       "--follow",
       "-M40",## provide as option?
       # no -C, ok?
       #"format: " ?? how to output paths?
       "--raw",
       "--",
       $path
      );
    $s
}

sub next_commit {
    my $s=shift;
    # Fail. I did all of this.
    die "no, not that way. I did it once, see there";
}

# instead just parse it all once:

our $mode= qr{\d{6}};
our $hashellipsis= qr{[a-f0-9]{4,37}(?:\.\.\.)?};

sub paths {
    my $s=shift;
    my $fd= $s->fd;
    local $_;
    local $/= "\n"; # hm Perl still can't use regexes here. And
                    # "\ncommit " would loose the last one
    my %path;
    my $commit;
    my $extract= sub {
	my @pathpairs;
	my $comstr= join("", @$commit);
	while ($comstr=~ /\n:$mode $mode $hashellipsis $hashellipsis (T|A|D|M|[RC]\d{1,3})\t([^\n]+)/sg) {
	    push @pathpairs, [$1,$2];
	}
	@pathpairs or die "missing paths in commit: '$comstr'";
	for (@pathpairs) {
	    my ($action,$pathpair)=@$_;
	    my $add_pathpair = sub {
		my @paths= split /\t/, $pathpair;
		@paths==2 or die "'$pathpair' gave ".@paths." paths";
		$path{$_}++ for @paths;
	    };
	    if ($action=~ /^R(\d+)/) {
		# (look at $1 how much it matches? but pointless,
		# should just change -M setting)
		&$add_pathpair;
	    } elsif ($action=~ /^C(\d+)/) {
		&$add_pathpair
		  if $do_follow_copies;
	    } else {
		# register the other items, too, just in case a
		# directory was given? (If a file was given, then this
		# should never give new paths and hence is pointless.)
		# NOTE: there's actually no C case, git log doesn't
		# print these with --follow (for some reason actually
		# not clear to me).
		my @paths= split /\t/, $pathpair;
		@paths==1 or die "'$pathpair' gave ".@paths." paths";
		$path{$_}++ for @paths;
	    }
	}
    };
    while (<$fd>) {
	#warn "got line: '$_'";
	if (/^commit /) {
	    if ($commit) {
		&$extract
	    }
	    $commit=undef;
	}
	push @$commit, $_;
    }
    if ($commit) {
	&$extract
    }
    $fd->xxfinish;
    sort keys %path
}

end Class::Array;
