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

use enum qw(E_success
	    E_invalidformat
	    E_invalidmonthname
	    E_dateoutofrange
	   );
our @errmsgs;
$errmsgs[E_invalidformat]= "invalid date format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_dateoutofrange]= "date out of range";

use Chj::Parse::Date::months;
use Chj::Parse::Date::days;

ççççSHIIIIT  dort hab ich keine 3stelligen.
  ach.
  
use Class::Array -fields=>
  -publica=> 'error', #numeric
  ;

sub parse {# hm can still throw exceptions, since str2time can (as man Date::Parse says)
    my $s=shift;
    my ($str)=@_;
    if (defined (my $t= str2time ($str))) {
	$t
    } elsif (my ($weekday,$month, $mday,$hour,$min,$sec, $zone,$year)
	     =$str=~ /^(\w{3}) (\w{3}) {1,2}(\d{1,2}) (\d{2}):(\d{2}):(\d{2}) (\w{1,4}) (\d{4})\z/) {
	# now create a new string in english format. sigh
	my $t= str2time ()
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
