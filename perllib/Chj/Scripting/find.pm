#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Scripting::find

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Scripting::find;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(dir_files_hash);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::xperlfunc;
use Carp;

sub path_from_basepath_maybe_subpath ( $ $ ) {
    my ($basepath,$maybe_subpath)=@_;
    if (defined $maybe_subpath) {
	if ($basepath=~ m|/\z|) {
	    "$basepath$maybe_subpath"
	} else {
	    "$basepath/$maybe_subpath"
	}
    } else {
	$basepath
    }
}

sub subpath_from_maybe_subpath_item ( $ $ ) {
    my ($maybe_subpath,$item)=@_;
    if (defined $maybe_subpath) {
	## well I'm joking a bit here. subpath will (theoretically) never end in a slash. but the joke is that this is almost the same as path_from_basepath_maybe_subpath, but arguments semireversed.
	if ($maybe_subpath=~ m|/\z|) {
	    "$maybe_subpath$item"
	} else {
	    "$maybe_subpath/$item"
	}
    } else {
	#$maybe_subpath
	#ouch. wrong.
	$item
    }
}

use Chj::xopendir;

sub dir_files_hash { # collecting subpaths.
    my ($basepath,$maybe_acceptp, $maybe_subpath, $maybe_hash)=@_;
    my $hash= defined ($maybe_hash)? $maybe_hash : {};
    my $path= path_from_basepath_maybe_subpath($basepath,$maybe_subpath);
    if (my $st= xlstat $path) {
	my $do= sub {
	    if ($st->is_dir) {
		my $d= xopendir $path;
		while (defined (my $item= $d->xnread)) {
		    dir_files_hash(
				   $basepath,
				   $maybe_acceptp,
				   subpath_from_maybe_subpath_item($maybe_subpath,$item),
				   $hash
				  );
		}
	    } else {
		if (defined $maybe_subpath) {
		    if ($st->is_file
			or
			#for git this is sensible.
			$st->is_symlink
		       ) {
			$$hash{$maybe_subpath}=undef
		    } else {
			#ignore
		    }
		} else {
		    croak "dir_files_hash: not a directory: '$path'";
		}
	    }
	};
	if (defined $maybe_subpath and defined $maybe_acceptp) {
	    &$do if &$maybe_acceptp($maybe_subpath)
	} else {
	    &$do
	}
    } #else doesn't happen here. thought i'd warn only, but maybe not.
    $hash
}
#*find= \&dir_files_hash; hm?

1
