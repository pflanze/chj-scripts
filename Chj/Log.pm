# Sun Jul 15 11:04:22 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Log

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Log;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      logging_to
	      logging_to_fh
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::xopen 'xopen_append';

sub logging_to_fh ( $ $ ; $ ) {
    my ($fh,$thunk,$do_close)=@_;
    my $maybe_closeit= sub{
    	if ($do_close) {
	    eval { $fh->xclose };
	    warn "logging_to_fh: while closing fh: $@" if (ref $@ or $@);
	}
    };
    local *STDOUT= $fh;
    local *STDERR= $fh;
    my $wantarray= wantarray;
    my @rv = eval {
	$wantarray ? &$thunk : scalar &$thunk
    };
    if (ref $@ or $@) {
	my $e=$@;
	&$maybe_closeit;
	die  $e
    } else {
	&$maybe_closeit;
    }
    $wantarray ? @rv : $rv[0]
}

sub logging_to ( $ $ ) {
    my ($path,$thunk)=@_;
    logging_to_fh( xopen_append ($path), $thunk, 1)
}

# use Chj::Util::Interprocess ?



1
