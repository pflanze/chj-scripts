# Thu Jun  8 15:35:47 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Matrix2Excel

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Matrix2Excel;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(Matrix2xlsfile);

use strict;

# a Max which also accepts (and ignores) undef:
sub Max {
    my $v;
    for (@_) {
	next unless defined $_;
	if (!defined $v) {
	    $v=$_;
	} else {
	    if ($_>$v) {
		$v=$_
	    }
	}
    }
    $v
}

my $BIG;
my $WriteExcel;
BEGIN{
    $BIG=1;
    $WriteExcel= $BIG ? 'Spreadsheet::WriteExcel::Big' : 'Spreadsheet::WriteExcel';
    eval "use $WriteExcel"; die $@ if ($@ or ref $@);
}
use Chj::FP::Memoize;

sub Matrix2xlsfile {
    @_>=3 or die "need at least 3 arguments";
    my ($file,$maybe_titles,$data,
	$maybe_dateformat_string)=@_;

    my $workbook = $WriteExcel->new($file);#exceptions?
    #$workbook->compatibility_mode;
    my $worksheet= $workbook->add_worksheet;
    my $_titleformat= memoize_thunk sub {
	my $format= $workbook->add_format;
	$format->set_bold;
	$format
    };
    my $column_width={}; # col => width
    my $_dateformat= memoize_thunk sub {
	$workbook->add_format(num_format=> ($maybe_dateformat_string
					    or "d.m.yyyy hh:mm:ss"),
			      align=>'right'
			     );
    };
    my $_exceldateformat= memoize_thunk sub {
	#warn "uses _exceldateformat";
	require Chj::Format::Date::ExcelDatetime;
	new Chj::Format::Date::ExcelDatetime
    };

    my $output_row= sub {
	my ($rowno,$row,$maybe_format)=@_;
        for (my $i=0; $i<= $#$row; $i++) {
	    my $d= $$row[$i];
	    if (UNIVERSAL::isa($d,"UNIXTIME")) {
		$worksheet->write_date_time($rowno,$i,
					    (&$_exceldateformat)->from_unix($$d),
					    (&$_dateformat));
		$column_width->{$i}= Max($column_width->{$i},19);
	    } else {
		if ($maybe_format) {
		    $worksheet->write_string($rowno,$i,$d,$maybe_format)
		      #if (defined $d and length $d);#not 100% sure whether this if is necessary or even good.
		} else {
		    $worksheet->write($rowno,$i,$d)
		}
	    }
        }
    };

    if ($maybe_titles) {
	$output_row->(0,$maybe_titles,&$_titleformat);
    }

    my $rowno= ($maybe_titles ? 1 : 0);
    for my $row (@$data) {
	$output_row->($rowno,$row);
        $rowno++;
    }

    for my $key (keys %$column_width) {
	#warn "setting $key to ".$column_width->{$key};
	$worksheet->set_column($key,$key,$column_width->{$key});
    }

    #$worksheet->close; doesn't exist
    $workbook->close or ($BIG or die "error closing excel file '$file': $!"); # Spreadsheet::WriteExcel::Big seems buggy, it always returns false from close.
}



1
