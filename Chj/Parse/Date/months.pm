# Mon Jan 19 22:28:24 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Parse::Date::months

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Date::months;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw( @short_english_month
	       %short_english_month
	       xparse_short_english_month
	       %shortmonth_list_by_locale
	       %longmonth_list_by_locale
	       %shortmonth_hash_by_locale
	       %longmonth_hash_by_locale
	       $lcmonth_hash
	     );
use strict;
use utf8;
use Carp;

our @short_english_month= qw(
			      Jan
			      Feb
			      Mar
			      Apr
			      May
			      Jun
			      Jul
			      Aug
			      Sep
			      Oct
			      Nov
			      Dec
			     ); ## jan-may nicht getestet!!!ç
our %short_english_month;
{
    my $n=1;
    for (@short_english_month) {
	$short_english_month{$_}=$n++;
    }
}

sub xparse_short_english_month {
    my $str=shift; # must be ucfirst
    $short_english_month{$str} or croak "unknown month '$str'";
}


## Fri, 26 Mar 2004 12:06:55 +0100:
# (Wed, 29 Mar 2006 05:04:30 +0200 erweitert um andere als de_CH, gem. Angaben von DateTime, f. eid :d DateTime::Locale->load( 'fr' )->month_names)

our %shortmonth_list_by_locale=
  (
   de_CH=>[qw(
	      Jan
	      Feb
	      Mär
	      Apr
	      Mai
	      Jun
	      Jul
	      Aug
	      Sep
	      Okt
	      Nov
	      Dez
	     )],
   # ^- ist glaub von mir. DateTime hat aber Mrz nicht Mär:
   de=> [
	 'Jan',
	 'Feb',
	 'Mrz',
	 'Apr',
	 'Mai',
	 'Jun',
	 'Jul',
	 'Aug',
	 'Sep',
	 'Okt',
	 'Nov',
	 'Dez'
	],
   fr=> [
	 'janv.',
	 "f\x{e9}vr.",
	 'mars',
	 'avr.',
	 'mai',
	 'juin',
	 'juil.',
	 "ao\x{fb}t",
	 'sept.',
	 'oct.',
	 'nov.',
	 "d\x{e9}c."
	],
   en=> [
	 'Jan',
	 'Feb',
	 'Mar',
	 'Apr',
	 'May',
	 'Jun',
	 'Jul',
	 'Aug',
	 'Sep',
	 'Oct',
	 'Nov',
	 'Dec'
	],
   it=> [
	 'gen',
	 'feb',
	 'mar',
	 'apr',
	 'mag',
	 'giu',
	 'lug',
	 'ago',
	 'set',
	 'ott',
	 'nov',
	 'dic'
	],
  );
#$shortmonth_list_by_locale{de}= $shortmonth_list_by_locale{de_CH};

our %longmonth_list_by_locale=
  (
   de_CH=>[qw(
	      Januar
	      Februar
	      März
	      April
	      Mai
	      Juni
	      Juli
	      August
	      September
	      Oktober
	      November
	      Dezember
	     )],
   fr=>	   [
	   'janvier',
	   "f\x{e9}vrier",
	   'mars',
	   'avril',
	   'mai',
	   'juin',
	   'juillet',
	   "ao\x{fb}t",
	   'septembre',
	   'octobre',
	   'novembre',
	   "d\x{e9}cembre"
	   ],
   en=> [
	 'January',
	 'February',
	 'March',
	 'April',
	 'May',
	 'June',
	 'July',
	 'August',
	 'September',
	 'October',
	 'November',
	 'December'
	],
   it=> [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre'
   ],
  );
$longmonth_list_by_locale{de}= $longmonth_list_by_locale{de_CH};


# map *all* sorts of month names to the month number (0..11):
use Chj::Parse::Date::daysmonthsutils 'list_of_arrays_to_hash__with_startidx';
our $lcmonth_hash =
  list_of_arrays_to_hash__with_startidx(0) # also start at 0, so that back-conversions (using the number as index into an array) work easily.
  ->((values %shortmonth_list_by_locale),
     (values %longmonth_list_by_locale));


# Wed, 29 Mar 2006 05:28:32 +0200: better code, copy from days.pm:

sub TurnToHashes {
    my ($h)=@_;
    map {
	my $locale= $_;
	my $ary= $$h{$locale};
	my $i=1; # starting at 1! btw relying on map running through in straight direction
	$locale=> scalar {
	    map {
		$_=> $i++
	    } @$ary
	}
    } (keys %$h)
}

our %shortmonth_hash_by_locale= TurnToHashes \%shortmonth_list_by_locale;
our %longmonth_hash_by_locale= TurnToHashes \%longmonth_list_by_locale;



1;
