#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Shelllike::Rmrf

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Shelllike::Rmrf;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Rmrf);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::xopendir;
use Chj::xperlfunc 'Xlstat';

sub Rmrf ( $ );
sub Rmrf ( $ ) {
    my ($path)=@_;
    if (my $s= Xlstat $path) {
	if ($s->is_dir) {
	    my $d= xopendir $path;
	    # ^ let exceptions pass through to caller, ok?
	    while (my $item=$d->xnread) {
		Rmrf ("$path/$item")
	    }
	    $d->xclose;
	    rmdir $path
	      or warn "can't rmdir path: '$path'";
	} else {
	    unlink $path
	      or warn "can't unlink path: '$path'";
	}
    } else {
	warn "can't stat path: '$path'";
    }
}

1
