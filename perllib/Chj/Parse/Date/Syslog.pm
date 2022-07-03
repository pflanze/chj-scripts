# Tue Jan 20 04:31:45 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::Syslog

=head1 SYNOPSIS

 my $parser= Chj::Parse::Date::Syslog->new(2001);#start year; will be incremented if parse steps wrap over the month.
 defined(my $unix= $parser->parse("Dec 23 16:21:51"))  ##not 100% sure a defined 0 never means an error, though
   or die "error: ".$parser->errmsg; #erinnert an LWP. Kapselt ab (trennwand des fehlerhandlings)


=head1 DESCRIPTION

OO only - this is because it must track the year.

=cut


package Chj::Parse::Date::Syslog;

use strict;
use Chj::Parse::Date::months;
use Carp;
use POSIX 'strftime';
use Chj::Algo::CircularWraparound "circwrap";

use enum qw(E_success
	    E_invalidformat
	    E_invalidmonthname
	    E_dateoutofrange
	   );
our @errmsgs;
$errmsgs[E_invalidformat]= "invalid date format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_dateoutofrange]= "date out of range";


use Class::Array -fields=> (
			    'Year',
			    'Lastmonth',
			    'Error',# numeric id
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    ($$self[Year])=@_;
    $self
}

sub parse {
    my $self=shift;
    my ($datestr)=@_;
    $datestr=~ /^(\w+) +(\d+) +(\d+):(\d+):(\d+)$/
      or do{ $$self[Error]=E_invalidformat; return };
    my ($monname,$mday,$hour,$min,$sec)=($1,$2,$3,$4,$5);
    defined(my $mon= $Chj::Parse::Date::months::short_english_month{$monname})
      or do{ $$self[Error]=E_invalidmonthname; return };
    if ($$self[Lastmonth]){
	$$self[Year]+= circwrap($$self[Lastmonth],$mon,12);
    }
    $$self[Lastmonth]=$mon;
    my $rv=strftime('%s',$sec,$min,$hour,$mday,$mon-1,$$self[Year]-1900);
    if ($rv<0) { $$self[Error]=E_dateoutofrange; return };
    $rv
}

sub errortext {#kann man sich vertippen
    my $self=shift;
    $errmsgs[$$self[Error]]
}
*errmsg= \&errortext;

sub xparse {
    my ($self)=@_;
    &parse or croak $self->errmsg." '@_'"; # statt kompliziertes echtes exceptionhandling.
}

1;
