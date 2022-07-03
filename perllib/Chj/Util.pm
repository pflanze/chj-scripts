#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Util

=head1 SYNOPSIS

=head1 DESCRIPTION

Various utility functions and procedures.

=cut


package Chj::Util;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(Sort_table On $noop);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub Sort_table ( $ $ ) {
    # outputting an array of [key, val] entries.
    my ($hsh, $cmp)=@_;
    [
     map {
	 [ $_, $$hsh{$_} ]
     }
     sort {
	 &$cmp ($$hsh{$a}, $$hsh{$b})
     } keys %$hsh
    ]
}

sub On {
    my ($extract, $cmp)=@_;
    sub {
	my ($a_,$b_)=@_;
	&$cmp(&$extract ($a_),&$extract ($b_))
    }
}


our $noop= sub {
};


1
