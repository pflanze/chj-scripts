# Sun Feb 12 23:57:17 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::XSDatetime

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


# (done for rss-gen script)

package Chj::Parse::Date::XSDatetime;

use strict;

use POSIX 'strftime';

use Class::Array -fields=>
  -publica=>
  ;


# https://en.wikipedia.org/wiki/ISO_8601

# parse e.g.
# 2006-02-09T06:00:00UTC+01:00

sub xparse_to_unix {
    my $s=shift;
    my ($str)=@_;
    if (my ($year,$mon,$mday,$hour,$min,$maybe_sec,
	    $zonewhat, $maybe_plusminus, $zone_hour,$zone_minute)
	=
	$str=~ /^(\d{4})-(\d{1,2})-(\d{1,2})T(\d{1,2}):(\d{1,2})(?:\:(\d{1,2}))?(\w+)([+-]?)(\d{1,2}):(\d{1,2})/) {
	$zonewhat eq "UTC" or warn "invalid time ? : '$zonewhat' in '$str'";
	#### just ignore zone infos. todo.
	my $rv=strftime('%s',$maybe_sec||0,$min,$hour,$mday,$mon-1,$year-1900);
	if ($rv<0) {
	    #$$self[Error]=E_dateoutofrange; return
	    die "date out of range";
	}
	$rv
    } else {
	die "invalid date format: '$str'";
    }
}


end Class::Array;
