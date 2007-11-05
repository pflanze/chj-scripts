# Mon Nov  5 22:49:07 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Store::Storabled

=head1 SYNOPSIS

=head1 DESCRIPTION

Make Storable easier to use. Transparent. Wrapperend. finally.

=cut


package Chj::Store::Storabled;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Storabled_at);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Storable qw(nstore retrieve);
#use Chj::FP::lazy; no, just use thunks. we are the   cacher s  or not eve n.   caching  in other pieceis  is  others duty.
use Chj::xtmpfile;
use Carp;

sub Storabled_at ( $ $ ; $ ) {
    my ($path, $thunk, $maybe_permissions)=@_;  # do not expect a promise, just a thunk. *we* are the cachers here? if at all?.
    sub {#warum so. ?  nid dirtk ?  ?  closuresfürallefelle oder wos
	my $create= sub {
	    my $data= &$thunk;
	    my $f= xtmpfile $path;
	    defined(nstore_fd($data,$f))
	      or croak "Storabled_at: could not store at '$path' (maybe: $!)";
	    $f->xclose;
	    $f->xputback(defined($maybe_permissions) ? $maybe_permissions : 0600);
	    $data
	};
	if (-e $path) {
	    my $data= restore $path;
	    defined ($data) ? $data : do {
		carp "Storabled_at: error reading from file '$path' (maybe: $!), trying to recreate file";
		&$create;
	    };
	} else {
	    &$create
	}
    }
}

1
