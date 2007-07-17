# Mon Jul 14 07:21:22 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::xtmpdir

=head1 SYNOPSIS

=head1 DESCRIPTION

NA, könnte auch objekt geben? (Das in den Pfad stringified)
so dass autoclean möglich. ein aund ausschaltgen.
Aber  wann autocleanen   muss sihcerstellen dass zuerst die tmpfiles aufgeräumt werden

d.h. müsste allle pending tmpfiles verzeichnen    und reaper zugang geben.


=cut


package Chj::xtmpdir;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xtmpdir);

use strict;
use Chj::IO::Tempdir;


sub xtmpdir {
    unshift @_, 'Chj::IO::Tempdir';
    goto &Chj::IO::Tempdir::xtmpdir;
}

1;
