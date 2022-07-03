#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Path::Expand - resolving paths safely for chroots

=head1 SYNOPSIS

 PathExpand_relative("foo/bar/baz")

   returns "baz" if bar is a symlink pointing to ".."
   dies if bar is a symlink pointing to "/foo" or "../.."

 PathExpand_all("foo/bar/baz")

   same but makes /foo point to "foo" (interprets absolute symlink
   targets as starting off the base; "." is the base here)

 The above assumes the base is ".". With different base:

 PathExpand_all("foo/bar/baz","foo")
   same thing but already dies if bar points to ".."

=head1 DESCRIPTION


=cut


package Chj::Path::Expand;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      PathExpand_relative
	      PathExpand_all
	      perhaps_PathExpand_relative
	      perhaps_PathExpand_all
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use Chj::xperlfunc 'xreadlink','Xlstat';
use Chj::Path;
use Chj::singlequote ':all';
use POSIX 'ENOENT'; # or where forever?

#use Chj::Backtrace;

{
    package Chj::Path::Expand::Error;
    use Chj::singlequote 'singlequote';
    use overload '""' => sub { die "it is an error to use an Error as a string" };
    sub new {
	my $cl=shift;
	@_==5 or die;
	bless[@_], $cl
    }
    sub _make_acc { my ($i)=@_; sub { my $s=shift; $$s[$i] } }
    *msg= _make_acc(0);
    *path= _make_acc(1);
    *errno= _make_acc(2);
    *errstr= _make_acc(3);
    *is_origpath= _make_acc(4);
    sub errorstring {
	my $s=shift;
	$s->msg.": ".
	  join(", ",
	       singlequote($s->path),
	       $s->errstr)
    }
}

# 'syntax' to make passing the function as first argument to itself simpler
sub call {
    # "Deep recursion on anonymous subroutine" can be disabled here
    # (heh, at the place where a new frame is *not* allocated, how
    # comes?):
    use warnings;
    no warnings;
    goto $_[0]
}

