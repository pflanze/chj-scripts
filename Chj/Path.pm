#
# Copyright 2011-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Path

=head1 SYNOPSIS

=head1 DESCRIPTION

Not sure why I'm creating something from scratch here.

This doesn't access the file system, and it doesn't resolve
"..". These are things that have to be implemented by the user.

=cut


package Chj::Path;

use strict;

use Class::Array -fields=>
  -publica=>
  'segments', # array of str not containing slashes
  'has_endslash', # bool, whether the path is forcibly specifying a
                  # dir by using a slash at the end (forcing a dir by
                  # ending in "." isn't setting this flag)
  'is_absolute', # bool
  ;


sub new {
    my $cl=shift;
    bless [@_], $cl
}

sub new_from_string {
    my $cl=shift;
    my ($str)=@_;
    my @p= split m{/+}, $str;
    $cl->new(\@p,
	     scalar $str=~ m{/$}s,
	     scalar $str=~ m{^/}s)
}

sub string_without_endslash {
    my $s=shift;
    join("/",@{$$s[Segments]})
}

sub string {
    my $s=shift;
    my $str= $s->string_without_endslash;
    if ($s->has_endslash) {
	if (length $str) {
	    $str."/"
	} else {
	    if ($s->is_absolute) {
		"/"
	    } else {
		# force using ".", XX hmm but yes no other way
		"./"
	    }
	}
    } else {
	if (length $str) {
	    $str
	} else {
	    # PS. if I would split ..,1, then I could do away with
	    # this test (and also some others), right?
	    if ($s->is_absolute) {
		"/"
	    } else {
		"."
	    }
	}
    }
}

