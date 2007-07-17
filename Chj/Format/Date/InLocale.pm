# Wed Mar 29 05:31:53 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::InLocale

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Date::InLocale;

use strict;

use Class::Array -fields=>
  -publica=>
  'Locale', # currently 2 lowercase chars ..  must fit those in Chj/Parse/Date/{months,days}.pm
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Locale])=@_;
    $s
}

sub from_unix {
    my $s=shift;
    my ($unix,$flag_show_seconds)=@_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)= localtime($unix);
    $year+=1900;
    $mon++;
    #$wday--; # so that it starts monday with 0, like assumed by Chj/Parse/Date/{months,days}.pm no do that there. since $mon must be subtracted as well
    ($s->_format_datepart($wday, $mday,$mon,$year)
     . " " .
     $s->_format_timepart($hour,$min,$sec,$flag_show_seconds))
}

sub _format_timepart {
    my $s=shift;
    my ($hour,$min,$sec,$flag_show_seconds)=@_;
    #if ($$s[Locale] eq 'en') {
    ( (length($hour)>1 ? $hour : "0$hour") . ":"
      . (length($min)>1 ? $min : "0$min")
      . ($flag_show_seconds ? ":".(length($sec)>1 ? $sec : "0$sec") : ""))
}


end Class::Array;
