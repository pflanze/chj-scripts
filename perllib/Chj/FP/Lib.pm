#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Lib -- library of various functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Lib;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Any);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# Well should be in a list library maybe? Except it doesn't act on
# functional lists, yeah.
sub Any {
    my $fn=shift;
    for (@_) {
	my $v= $fn->($_);
	if ($v){
	    return $v
	}
    }
    return
}


1
