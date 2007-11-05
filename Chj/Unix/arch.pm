# Tue Nov  6 00:55:16 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::arch

=head1 SYNOPSIS

 use Chj::Unix::arch;
 print arch,"\n";

=head1 DESCRIPTION

Returns the hardware architecture string (uname -m).

=cut


package Chj::Unix::arch;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(arch);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::FP::Memoize;

*arch= memoize_thunk sub {
    my $c= Chj::IO::Command->new_sender("uname", "-m");
    my $str= $c->xreadline;
    chomp $str;
    $str=~ /^[\w-]+\z/ or die "hm looks strange for an arch: '$str'";
    $str #hm detaint it?
};

1
