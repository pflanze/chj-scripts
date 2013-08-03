#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::numcores

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::numcores;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(numcores);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# Code partially borrowed from:
# http://cpansearch.perl.org/src/DBR/App-OS-Detect-MachineCores-0.038/lib/App/OS/Detect/MachineCores.pm
# (but avoiding dependency on Moo)


our $os_numcores=
  {
   linux=> sub {
       local $_ = `grep processor < /proc/cpuinfo | wc -l`;
       chomp;
       $_
   },
   darwin=> sub {
       local $_= `sysctl hw.ncpu | awk '{print \$2}'`;
       chomp;
       $_
   },
  };

our $warned;
sub numcores {
    my $os= $^O;
    if (my $numcores= $$os_numcores{$os}) {
	&$numcores
    } else {
	$warned||=
	  warn "don't know how to derive numcores from os '$os'";
	1
    }
}

1
