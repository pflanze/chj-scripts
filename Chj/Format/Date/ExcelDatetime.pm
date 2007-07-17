# Wed Jun 28 16:54:35 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::ExcelDatetime

=head1 SYNOPSIS

=head1 DESCRIPTION

The sick(+-?) format as used by Spreadsheet::WriteExcel (or excel?).

Like 2005-12-23T06:00:00Z  but with localtime values
oder eben doch ohne Z weil dann ist es vielliecht immerhin korrekt

=cut


package Chj::Format::Date::ExcelDatetime;

use strict;

use Class::Array -fields=>
  -publica=>
  ;


sub padstring_of_number {
    my ($n,$width)=@_;
    sprintf('%0'.$width.'d',$n)
}

sub from_unix {
    my $s=shift;
    my ($unixtime)=@_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)= localtime($unixtime);
    $year+=1900;
    $mon++;
    ($year.
     "-".
     padstring_of_number($mon,2).
     "-".
     padstring_of_number($mday,2).
     "T".
     padstring_of_number($hour,2).
     ":".
     padstring_of_number($min,2).
     ":".
     padstring_of_number($sec,2)
     #"Z"
    )
}

end Class::Array;