sub _expand {
    my ($do_expand_absolute)=@_;
    my $_expand= sub {
	my ($_expand, $p,$segments,$level)=@_;
	die "too many levels of symlinks (cycle?) at path: ".singlequote($p->string)." with remaining segments: ".singlequote_many(@$segments)
	  if $level > 100;
	#use Data::Dumper; print "AAA: ".Dumper ($p, $segments,$level);
	if (not @$segments) {
	    $p
	} else {
	    my $segment = $$segments[0];
	    my $segments2 = [@$segments[1..$#$segments]];
	    # (some say car and cdr is not good.)

	    # have to check for .. explicitely, Chj::Path doesn't resolve this
	    if ($segment eq "..") {
		# XX relying on getting an exception if walking out. And,
		# has to be changed if maybe_base is implemented
		my $p2= $p->dirname;
		call ($_expand, $p2, $segments2, $level)
	    } else {
		my $p2= $p->add_segment($segment);

		my $path2= $p2->string;
		if (defined (my $s= Xlstat ($path2))) {
		    if ($s->is_symlink) {
			my $targstr= xreadlink $path2;
			my $targ= Chj::Path->new_from_string($targstr);
			if ($targ->is_absolute) {
			    if ($do_expand_absolute) {
				my $targ_relative_from_base=
				  # XX another point where $base would matter
				  $targ->to_relative;
				call ($_expand,
				      call ($_expand,
					    $nullpath,
					    $targ_relative_from_base->segments,
					    $level+1),
				      $segments2,
				      $level);
				# is $level correct here?
			    } else {
				die "absolute symlink '$targstr' at '$path2'"
			    }
			} else {
			    call ($_expand,
				  call ($_expand, $p, $targ->segments, $level+1),
				  $segments2,
				  $level);
			}
		    } else {
			call ($_expand, $p2, $segments2, $level)
		    }
		} else {
		    Chj::Path::Expand::Error->new
			("lstat",
			 $path2,
			 $!+0,
			 "$!",
			 # is_origpath: (wow parens needed, Perl)
			 ($level==0 and !@$segments2))
		}
	    }
	}
    };
    sub {
	call ($_expand,@_)
    }
}


sub assert_no_dotdot {
    my ($p)=@_;
    die "path contains '..': '$path'"
      if $p->contains_dotdot
}

our $nullpath= Chj::Path->new_from_string(".")->clean;
#provide this from Chj::Path ?

sub _PathExpand {
    @_==4 or die;
    my ($do_expand_absolute, $path, $maybe_base, $is_perhaps)=@_;
    local $nullpath= do {
	if (defined $maybe_base) {
	    Chj::Path->new_from_string($maybe_base)->clean;
	} else {
	    $nullpath
	}
    };
    my $p= Chj::Path->new_from_string($path)->clean;
    assert_no_dotdot $p; # well, what for *exactly?*
    my $res= _expand($do_expand_absolute)->($nullpath, $p->segments, 0);
    UNIVERSAL::isa($res, "Chj::Path::Expand::Error") ?
	(($is_perhaps
	  # allow ENOENT for original path
	  and $res->errno == ENOENT
	  and $res->is_origpath
	 ) ? () : die $res->errorstring)
	  : $res->string
}

sub PathExpand_relative ( $ ; $ ) {
    my ($path,$maybe_base)=@_;
    _PathExpand (0, $path, $maybe_base, 0);
}

sub PathExpand_all ( $ ; $ ) {
    my ($path,$maybe_base)=@_;
    _PathExpand (1, $path, $maybe_base, 0);
}

sub perhaps_PathExpand_relative ( $ ; $ ) {
    my ($path,$maybe_base)=@_;
    _PathExpand (0, $path, $maybe_base, 1);
}

sub perhaps_PathExpand_all ( $ ; $ ) {
    my ($path,$maybe_base)=@_;
    _PathExpand (1, $path, $maybe_base, 1);
}

1


__END__

(haven't recorded previous tests, sigh)


chris@tie:/tmp/chris/foo$ lns /foo hum2
chris@tie:/tmp/chris/foo$ u
chris@tie:/tmp/chris$ calc -MChj::xperlfunc=:all -MChj::Path::Expand
calc> :l PathExpand_all "foo/hum2"
foo

lrwxrwxrwx 1 chris chris 1 2011-09-10 13:15 foo/hum -> /
chris@tie:/tmp/chris$ calc -MChj::xperlfunc=:all -MChj::Path::Expand
calc> :l PathExpand_all "foo/hum"
./

chris@tie:/tmp/chris$ lns giga fob

calc> :l PathExpand_all "fob"
xlstat: 'giga': No such file or directory at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 73

chris@tie:/tmp/chris$ l foo
total 0
lrwxrwxrwx 1 chris chris 2 2011-09-09 01:06 bar -> ..
lrwxrwxrwx 1 chris chris 5 2011-09-09 01:25 baz -> ../..
lrwxrwxrwx 1 chris chris 6 2011-09-09 01:26 baz2 -> ../baz
lrwxrwxrwx 1 chris chris 1 2011-09-10 13:15 hum -> /
lrwxrwxrwx 1 chris chris 4 2011-09-10 13:39 hum2 -> /foo
lrwxrwxrwx 1 chris chris 9 2011-09-10 13:40 hum3 -> /foo/hum3
-rw-r--r-- 1 chris chris 0 2011-09-10 13:48 bah

chris@tie:/tmp/chris$ calc -MChj::xperlfunc=:all -MChj::Path::Expand
calc> :l PathExpand_all "foo/hum2/bar"
.
calc> :l PathExpand_all "foo/hum2/bah"
foo/bah

calc> :l PathExpand_all "foo/hum3/bar"
Deep recursion on anonymous subroutine at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 47.
too many levels of symlinks (cycle?) at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 54.
calc> :l PathExpand_all "foo/hum3"
Deep recursion on anonymous subroutine at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 47.
too many levels of symlinks (cycle?) at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 54.

chris@tie:/tmp/chris$ mkdir bard
chris@tie:/tmp/chris$ lns bard bar
chris@tie:/tmp/chris$ touch bard/hello
chris@tie:/tmp/chris/foo$ lns ../bar bada
chris@tie:/tmp/chris/foo$ lns /bar bada
#bada -> /bar -> /bard
calc> :l PathExpand_all "foo/bada/hello"
bard/hello

{Mit Aug  3 16:57:45 BST 2016}
sigh (non-existing /jessie dir)
main> perhaps_PathExpand_all('/dev/shm', '/jessie');
main> 
bad. see. level 0 still, no symlink followed yet.
sgh. not what I wanted.
that shohuld throw error.
main> eval { PathExpand_all('/dev/shm', '/jessie') } || "$@"
$VAR1 = 'can\'t lstat: \'/jessie/\', Datei oder Verzeichnis nicht gefunden at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 178.
';

ah now with defined check it actually works
main> perhaps_PathExpand_all('/dev/shm', '/jessie');
Exception: can't lstat: '/jessie/', Datei oder Verzeichnis nicht gefunden at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 178.
Chj::Path::Expand 1> 

chrisperl@novo:~/tmp/testing$ mkdir jessie
chrisperl@novo:~/tmp/testing$ ./t-Chj\:\:Path\:\:Expand
main> perhaps_PathExpand_all('/dev/shm', 'jessie');
Exception: can't lstat: 'jessie//dev', Datei oder Verzeichnis nicht gefunden at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 178.
Chj::Path::Expand 1> 

chrisperl@novo:~/tmp/testing$ mkdir jessie/dev
chrisperl@novo:~/tmp/testing$ ./t-Chj\:\:Path\:\:Expand
main> perhaps_PathExpand_all('/dev/shm', 'jessie');
Exception: can't lstat: 'jessie//dev/shm', Datei oder Verzeichnis nicht gefunden at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 178.
Chj::Path::Expand 1> 
UH  wrong again? sigh.
it should give nothing now.

  YES now it works:
main> perhaps_PathExpand_all('/dev/shm', 'jessie');
main> perhaps_PathExpand_all('/dev/shm/foo', 'jessie');
Exception: lstat: 'jessie//dev/shm', Datei oder Verzeichnis nicht gefunden at /usr/local/lib/site_perl/Chj/Path/Expand.pm line 179.
Chj::Path::Expand 1> 

