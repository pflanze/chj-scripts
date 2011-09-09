#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Path::Expand

=head1 SYNOPSIS

 PathExpand("foo/bar/baz")
   returns "baz" if bar is a symlink pointing to ".."
   dies if bar is a symlink pointing to "/foo" or "../.."


 The above assumes the base is ".". With different base:

 PathExpand("foo/bar/baz","foo")
   same thing but already dies if bar points to ".."

=head1 DESCRIPTION


=cut


package Chj::Path::Expand;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(PathExpand);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use Chj::xperlfunc 'xreadlink','xlstat';
use Chj::Path;

sub _expand {
    my ($p,$segments)=@_;
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
	    _expand ($p2, $segments2)
	} else {
	    my $p2= $p->add_segment($segment);

	    my $path2= $p2->string;
	    my $s= xlstat $path2;
	    if ($s->is_symlink) {
		my $targstr= xreadlink $path2;
		my $targ= Chj::Path->new_from_string($targstr);
		die "absolute symlink '$targstr' at '$path2'"
		  if $targ->is_absolute;
		_expand (_expand ($p, $targ->segments), $segments2);
	    } else {
		_expand ($p2, $segments2)
	    }
	}
    }
}


sub assert_no_dotdot {
    my ($p)=@_;
    die "path contains '..': '$path'"
      if $p->contains_dotdot
}

our $nullpath= Chj::Path->new_from_string(".")->clean;
#provide this from Chj::Path ?

sub PathExpand ( $ ; $ ) {
    my ($path,$maybe_base)=@_;
    die "base not yet implemented" if defined $maybe_base;
    # base is assumed to be "."
    my $p= Chj::Path->new_from_string($path)->clean;
    assert_no_dotdot $p; # well, what for *exactly?*
    _expand($nullpath, $p->segments)->string
}


1
