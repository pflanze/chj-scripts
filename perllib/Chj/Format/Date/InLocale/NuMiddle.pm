# Wed Mar 29 05:54:33 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::InLocale::NuMiddle

=head1 SYNOPSIS

=head1 DESCRIPTION

With weekday, but numeric month  ("Numeric Middle") (and no comma after week day)

=cut


package Chj::Format::Date::InLocale::NuMiddle;

use strict;
use Chj::Parse::Date::days  ('%shortday_list_by_locale');

use Chj::Format::Date::InLocale -extend=>
  -publica=>
  ;

sub _format_datepart {
    my $s=shift;
    my ($wday, $mday,$mon,$year)=@_;
    $wday--;
    #$mon--; nope we use it as number here
    my $days= $shortday_list_by_locale{$$s[Locale]}
      or die "no shortday definition for locale '$$s[Locale]'";## proper exceptions
    if ($$s[Locale] eq 'de'
	or $$s[Locale] eq 'fr' #I think so.
	or $$s[Locale] eq 'it' #ok? assume the CH language regions all can read this, at least.
       ) {
	"$$days[$wday] $mday.$mon.$year"
    } else {
	## assume that all non de use english style  sigh
	$mon= "0$mon" if length($mon)<2;
	$mday= "0$mday" if length($mday)<2;
	"$$days[$wday] $year/$mon/$mday"
    }
}

end Class::Array;
