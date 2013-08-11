#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Matrix2csv

=head1 SYNOPSIS

 use Chj::Format::Matrix2csv 'Matrix2csvfile';
 local $Chj::Format::Matrix2csv::separator = "\t";
 Matrix2csvfile "foo.tsv", ["id","year"], [[1,1900], [2, 2000]];

=head1 DESCRIPTION


=cut


package Chj::Format::Matrix2csv;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Matrix2csvfile);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::Excel::GenCSV ":all";
use Chj::xopen "xopen_write";

our $separator= ";";

sub write_row {
    my ($f,$row)=@_;
    $f->xprintln
      (join($separator,
	    map {
		die "wrappers not yet implemented"
		  if ref $_;
		excel_quote $_
	    } @$row));
}

sub Matrix2csvfile {
    @_>=3 or die "need at least 3 arguments";
    my ($file,$maybe_titles,$data,
	$maybe_dateformat_string)=@_;

    die "dateformat_string not yet implemented"
      if defined $maybe_dateformat_string;

    my $f=xopen_write $file;
    binmode $f, ":encoding(Windows-1252)" or die;
    write_row $f, $maybe_titles
      if $maybe_titles;
    write_row $f,$_ for @$data;
    $f->xclose;
}


1
