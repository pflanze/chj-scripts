# Sat Oct 18 21:48:42 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Chomp

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Chomp;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Chomp);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub Chomp ( $ ) {
    my ($str)=@_;
    chomp $str;
    $str
}

1
