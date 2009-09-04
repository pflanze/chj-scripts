# Sun Mar 30 11:16:38 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xrealpath

=head1 SYNOPSIS

 use Chj::xrealpath;

 my $realpath= xrealpath($path);

=head1 DESCRIPTION

Layer above Cwd::abs_path or Chj::Cwd::realpath::realpath, choosing
the latter if the former doesn't implement the same functionality as
the latter. -- Well actually *always* require the latter since the
former doesn't require the last path segment to exist :/.

=cut


package Chj::xrealpath;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xrealpath);
@EXPORT_OK=qw(xrealpath_dirname);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# man 3perl Cwd :
# (only works on files in perl 5.8+)
#
#       abs_path
#             my $abs_path = abs_path($file);
#
#           Uses the same algorithm as getcwd().  Symbolic links and relative-path components ("."
#           and "..") are resolved to return the canonical pathname, just like realpath(3).
#
# realpath
#   A synonym for abs_path().
#
# fast_abs_path
#  A more dangerous, but potentially faster version of abs_path.
#so we don't want this, right

BEGIN {
    if (0 and $] >= 5.008) {
	warn "using Cwd::abs_path";
	require Cwd;
	*xrealpath= sub ( $ ) {
	    my ($path)=@_;
	    my $res= Cwd::abs_path ($path);
	    defined ($res) ? $res : die "xrealpath('$path'): $!";
	};
    } else {
	#warn "using Chj::Cwd::realpath::xrealpath";
	require Chj::Cwd::realpath;
	*xrealpath= *Chj::Cwd::realpath::xrealpath;
    }
}

use Chj::xperlfunc 'dirname','basename';
sub xrealpath_dirname ($ ) {
    my ($path)=@_;
    my $dir= dirname $path;
    my $bn= basename $path;
    #xrealpath ($dir)."/".$bn  ## always correct?. should. except platform dependency, as always.  HMM and /foo expands to //foo. Since basename doesn't go to "" and neither does xrealpath. old sigh~.
    my $xdir= xrealpath ($dir);
    if ($xdir eq "/") {
	"/".$bn
    } else {
	$xdir."/".$bn
    }
}

# hm a result of this way of working is:
#calc> :l xrealpath_dirname "/usr/"
#/usr
#calc> :l xrealpath_dirname "/usr/src"
#/mnt/rootextend/usr/src
# so GRRR it's still not like readlink -f
#chris@novo:~$ readlink -f /usr
#/mnt/rootextend/usr
# -- but things like cj-tailor might still be happy with this. But then, those would be just as happy (if not happier) with just prepending cwd to relative paths. hmmm.

1
