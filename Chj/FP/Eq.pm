#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Eq

=head1 SYNOPSIS

=head1 DESCRIPTION

Equality comparator functions

=cut


package Chj::FP::Eq;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 string_eq
		 number_eq
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub string_eq ( $ $ ) {
    $_[0] eq $_[1]
}

sub number_eq ( $ $ ) {
    $_[0] == $_[1]
}

1
