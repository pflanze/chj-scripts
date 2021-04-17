# Mon Jun 16 03:44:19 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::ParseNumber::Bytes

=head1 SYNOPSIS

=head1 DESCRIPTION

 $tmpsiz= parsenumber_bytes $tmpsiz;
800M -> 800*1024*1024
  irgendwo kürzlich hatte ich son parser gemacht
  wo schon wieder
  egal, mount kann M und so selber verstehen
  ach ja
  

=cut


package Chj::ParseNumber::Bytes;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(parsenumber_bytes);

use strict;
use utf8;
use Carp;

sub contextsensitive {
    if (wantarray) {
	@_
    } else {
	$_[0]
    }
}


my %multiplier = (
		  # units
		  k => 1024,
		  m => 1024**2,
		  g => 1024**3,
		  t => 1024**4
		  );

sub parsenumber_bytes {
    contextsensitive map {
	/^\s* ([+-])?\s*  (\d+(?:\.\d+)?)\s*  (?:(\w) (?:i?[bB](?:ytes?)?\s*)?  )?\z/sx
	  or croak "parsenumber_bytes: '$_' does not follow the byte number format (something like -12.3 MB or 14KiB)";
	my $multiplier;
	if (defined $3) {
	    defined ($multiplier= $multiplier{lc $3})
	      or croak "parsenumber_bytes: unknown unit '$3' in '$_'";
	} else {
	    $multiplier=1 # 1 byte
	}
	((defined $1 and $1 eq '-') ? -1 : 1)* $2 * $multiplier
    } @_
}

1;
