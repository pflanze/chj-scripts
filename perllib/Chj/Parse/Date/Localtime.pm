# Mon Jan 19 22:48:30 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Parse::Date::Localtime

=head1 SYNOPSIS

 my $parser= Chj::Parse::Date::Localtime->new;
 my $unixtime= $parser->xparse("Fri Dec  7 16:34:28 2001");
 my $unixtime= $parser->parse("Fri Dec  7 16:34:28 2001")
   or die $parser->errmsg;



=head1 DESCRIPTION

OO only - in spite of the fact that currently functional would suffice
(at least we have err code per-object)

=cut


package Chj::Parse::Date::Localtime;

use strict;
use utf8;
use Carp;
use POSIX 'strftime';
use Chj::Parse::Date::months;


use enum qw(E_success
	    E_invalidformat
	    E_invalidmonthname
	    E_dateoutofrange
	   ); #ps. E_invalidparts gibts nicht nur im Sinne dass strftime selben wert geben würd, sondern es gibt gar keinen fehler wenn z.B. stundenangabe >24 ist.
our @errmsgs;
$errmsgs[E_invalidformat]= "invalid date format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_dateoutofrange]= "date out of range";


use Class::Array -fields=> (
			    'Error',# numeric id
			   );



sub parse {
    my $self=shift;
    my ($str)=@_;
    # 'bewährte' kombination aus selber zerlegen und dann durch strftime in unix verwandeln.
    $str=~ /^(\w+) +(\w+) +(\d+) +(\d+):(\d+):(\d+) +(\d+)$/
      or do { $$self[Error]=E_invalidformat; return };
    my ($dayname,$monname,$mday,$hour,$min,$sec,$year)=($1,$2,$3,$4,$5,$6,$7);
    defined(my $mon= $Chj::Parse::Date::months::short_english_month{$monname})
      or do{ $$self[Error]=E_invalidmonthname; return };
    my $rv=strftime('%s',$sec,$min,$hour,$mday,$mon-1,$year-1900);
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



__END__

vgl. Chj::Parse::Date::Xferlog für volles Fragenpaket
