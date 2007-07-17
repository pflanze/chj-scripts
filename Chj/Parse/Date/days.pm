# Wed Mar 29 05:15:03 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::days

=head1 SYNOPSIS

=head1 DESCRIPTION

(I needed those for EiD and DateTime was .so)

=head1 SEE ALSO

Chj::Parse::Date::months

=cut


package Chj::Parse::Date::days;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      %shortday_list_by_locale
	      %longday_list_by_locale
	      %shortday_hash_by_locale
	      %longday_hash_by_locale
	     );

use strict;


# :d ($dt = DateTime::Locale->load( 'it' ))-> day_abbreviations
# etc.

our %shortday_list_by_locale=
  (
   de=> [
	 'Mo',
	 'Di',
	 'Mi',
	 'Do',
	 'Fr',
	 'Sa',
	 'So'
	],
   en=> [
	 'Mon',
	 'Tue',
	 'Wed',
	 'Thu',
	 'Fri',
	 'Sat',
	 'Sun'
	],
   fr=> [
	 'lun.',
	 'mar.',
	 'mer.',
	 'jeu.',
	 'ven.',
	 'sam.',
	 'dim.'
	],
   it=> [
	 'lun',
	 'mar',
	 'mer',
	 'gio',
	 'ven',
	 'sab',
	 'dom'
	],
  );

our %longday_list_by_locale=
  (
   de=> [
	 'Montag',
	 'Dienstag',
	 'Mittwoch',
	 'Donnerstag',
	 'Freitag',
	 'Samstag',
	 'Sonntag'
	],
   en=> [
	 'Monday',
	 'Tuesday',
	 'Wednesday',
	 'Thursday',
	 'Friday',
	 'Saturday',
	 'Sunday'
	],
   fr=> [
	 'lundi',
	 'mardi',
	 'mercredi',
	 'jeudi',
	 'vendredi',
	 'samedi',
	 'dimanche'
	],
   it=> [
	 "luned\x{ec}",
	 "marted\x{ec}",
	 "mercoled\x{ec}",
	 "gioved\x{ec}",
	 "venerd\x{ec}",
	 'sabato',
	 'domenica'
	],
  );




# modified copy from months.pm:
#hm no rewritten now.

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

our %shortday_hash_by_locale= TurnToHashes \%shortday_list_by_locale;
our %longday_hash_by_locale= TurnToHashes \%longday_list_by_locale;

1