# remove "." entries: (leave ".." in, because these cannot be resolved
# without knowing the file system, right?)
sub clean {
    my $s=shift;
    my $cl= ref $s;
    bless [
	   [
	    grep {
		not ($_ eq ".")
	    } @{$$s[Segments]}
	   ],
	   # set forced dir flag if the last segment was a ".", even
	   # if previously it didn't end in "/"
	   ($$s[Has_endslash]
	    or
	    do {
		if (defined (my $last= ${$$s[Segments]}[-1])) {
		    $last eq "."
		} else {
		    0
		}
	    }),
	   @$s[2..$#$s]
	  ], $cl;
}

sub clean_dotdot {
    my $s=shift;
    my @s;
    for my $seg (@{$s->segments}) {
	if ($seg eq "..") {
	    if (@s) {
		pop @s;
	    } else {
		if ($s->is_absolute) {
		    push @s, "..";
		} else {
		    die "can't take '..' of root directory"
		}
	    }
	} else {
	    push @s, $seg
	}
    }
    $s->segments_set (\@s)
}
# (should have those functions without the Path wrapper? Maybe, maybe not.)


sub add_segment { # functionally. hm.
    my $s=shift;
    my ($segment)=@_;
    die "segment contains slash: '$segment'" if $segment=~ m{/};
    my $cl= ref $s;
    bless [
	   [
	    @{$$s[Segments]},
	    $segment
	   ],
	   0, # no forced endslash anymore
	   @$s[2..$#$s]
	  ], $cl;
}

sub add {
    my $a=shift;
    @_==2 or die "wrong number of arguments";
    my ($b, $is_url)=@_; # when is_url is true, it cleans dit
    if ($b->is_absolute) {
	$b
    } else {
	my $c= $a->segments_set([ @{$a->segments}, @{$b->segments} ])->clean;
	$is_url ? $c->clean_dotdot : $c
    }
}

TEST{ Chj::Path->new_from_string("a/b/C")->add( Chj::Path->new_from_string("d/e"), 0 )->string }
  'a/b/C/d/e';
TEST{ Chj::Path->new_from_string("a/b/C")->add( Chj::Path->new_from_string("../d/e"), 0 )->string }
  'a/b/C/../d/e';
TEST{ Chj::Path->new_from_string("a/b/C")->add( Chj::Path->new_from_string("../d/e"), 1 )->string }
  'a/b/d/e';
TEST{ Chj::Path->new_from_string("a/b/C")->add( Chj::Path->new_from_string("/d/e"), 1 )->string }
  '/d/e';


sub dirname { # functional
    my $s=shift;
    my $seg= $$s[Segments];
    @$seg or die "can't take dirname of empty path";
    my $cl= ref $s;
    bless [
	   [
	    @{$seg}[0..($#$seg-1)]
	   ],
	   0, # no forced endslash anymore
	   @$s[2..$#$s]
	  ], $cl;
}

sub to_relative {
    my $s=shift;
    die "is already relative" unless $s->is_absolute;
    my $seg= $$s[Segments];
    my $cl= ref $s;
    bless [
	   [
	    # drop first entry
	    @{$seg}[1..($#$seg)]
	   ],
	   scalar $s->has_endslash, # XX hm always? what about the dropping of first entry?
	   0, # not absolute
	   @$s[3..$#$s]
	  ], $cl;
}

sub contains_dotdot {
    my $s=shift;
    for my $segment (@{$$s[Segments]}) {
	return 1 if $segment eq ".."
    }
    0
}

end Class::Array;


use Chj::TEST;

TEST { (new_from_string Chj::Path "hello//world/you")->string }
  "hello/world/you";
TEST { (new_from_string Chj::Path "/hello//world/you")->string }
  "/hello/world/you";
TEST { (new_from_string Chj::Path "/hello//world/you/")->string }
  "/hello/world/you/";
TEST { (new_from_string Chj::Path "/")->string }
  "/";
TEST { (new_from_string Chj::Path ".")->string }
  ".";
TEST { (new_from_string Chj::Path "./")->string }
  "./";
TEST { (new_from_string Chj::Path "./")->clean->string }
  "./";
TEST { (new_from_string Chj::Path "./..")->string }
  "./..";
TEST { (new_from_string Chj::Path "./..")->clean->string }
  "..";

TEST { (new_from_string Chj::Path "./foo/../bar/.//baz/.")->clean->string }
  "foo/../bar/baz/";
TEST { (new_from_string Chj::Path "")->clean->string }
  # XX should this be an error?
  '.';

TEST { (new_from_string Chj::Path ".")->string }
  ".";
TEST { (new_from_string Chj::Path ".")->clean->string }
  './';

TEST { (new_from_string Chj::Path "/")->string }
  "/";
TEST { (new_from_string Chj::Path "/")->clean->string }
  "/";
TEST { (new_from_string Chj::Path "/.")->clean->string }
  "/";
TEST { (new_from_string Chj::Path "/./")->clean->string }
  "/";
TEST { (new_from_string Chj::Path "/./")->string }
  "/./";
TEST { (new_from_string Chj::Path "/.")->string }
  "/.";

TEST { (new_from_string Chj::Path "/.")->contains_dotdot }
  "0";
TEST { (new_from_string Chj::Path "foo/bar/../baz")->contains_dotdot }
  "1";
TEST { (new_from_string Chj::Path "../baz")->contains_dotdot }
  "1";
TEST { (new_from_string Chj::Path "baz/..")->contains_dotdot }
  "1";
TEST { (new_from_string Chj::Path "baz/..")->clean->contains_dotdot }
  "1";

TEST_EXCEPTION { Chj::Path->new_from_string(".")->clean->dirname }
  q{can't take dirname of empty path};
TEST { Chj::Path->new_from_string("foo")->clean->dirname->string }
  '.';
TEST { Chj::Path->new_from_string("foo/bar")->clean->dirname->string }
  'foo';
TEST_EXCEPTION { Chj::Path->new_from_string("")->dirname }
  q{can't take dirname of empty path};

TEST { Chj::Path->new_from_string(".")->clean->has_endslash }
  1;
TEST { Chj::Path->new_from_string(".")->clean->string }
  './';
#ok
TEST { Chj::Path->new_from_string("")->clean->has_endslash }
  0;
TEST { Chj::Path->new_from_string("")->clean->string }
  '.';
#h

TEST { Chj::Path->new_from_string("/foo")->to_relative->string }
  'foo';
TEST { Chj::Path->new_from_string("/")->to_relative->string }
  './';
TEST_EXCEPTION { Chj::Path->new_from_string("")->to_relative->string }
  q{is already relative};
TEST { Chj::Path->new_from_string("/foo/")->to_relative->string }
 'foo/';


1
