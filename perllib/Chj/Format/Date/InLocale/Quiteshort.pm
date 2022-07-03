# Wed Mar 29 16:28:20 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::InLocale::Quiteshort

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Date::InLocale::Quiteshort;

use strict;

use Chj::Format::Date::InLocale -extend=>
  -publica=>
  ;


sub _format_datepart {
    my $s=shift;
    my ($wday, $mday,$mon,$year)=@_;
    $wday--;
    #$mon--; nope we use it as number here
    $year=substr($year,2);
    if ($$s[Locale] eq 'de'
	or $$s[Locale] eq 'fr' #I think so.
	or $$s[Locale] eq 'it' #ok? assume the CH language regions all can read this, at least.
       ) {
	"$mday.$mon.$year"
    } else {
	## assume that all the others use english style  (~sigh)
	$mon= "0$mon" if length($mon)<2;
	$mday= "0$mday" if length($mday)<2;
	"$year/$mon/$mday"
    }
}

end Class::Array;
