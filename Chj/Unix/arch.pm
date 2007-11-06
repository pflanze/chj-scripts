# Tue Nov  6 00:55:16 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::arch

=head1 SYNOPSIS

 use Chj::Unix::arch ':all';
 is_current_linux_arch("i386") ? "running on a pc" : "something else"
 # note that is_current_linux_arch doesn't know about i686 since this
 # isn't present in the linux kernel arch/ subdirectory and thus also
 # not in our map. Ok?

=head1 DESCRIPTION

Returns the hardware architecture string (uname -m).

=cut


package Chj::Unix::arch;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(is_current_linux_arch);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::FP::Memoize;

*uname_arch= memoize_thunk sub {
    my $c= Chj::IO::Command->new_sender("uname", "-m");
    my $str= $c->xreadline;
    chomp $str;
    $str=~ /^[\w-]+\z/ or die "hm looks strange for an arch: '$str'";
    $str #hm detaint it?
};

our $linux_arches_of_uname_arch=
  {
   # sigh. why do they have to differ? or worse, why are there multiple dirs in the linux kernel for the (same?) arch?
   ppc=> [qw(ppc powerpc)], # sure?   lombi is a case of a 'ppc'
   #powerpc=> [qw(ppc powerpc)], # sure?
   i686 => ['i386'],
   i386 => ['i386'],
   #...
  };

sub linux_arches_of_uname_arch ( $ ) {
    my ($uname_arch)=@_;
    $$linux_arches_of_uname_arch{$uname_arch}
      or die "missing map entry for uname_arch '$uname_arch', please complete the table above here"
}

*linux_arches= memoize_thunk sub {
    linux_arches_of_uname_arch ( uname_arch() )
};

*linux_arches_collection= memoize_thunk sub {
    +{
      map {
	  $_=> undef
      } @{ linux_arches() }
     }
};

sub is_current_linux_arch ( $ ) { # true if the given linux arch matches the architecture of the running machine. There can be multiple values given to this function returning true.
    my ($linux_arch)=@_;
    exists ${ linux_arches_collection() }{$linux_arch}
}

1
