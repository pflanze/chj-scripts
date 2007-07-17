# Tue Apr  1 23:03:56 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::deff

=head1 SYNOPSIS

 use Chj::deff;
 my ($a,$b,$c)=(undef,0,"hello world");
 print deff($a,$b,$c),"\n"; # prints "undef, '0', 'hello world'\n"

=head1 DESCRIPTION

Turn a list of values into one scalar.

=head1 CAVEATS

Should it be called deaf() instead?

=cut


package Chj::deff;
require Exporter;
@ISA="Exporter";
@EXPORT="deff";

use strict;

sub deff {
    my @str;
    for (@_){
	push @str, defined $_ ? "'$_'" : "undef"
    }
    join (", ",@str)
}

1;
