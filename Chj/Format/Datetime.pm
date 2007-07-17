# Thu Oct 20 08:16:49 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Datetime

=head1 SYNOPSIS

=head1 DESCRIPTION

Copied from EL::Util::DateFormat

=cut


package Chj::Format::Datetime;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(unix2xsdatetime unix2xsdatetimewithzone);

use strict;

use Carp;

sub unix2xsdatetime { # XML Schema DateTime format
    my ($time)=@_;
    my ($sec,$min,$hour,$d,$m,$y)= localtime($time);
    sprintf("%04d-%02d-%02dT%02d:%02d:%02d",$y+1900,$m+1,$d,$hour,$min,$sec)
}

sub sign {
    @_ > 1 ? map { $_ >= 0 ? "+" : "-" } @_ : $_[0] >= 0 ? "+" : "-"
}
our $localzoneseconds; ## = 2*60*60; ## DateTime::TimeZone does not work. :(
sub unix2xsdatetimewithzone { # XML Schema DateTime format
    my ($time,$zoneseconds)=@_;
    my ($sec,$min,$hour,$d,$m,$y)= localtime($time);
    unless (defined $zoneseconds) {
	unless(defined $localzoneseconds) {
	    #require DateTime::TimeZone;
	    #my $tz = DateTime::TimeZone->new( name => 'local' ) or croak "unix2xsdatetimewithzone: could not determine local timezone; maybe add it as second parameter";
	    #$localzoneseconds= $tz->offset_for_datetime;
	    # above does not work, does not return an object.
	    my $zonestr= `date '+%z'`;
	    my ($sign,$hour,$minute)= $zonestr=~ /([+-])(\d{2})\:?(\d{2})/ or croak "unix2xsdatetimewithzone: could not determine local timezone (could not parse date output '$zonestr'); maybe add it as second parameter";
	    $localzoneseconds= ($sign eq '+' ? 1 : -1) * ( $hour * 3600 + $minute * 60);
	}
	$zoneseconds= $localzoneseconds;
    }
    use integer;
    sprintf("%04d-%02d-%02dT%02d:%02d:%02dUTC%s%02d:%02d",$y+1900,$m+1,$d,$hour,$min,$sec,
	    sign( $zoneseconds), abs($zoneseconds)/3600, abs($zoneseconds) % 3600)
}


1
