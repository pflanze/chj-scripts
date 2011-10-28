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
	      xgit_describe
	      xgit_describe_debianstyle
	      xgit_stdout_ref
	      maybe_cat_file
	      maybe_cat_tag
	      parse_tag
	      xgit_do
	      make_xgit_do
	      git_unquote_path

	      git_branches_local
	      git_branches_all
	      git_tags

	      status_is_clean
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
	defined ($res) ? $res : croak $message.(@_ ? ": ".singlequote_many(@_) : "")
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
    local $_; #!!!!!!!!!!!
    while (<$in>) {
#	my $str="$_";
#	$_=$str;
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


# functions for querying which just return what the git commands return:

# should be a library function, is just a (curried) safe backtick.
# well re curried: also allow additional arguments to be given.
sub mk_xcommand_output {
    my @cmd=@_;
    sub {
	my $cmd= Chj::IO::Command->new_sender (@cmd,@_);
	my $cnt= $cmd->xcontent;
	$cmd->xxfinish;
	chomp $cnt;
	$cnt
    }
}

*xgit_describe= mk_xcommand_output ("git","describe");

sub xgit_describe_debianstyle {
    my $desc= xgit_describe(@_);
    $desc=~ s/^v//
      or die "missing v at the beginning of expected tag name: '$desc'";
    $desc=~ s/-/./sg;
    $desc
}

use Chj::xperlfunc 'xxsystem';

sub xgit_do {
    xxsystem "git",@_
}

# an xgit_do that polls the lock file (workaround for apparent Git race bug)
sub make_xgit_do {
    my $base= xgit_dir();
    my $lock= "$base/index.lock";
    sub {
	xxsystem "git",@_;
	if (-e $lock) {
	    warn "*** NOTE: index.lock detected, waiting for it to go away";
	    while (-e $lock) {
		sleep 1
	    }
	    warn "    ok continuing.\n";
	}
    }
}

sub xgit_stdout_ref {
    my $t= Chj::IO::Command->new_sender ("git",@_);
    my $rf= $t->xcontentref;
    $t->xxfinish;
    $rf
}

sub maybe_cat_file { # returns content ref, or undef in 'bad file' case (i.e. un-annotated tag), hm, hacky since that only makes sense for cat_tag?
    my ($type,$id)=@_;
    my $t= Chj::IO::Command->new_combinedsender("git","cat-file",$type,$id);
    my $rf= $t->xcontentref;
    my $res= $t->xfinish;
    if ($res==0) {
	$rf
    } else {
	if ($$rf=~ /bad file$/) {
	    undef
	} else {
	    # seems a real error has happened
	    die "git cat-file $type $id exited with code $res and message '$$rf'";
	}
    }
}

sub maybe_cat_tag {
    my ($id)=@_;
    maybe_cat_file ("tag",$id)
}


{
    package Chj::Git::Functions::ParsedTag;
    use Class::Array -fields=> -publica=>
      (qw(name maybe_contentrf maybe_unixtime maybe_tagger is_signed),
       # and for caching:
       '_maybe_unixtime', # promise
       '_sha1', # cache
       '_Dereferenced_type',
      );
    use Chj::FP::Memoize ();# 'memoize_thunk';
    our $sha1_re= qr/\b[0-9a-f]{40}\b/;
    sub new {
	my $cl=shift;
	my $s=bless [@_],$cl;
	$$s[_Maybe_unixtime]=
	  Chj::FP::Memoize::memoize_thunk
	      (sub {
		   if (defined (my $val= $$s[Maybe_unixtime])) {
		       $val
		   } elsif (1) {
		       # the tag either isn't an annotated tag, or is
		       # of the old type which didn't carry a tagger
		       # line. Dereference it to the commit object and
		       # use the commit object's commit time instead.
		       # (Well, we expect it to be a commit, which
		       # isn't necessarily true)
		       my $sha1= $s->dereferenced_sha1;
		       if (my $rf= Chj::Git::Functions::maybe_cat_file ("commit",$sha1)) {
			   $$rf=~ /^committer .* (\d{8,}) +[+-]\d{4} *$/m
			     # is . really not matching \n here? hm seems so, only /s does make . match \n according to man perlre
			     or die "missing committer field in commit '$sha1': '$$rf'";
			   $1
		       } else {
			   0 ## undef
		       }
		   } else {
		       0 ## undef
		   }
	       });
	$s
    }
    sub is_annotated {
	my $s=shift;
	$$s[Maybe_contentrf] and 1
    }
    #*dereferenced_sha1= Mk_dereference ()
    #  sub Mk_dereference ( $ ) {
    #nah it's not that simple. could short-cut the unannotated case but not the others.
    sub dereferenced_sha1 {
	my $s=shift;
	if (defined (my $r= $$s[_Sha1])) {
	    $r
	} else {
	    my $r= do {
		if (my $rf= $$s[Maybe_contentrf]) {
		    # annotated.
		    $$rf=~ /^object ($sha1_re)/m
		      or die "tag object '$$s[Name]' does not carry an object line";
		    $1
		} else {
		    # unannotated tag. use rev-parse
		    my $rf= Chj::Git::Functions::xgit_stdout_ref ("rev-parse", $$s[Name]);
		    $$rf=~ /^($sha1_re)\s*\z/s
		      or die "rev-parse did not return a sha1 for '$$s[Name]': '$$rf'";
		    $1
		}
	    };
	    $$s[_Sha1]= $r;
	    $r
	}
    }
    sub dereferenced_type {
	my $s=shift;
	$$s[_Dereferenced_type] ||= do {
	    my $rf= Chj::Git::Functions::xgit_stdout_ref ("cat-file",
					   "-t",
					   $s->dereferenced_sha1);
	    $$rf=~ /^(\w+)\s*\z/s or die "invalid output '$$rf'";
	    $1
	}
    }
    sub maybe_unixtime {
	my $s=shift;
	&{$$s[_Maybe_unixtime]}
    }
    end Class::Array;
}

sub parse_tag {
    my ($name,$maybe_strrf,$verbose)=@_;
    if (my $strrf= $maybe_strrf) {
	my $is_signed= $$strrf=~ /^-----BEGIN PGP SIGNATURE-----$/m;
	my ($maybe_unixtime,$maybe_tagger)= do {
	    if ($$strrf=~ /^(?:[^\n]+\n)*[Tt]agger ([^\n]*) (\d+) [-+\d]\d+ *\n/s) {
		($2,$1)
	    } else {
		warn "no match for tagger field in tag '$name': '$$strrf'"
		  if $verbose;
		(undef,undef)
	    }
	};
	Chj::Git::Functions::ParsedTag->new($name,$strrf,$maybe_unixtime,$maybe_tagger,$is_signed);
    } else {
	# un-annotated tag
	Chj::Git::Functions::ParsedTag->new($name,undef,undef,undef,0);
    }
}

use Encode 'decode_utf8';

sub git_unquote_path ( $ ) {
    my ($str)=@_;
    if ($str=~ /^\"/) {
	my ($str2)= $str=~ m/^\"(.*)\"\s*\z/
	  or die "invalid quoted string?: '$str'";
	#####HACKY ABSOLUTELI UNCORRECLT fo rnow
	my $s= [ split /\\/, $str2 ];
	my $r= [];
	push @$r, shift @$s;
	# now have to split off the \d+ parts huh.
	#for my $piece (@$s) {
	#need $i+1 access.'doh'
	my $len= @$s;
	my $flag_last_was_backslash=0;
	for (my $i=0; $i<$len; $i++) {
	    my $piece= $$s[$i];
	    if ($piece =~ s/^(\d+)//) {
		push @$r, chr(oct $1), $piece;
	    #} elsif $piece =~ m/^\\/  EHR that can  never happen right? here's the HACK/wrong bit.
	    } else {
		#hmm. ah yep if it is empty?
		# (shoult put this test to above--but doesn't matter except for computational cost)
		if (length $piece) {
		    # backslash before text ? ah, \n and such uuhm.
		    if ($piece=~ s/^([nrt\"])//) {
			my $thing=$1;
			push @$r, do {
			    if ($thing eq "n") {
				"\n"
			    } elsif ($thing eq "r") {
				"\r"
			    } elsif ($thing eq "t") {
				"\t"
			    } elsif ($thing eq '"') {
				$thing
			    } else {
				die "??"
			    }
			}, $piece
		    } else {
			die "unknown text after backslash: '$piece'";
		    }
		} else {
		    # okso it was a backslashed backslash, *except* if it's the last?
		    if ($flag_last_was_backslash) {
			push @$r, "\\";
			$flag_last_was_backslash=0;
		    } else {
			if (length $$s[$i+1]) {
			    push @$r, "\\";
			    $flag_last_was_backslash=1;
			} else {
			    die "backslash at end of string: '$str'";
			}
		    }
		}
	    }
	}
	decode_utf8(join "", @$r)
    } else {
	$str   # correct, are thingies needing unquote always in double quotes?
    }
}


# strange I could swear I did something these (parsing and checking
# for or ignoring '* ') multiple times but I can't even find it in bin
# more than once.

use Chj::Git::Branch;

sub git_branches { # "git branch" 'but' returns 'list'
    my $in= Chj::IO::Command->new_sender ("git","branch",@_);
    my @res;
    while (<$in>) {
	chomp;
	my ($selected, $name)=  /^(\*\s+)?\s*(\S+)$/
	  or die "invalid line '$_'";
	# now what to do with it, some object [with stringify overload?]?
	push @res, Chj::Git::Branch->new($selected, $name);
    }
    $in->xxfinish;
    @res
}

sub git_branches_local {
    git_branches
}

sub git_branches_all {
    git_branches "-a"
}


sub git_tags () {
    my $in= Chj::IO::Command->new_sender ("git","tag","-l");
    my @res;
    while (<$in>) {
	chomp;
	push @res, $_
    }
    $in->xxfinish;
    @res
}


sub status_is_clean {
    my $in= Chj::IO::Command->new_combinedsender( "git","status");
    my $incnt= $in->xcontent;
    my $instatus= $in->xfinish;
    [
     (scalar ((($instatus==(1<<8)) or ($instatus==0))
	      and
	      $incnt=~ /\nnothing to commit .working directory clean/)),
     $incnt
    ]
}


1
