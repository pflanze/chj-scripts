#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Trace

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Trace;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(tracing);
@EXPORT_OK=qw();

use strict;

use Chj::singlequote 'singlequote_many';
use Carp;

sub tracing ( $; $ ) {
    my ($proc,$maybe_name) = @_;
    my $name = defined($maybe_name)? $maybe_name : "$proc";
    sub {
	my $wantarray=wantarray;
	carp ">>> $name(". singlequote_many( @_).")";
	my @res= do {
	    if ($wantarray) {
		&$proc(@_)
	    } else {
		scalar &$proc(@_)
	    }
	};
	# hm could also suppress return value rendering if wantarray
	# is indicating void context..
	carp "<<< $name -> ".singlequote_many(@res);
	if ($wantarray) {
	    @res
	} else {
	    $res[0]
	}
    }
}

#sub trace   would replace a procedure with a tracing one. will I need it?


1
