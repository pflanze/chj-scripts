# Wed Jan 14 17:22:34 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Excel::GenCSV

=head1 SYNOPSIS

=head1 DESCRIPTION

Funktionen bloss.

EIGENTLICHNICHT CSV sondern text  tab  format  weil das das einzige ist was in Mac funktionniert.

=cut


package Chj::Excel::GenCSV;
#require "Exporter";#  HUH?: Exporter did not return a true value at /root/extlib/Chj/Excel/GenCSV.pm line 24.
#use Exporter ();# geht. ??
require Exporter;# ah.

@ISA="Exporter";
@EXPORT_OK=qw(
	      excel_datetime
	      excel_unix2datetime
	      excel_quote
	      );
use strict;

sub quote_csv {
    my $str=shift;
    $str=~ s/\\/\\\\/sg;
    $str=~ s/"/\\"/sg;
    #$str=~ s/,/\\,/sg; aber das isch doch nöd nötig? dafür sind doch anf zeichen.
    "\"$str\""
}

sub quote {
    my $str=shift;
    $str=~ s/\\/\\\\/sg;
    $str=~ s/"/\\"/sg;
    "\"$str\""
}
*excel_quote= \&quote;

sub datetime {
    my ($year,$monthno,$mday,$hour,$min,$sec)=@_;
    #"$year/$monthno/$mday $hour:$min"
    if (defined $sec) {
	sprintf("%04d/%02d/%02d %02d:%02d:%02d",$year,$monthno,$mday,$hour,$min,$sec)
    } else {
	sprintf("%04d/%02d/%02d %02d:%02d",$year,$monthno,$mday,$hour,$min)
    }
}
*excel_datetime= \&datetime;
sub unix2datetime {# sollte halt WIRKLICH ne zeit klasse sein  von mir oder so. ?
    my $unix=shift;
    my ($year,$monthno,$mday,$hour,$min,$sec)=(localtime $unix)[5,4,3,2,1,0];
    $year+=1900;
    $monthno++;
    #"$year/$monthno/$mday $hour:$min"
    sprintf("%04d/%02d/%02d %02d:%02d:%02d",$year,$monthno,$mday,$hour,$min,$sec)
}
*excel_unix2datetime= \&unix2datetime;

1;
