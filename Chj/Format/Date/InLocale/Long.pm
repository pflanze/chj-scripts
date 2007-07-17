# Wed Mar 29 05:36:28 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::InLocale::Long

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Date::InLocale::Long;

use strict;

use Chj::Format::Date::InLocale -extend=>
  -publica=>
  ;


use Chj::Parse::Date::months ('%longmonth_list_by_locale');
use Chj::Parse::Date::days  ('%longday_list_by_locale');

sub _format_datepart {
    my $s=shift;
    my ($wday, $mday,$mon,$year)=@_;
    $wday--;
    $mon--;
    my $days= $longday_list_by_locale{$$s[Locale]}
      or die "no longday definition for locale '$$s[Locale]'";## proper exceptions
    my $months= $longmonth_list_by_locale{$$s[Locale]}
      or die "no longmonth definition for locale '$$s[Locale]'";## proper exceptions
    if ($$s[Locale] eq 'de') {
	"$$days[$wday], $mday. $$months[$mon] $year"
    } else {
	## assume that all non de use english style  sigh
	"$$days[$wday], $$months[$mon] $mday $year"
    }
}


end Class::Array;
