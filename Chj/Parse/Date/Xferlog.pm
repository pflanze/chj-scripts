# Mon Jan 19 22:48:30 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Parse::Date::Xferlog

=head1 SYNOPSIS

parse_date_xferlog("Fri Dec  7 16:34:28 2001")

=head1 DESCRIPTION

functional only.


=cut


package Chj::Parse::Date::Xferlog;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      parse_date_xferlog
	     );

use strict;
use Carp;
use POSIX 'strftime';
use Chj::Parse::Date::months;


warn "EXPERIMENTAL, see ...::Localtime instead";

# -----
# exception setup:
# fehlerklassenweise handler setzen.

#our %errorhandler= (
#		    
#		   );

use enum qw(E_success
	    E_noprimarymatch
	    E_invalidmonthname
	    E_invalidparts_EHGIBTSDOCHGARNIEsighwarirrtummeinerseits
	    E_dateoutofrange
	   );#ps. E_invalidparts gibts nicht nur im Sinne dass strftime selben wert geben würd, sondern es gibt gar keinen fehler wenn z.B. stundenangabe >24 ist.

our $error;
#our %errorhandler= (
		    #E_noprimarymatch, Foo::Bar->can("throw"),  HMMM inklusive der class will ich diese sub. aber unten im kontext ausführen, daher lieber keine neue sub hier.
		    # oder doch nur klassen namen, immer throw?
		    # könnt dann ja immer noch wrapperklassen machen  für mehr flexibel?
		    #hey könnt hier auch objekte speichern. auf welche dann throw geht. damit noch mehr fun machbar.
#		    );
# hey mann ich doch array.
#our @errorhandler;
#$errorhandler[E_noprimarymatch]=...;
#...
#(oder mit ner map(ehr?och) und doppelliste)
# ah noch ne weitere idee: n austauschbares dings?!:
our $errorhandlers;
#$$errorhandlers[E_noprimarymatch]= ...;
#$errorhandlers= [ ... ];

use elcms_general_settings; use EL::Exception();####ç
{
    package Chj::Parse::Date::Xferlog::Exception::Noprimarymatch;##ist hierige Platzierung gute idee? (woran erkennt man wasfür eine exception konstruktion es ist?) ##ps. syntaxfilter wirklich n wichtiger punkt, für ->can("croakthrow")||->can("throw")||... zeugs.  oder eben rausfinden wie ich sonst von soner neuen schurksub aus dann die frames entfernen lassen.
    our @ISA='EL::Exception'; #ps isches nich funny dass strict hier noch wirkung hat?
}
{
    package Chj::Parse::Date::Xferlog::Exception::InvalidMonthname;
    our @ISA='EL::Exception';
}
{
    package Chj::Parse::Date::Xferlog::Exception::InvalidParts;
    our @ISA='EL::Exception';
}
{
    package Chj::Parse::Date::Xferlog::Exception::DateOutOfRange;
    our @ISA='EL::Exception';
    ### Ps. nun muss ich *hier* wieder schauen, dass ich n stackframe ignorier. *und wie schon wieder*. vgl. Thea.
    ##ps. ethrow Idee statt throw? eben doch gescheiter mit ->can hantieren  aber auch gleich die parameterliste reintun?  ****ist das ein function object? ****
    #####ah  ja und dann noch   dass   croak  statt throw . damit auch ohne trace schlecht eh schön.
}

$$errorhandlers[E_noprimarymatch]= 'Chj::Parse::Date::Xferlog::Exception::Noprimarymatch';
$$errorhandlers[E_invalidmonthname]= 'Chj::Parse::Date::Xferlog::Exception::InvalidMonthname';
#$$errorhandlers[E_invalidparts]= 'Chj::Parse::Date::Xferlog::Exception::InvalidParts';
$$errorhandlers[E_dateoutofrange]= 'Chj::Parse::Date::Xferlog::Exception::DateOutOfRange';
# -----

sub parse_date_xferlog {
    my ($s)=@_;
    # 'bewährte' kombination aus selber zerlegen und dann durch strftime in unix verwandeln.
    $s=~ /^(\w+) +(\w+) +(\d+) +(\d+):(\d+):(\d+) +(\d+)$/
      or do { $error=E_noprimarymatch; return };
    my ($dayname,$monname,$mday,$hour,$min,$sec,$year)=($1,$2,$3,$4,$5,$6,$7);
    defined(my $mon= $Chj::Parse::Date::months::short_english_month{$monname})
      or do{ $error=E_invalidmonthname; return };
    my $rv=strftime('%s',$sec,$min,$hour,$mday,$mon-1,$year-1900);
      #or do{ $error=E_invalidparts; return };
      #or do{ $error=E_dateoutofrange; return };
    #if (!$rv) { $error=E_invalidparts; return };
    if ($rv<0) { $error=E_dateoutofrange; return };
    $rv
}
*parse=\&parse_date_xferlog;

sub xparse_date_xferlog {
    &parse_date_xferlog or do {
	$$errorhandlers[$error]->throw   ## nun ja, was ich verliere ist der ort genau  wo der fehler entstand. auch wenn ich den wenn ich croak verwende doch kaum je wissen will (resp gar nicht wirklich kann, ausser ich wolle das auch noch in das dings einbauen. hm.)
    };
}
*xparse=\&xparse_date_xferlog;


__END__

PS. Fragen zusammengestellt:
- sollen die versionen der routine die keine exception werfen, die routine verwenden welche exceptions wirft?  egal ob ja oder nein: soll der error in ner global gespeichert werden ala errno? (in C isses (super) effizient, in perl? well. zahlen? strings? packages/symbols?)
- sollen sie unixinteger geben oder ein date/time objekt?

Mit return values könnte man spielen? in C++ nicht so sehr.
(in lisp prüfung?)



__END__
#use POSIX "strptime"; nope.
use Time::Piece;

#sub parse_xferlog_line {
#    local $_=shift if @_;
#    /.....

sub parse_date_xferlog {
    #my $s=shift;
    my ($s)=@_;
    #strptime('%a %b %d %R %Y',$s)
    eval {
	#Time::Piece->strptime('%a %b  %d %H:%M:%S %Y',$s)  #hmm now returns an obj.krach. und HMMMMM gibt eh schon eine exception.
	#Time::Piece->strptime('%H:%M:%S',$s)->epoch
	Time::Piece->strptime($s,'%a %b %d %H:%M:%S %Y')->epoch  # %R verstehts auch nicht. UND DEN WOCHENTAG Prüfts nicht.  einfach schrott.
	    # Hatte ich das nich schon mal? "ach vertrau doch ner std library" format like  evenifidontlike  aha problem?likeimorenow?
      };
}
*parse=\&parse_date_xferlog;
sub xparse {
    &parse or croak "invalid date '@_'";
}

1;

__END__
Was erwart ich von der klass?
subklasse von date klasse?  oder bloss retournieren eines solchen.!
dann reicht aber, solang ich keine werte sonst speichern muss (eh das kann ich dann ja nicht) eine funktion. isch dann auch weniger verwirrend. logo.
  Klassenmethoden würden nur Sinn machen, wenn inheritance benutzt. Für instanzlose klassen? hm?


