# Thu Dec 20 06:02:53 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::Date

=head1 SYNOPSIS

 my $parser= Chj::Parse::Date::Localtime->new;
 my $unixtime= $parser->xparse("Don Dez 20 05:09:38 MET 2007");
 my $unixtime= $parser->parse("Don Dez 20 05:09:38 MET 2007")
   or die $parser->errmsg;

=head1 DESCRIPTION

Parse the date format as printed by the "date" utility. In either the
LANG=C locale or some other locales (German, at least).

=cut


package Chj::Parse::Date::Date;

use strict;
use utf8;

use enum qw(E_success
	    E_invalidformat
	    E_invalidmonthname
	    E_invaliddayname
	   );
#	    E_dateoutofrange
our @errmsgs;
$errmsgs[E_invalidformat]= "invalid date format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_invaliddayname]= "invalid day name";
#$errmsgs[E_dateoutofrange]= "date out of range";

use Chj::Parse::Date::months '$lcmonth_hash', '%shortmonth_list_by_locale';
use Chj::Parse::Date::days '%shortday_list_by_locale', '$lcday_hash';
use Date::Parse 'str2time';
use Chj::singlequote 'singlequote_many';

our $day_idx2english = $shortday_list_by_locale{en};
our $day_anystr2idx= $lcday_hash;
our $month_idx2english= $shortmonth_list_by_locale{en};
our $month_anystr2idx= $lcmonth_hash;

use Class::Array -fields=>
  -publica=> 'error', #numeric
  ;


sub Convert ( $ $ $ ) {
    my ($str2idx,$idx2str,$str)=@_;
    if (defined(my $i= $$str2idx{lc $str})) {
	$$idx2str[$i] or die "?? index not contained in array: $i (original string value '$str')";
    } else {
	return
    }
}

sub parse_segments {
    my $s=shift;
    my ($weekday_str,$month_str, $mday,$hour,$min,$sec, $zone_str,$year)=@_;
    # now it would be fine if we had a module that took numbers, including zone, to do the conversion. but since gmtime and suchstuff just ignore zones and I do not know whether that would work out correctly by just correcting the resulting unixtime value, I go create strings for reparsing here.
    if (defined
	(my $weekday_str_en=
	 Convert ($day_anystr2idx, $day_idx2english, $weekday_str))) {
	if (defined
	    (my $month_str_en=
	     Convert ($month_anystr2idx, $month_idx2english, $month_str))) {
	    my $newstr= "$weekday_str_en $month_str_en $mday $hour:$min:$sec $zone_str $year";
	    if (defined (my $t= str2time ($newstr))) {
		$t
	    } else {
		die "?? parse_segments(".singlequote_many(@_)."): str2time can't parse, shouldn't happen here, internal inconsistency, got str '$newstr'";
		##ok könte noch sein dass zonen nid stimmen oder solches -- wie dies genau konsistent handhaben?
	    }
	} else {
	    $$s[Error]= E_invalidmonthname;
	}
    } else {
	$$s[Error]= E_invaliddayname;
	return
    }
}

sub parse {# hm can still throw exceptions, since str2time can (as man Date::Parse says)
    my $s=shift;
    my ($str)=@_;
    if (defined (my $t= str2time ($str))) {
	$t
    } elsif (my @v= $str=~ /^(\w{3}) (\w{3}) {1,2}(\d{1,2}) (\d{2}):(\d{2}):(\d{2}) (\w{1,4}) (\d{4})\z/) {
	if (defined (my $t= $s->parse_segments (@v))) {
	    $t
	} else {
	    # error already saved
	    return
	}
    } else {
	$$s[Error]= E_invalidformat;
	return;
    }
}

#COPY from ::Localtime.pm
sub errortext {
    my $self=shift;
    $errmsgs[$$self[Error]]
}
*errmsg= \&errortext;
#/COPY

end Class::Array;


__END__

perl -w -MDate::Manip -e 'Date_Init("Language=German");  print ParseDate("Mon Dez 10 19:39:58 MET 2007")'
2007121019:39:58
