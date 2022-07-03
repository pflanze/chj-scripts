# Mon Mar 31 21:22:20 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
#
# $Id$

=head1 NAME

Chj::oerr

=head1 SYNOPSIS

 use Chj::oerr;
 print oerr(undef,"undef"),"\n";

=head1 DESCRIPTION

Function doing the same as perl6 //. Damian Conway's phonetics indicate
this name. Nothing error, just a funny kind of "or".

=cut


package Chj::oerr;
require Exporter;
@ISA="Exporter";
@EXPORT=qw(oerr);
@EXPORT_OK=qw( oerrset);

use strict;

sub oerr {
    defined $_[0] ? $_[0] : $_[1]
}
*Chj::oerr= \&oerr;

sub oerrset($ $ ) {
    if(!defined $_[0]) {
	$_[0]=$_[1];
    }
}

1;
