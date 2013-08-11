# Wed Jan 14 17:22:34 2004  Christian Jaeger, ch@christianjaeger.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Excel::GenCSV

=head1 SYNOPSIS

=head1 DESCRIPTION

Functions to help generate CSV or TSV (tab separated columns) format files.

=cut


package Chj::Excel::GenCSV;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
	      excel_datetime
	      excel_unix2datetime
	      excel_quote
	      );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

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

sub unix2datetime {
    my $unix=shift;
    my ($year,$monthno,$mday,$hour,$min,$sec)=(localtime $unix)[5,4,3,2,1,0];
    $year+=1900;
    $monthno++;
    #"$year/$monthno/$mday $hour:$min"
    sprintf("%04d/%02d/%02d %02d:%02d:%02d",$year,$monthno,$mday,$hour,$min,$sec)
}
*excel_unix2datetime= \&unix2datetime;

1
