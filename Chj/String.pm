# Mon Feb 11 13:17:13 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::String

=head1 SYNOPSIS

 use Chj::String ':all';
 grep { Chomp $_ eq "foo" } ...

=head1 DESCRIPTION

*Functions* for string manipulation.

All have ucfirst names (to avoid method name clashes).

=cut


package Chj::String;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(Chomp);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub Chomp ( $ ) {
    my ($str)=@_;
    chomp $str;
    $str
}


1
