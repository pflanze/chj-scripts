# Wed Mar  1 03:43:22 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Excel2Matrix

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Excel2Matrix;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(Xlsfile2matrix);

use strict;

use Spreadsheet::ParseExcel::Simple;

use Chj::singlequote 'singlequote', 'singlequote_many';

sub Xlsfile2matrix {
    my ($filepath, $optional_sheetindex)=@_;
    my $xls = Spreadsheet::ParseExcel::Simple->read($filepath)
      or die "could not open (or parse?) excel sheet ".Chj::singlequote($filepath)." (os status: $!)";
    my @sheet= $xls->sheets;
    if (defined($optional_sheetindex) or @sheet==1) {
	my $sheet= do {
	    if (defined ($optional_sheetindex)) {
		my $s= $sheet[$optional_sheetindex];
		defined $s or die "no sheet with index $optional_sheetindex";
		$s
	    } else {
		shift @sheet
	    }
	};
	my @rows;
	while ($sheet->has_data) {
	    my @cols = $sheet->next_row;
	    #print join ", ",singlequote_many @cols;
	    #print scalar @cols;
	    #print "\n";
	    push @rows,\@cols
	}
	\@rows
    } else {
	die "expecting 1 sheet, got ".@sheet;
    }
}



1
