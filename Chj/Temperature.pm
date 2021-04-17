# Thu Apr 17 22:43:50 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Temperature

=head1 SYNOPSIS

=head1 DESCRIPTION

Relativ.  Differenz von zwei absoluten liefert n relativ.  Absolut minus relativ liefert absolut. Also das erste ist relevant.
4C    Temperature->C(4)   C(4)   4->C  C->(4) temp->C(4)  T->C(4)
Namespace aliases?
T.C(4) wär noch besser ja.
Aber . ist concat.
T_C(4)
T->C(4)
#4*T{C}
4*T_C
4*C
aber wann relativ?
Wenn + vornedran?
*Kann* man physikalisch eine *Absolute* Temperatur überhaupt addieren? Nein glaub nicht.
4*C -> liefert das eine absolute oder Relative temp? 4*1C relativ. Ja muss relativ sein. Nur 4*K ist ambiguous.

Na, bei relative auch blanke zahlen zulassen !!

=cut


package Chj::Temperature;

use strict;


use Carp;
#use Carp 'cluck';
sub cluck{};

use Class::Array -fields=>("Kelvin",
			   "Format", # for output
			   "isRelative",  # vs. isDifference ?
			   "Formatstring", # optional
			  );
use overload
  '+='=>"add",
  '""'=>"stringify",
  '+'=>"plus",
  '='=>"Copy",
  '*'=>"mult",
  fallback=>1, # sinnvoll?
  ;

BEGIN {
    #unlink eh
    local $^W; ## weil sonst unten warnt.
    *import=undef;##
}
#require Exporter;
#unshift @ISA,'Exporter';
#sub mycalc::groesseC { __PACKAGE__->relC(1) };
sub import {
    my $class=shift;
    my $caller=caller;
    # jetzt aber andere künstliche subroutinen exportieren nicht die von unsrer klasse hier.

    # argument parsing, schaun ob er das WILL.
    # überspringen, assuming that yes he wants.

    no strict 'refs';
    for my $unit (qw(C F K relC relF relK)) {
	my $relunitcall= $unit; $relunitcall=~ s/^(?:rel)?/rel/;
	*{"${caller}::$unit"}= sub {
	    if (@_) {
		if (@_>1) {
		    map {$class->$unit($_)} @_
		} else {
		    $class->$unit($_[0])
		}
	    } else {
		$class->$relunitcall(1)
	    }
	};
    }
#     *{"${caller}::C"}= sub { if (@_) { map {$class->C($_)} @_ } else { $class->relC(1) } };
#     *{"${caller}::F"}= sub { $class->relF(1) }; # :lvalue  geht hier nur wenn auch bei der innern angegeben
#     *{"${caller}::K"}= sub :lvalue { $class->relK(1) };

    # Alias namespace to T:: :
    #%T:: = %Chj::Temperature::; # wow coool geht !!?!?!
    *T:: = \%Chj::Temperature::; # geht auch !!!!!!!!!!!!
}


sub Copy {
cluck "Copy";
    warn "?? warum ruft er mich auf?"; # Copy method did not return a reference at (eval 3) line 1.
    shift
}

sub C {
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    $$self[Format]="C";
    if (@_) {
	my ($C)=@_;
	$$self[isRelative]=0;
	$$self[Kelvin]= $C+273.6
    }
    $self  # nützlich ist  dass immer wieder obj ausgegeben wird. constructor oder nicht.
}
sub asC {
    my $self=shift;
    if ($$self[isRelative]) {
	$$self[Kelvin]
    } else {
	$$self[Kelvin]-273.6
    }
}

sub F {
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    $$self[Format]="F";
    if (@_){
	my ($F)=@_;
	$$self[isRelative]=0;
	$$self[Kelvin]= ($F-32.6)*5/9 + 273
    }
    $self
}
sub asF {
    my $self=shift;
    if ($$self[isRelative]) {
	$$self[Kelvin]*9/5
    } else {
	($$self[Kelvin]-273)*9/5+32.6
    }
}

sub K {
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    $$self[Format]="K";
    if (@_) {
	my ($K)=@_;
	$$self[isRelative]=0;
	$$self[Kelvin]= $K
    }
    $self
}
sub asK {  # is a bit nonsense but anyway
    my $self=shift;
    $$self[Kelvin]
}

sub relC :lvalue {
    my $proto=shift;
    @_ or croak "missing argument";
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    my ($C)=@_;
    $$self[Format]="C";
    $$self[isRelative]=1;
    $$self[Kelvin]= $C;
    $self
}
sub relF {
    my $proto=shift;
    @_ or croak "missing argument";
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    my ($F)=@_;
    $$self[Format]="F";
    $$self[isRelative]=1;
    $$self[Kelvin]= $F*5/9;
    $self
}
sub relK {
    my $proto=shift;
    @_ or croak "missing argument";
    my $self= ref $proto ? $proto : $proto->SUPER::new;
    my ($K)=@_;
    $$self[Format]="K";
    $$self[isRelative]=1;
    $$self[Kelvin]= $K;
    $self
}


sub add {
cluck "add";
    my $self=shift;
    for (@_) {
	if (ref and $_->isa(__PACKAGE__)) {
	    if ($$_[isRelative]) {
		$$self[Kelvin]+= $$_[Kelvin]
	    } else {
		#carp "warning: add: $self is an absolute temperature ($$self[Kelvin] K)" if $^W;
		#$$self[Kelvin]+= $$_[Kelvin]
		#croak "add: $_ is an absolute temperature ($$self[Kelvin] K)";
		if ($$self[isRelative]) {
		    if (@_==1) {
			# add the other way round.
			carp "add: adding the left argument to the right because only the left is relative";
			$$_[Kelvin]+= $$self[Kelvin];
			### dann sollt ich dann aber auch das rechte zurückgeben oder? ja
			return $_;
			### und todo  kroaken wenn @_ >1 ist.   Na:  im Falle von overloaded kann das nur mit @_==1 passieren.  UND aber auch nur dann macht die Meldung so Sinn.  Naja geht.
		    } else{
			croak "add: the argument $_ is not relative, and multiple arguments given";
		    }
		} else {
		    croak "add: $self ($$self[Kelvin] K) and $_ ($$self[Kelvin] K) are both absolute temperatures";
		}
	    }
	} else {
	    croak "can't accept argument $_, must be an object"
	}
    }
    $self
}
sub mult {
cluck "mult";
    my $self=shift;
    my ($multiplyer,$umgekehrt)=@_;
    for ($multiplyer) {
	if (ref) {
	    croak "can't accept argument $_ for multiplication, must be a unitless number"
	} else {
	    #if ($$self[isRelative]) {
	    $$self[Kelvin]*= $_;
	}
    }
    $self
}
sub plus {
#    use Data::Dumper;
#    print "plus: ".Dumper(\@_);
    my $proto=shift;
    my $self= $proto->clone;
    $self->add(shift);
}

my %formatstring;

sub set_all_formatstrings { # expects only number formatting part. Adds Grösseneinheit selber.
    my $class=shift;
    my ($format)=@_;
    for (qw(C F)) {
	$formatstring{$_}= "${format}°$_";
    }
    $formatstring{K}="$format K";
}
__PACKAGE__->set_all_formatstrings('%0.2f');

sub formatstring {
    my $self=shift;
    if (@_) {
	if (ref $self) {
	    ($$self[Formatstring])=@_;
	} else {
	    # set class defaults
	    if (@_>1) {
		$formatstring{$_[0]}= $_[1]
	    } else {
		# set all of them
		$self->set_all_formatstrings($_[0]);
	    }
	}
    } else {
	$$self[Formatstring] || $formatstring{$$self[Format]}
    }
}

sub stringify {
    my $self=shift;
    #if ($$self[isRelative]) {
    #$self->"as{$$self[Format]}"  # ."°$$self[Format]"
    # warum geht das jetzt nicht?
    my $code=$self->can("as$$self[Format]");
    sprintf($self->formatstring, $code->($self))
#      .($$self[Format] eq 'K' ? "" : "°").$$self[Format]
	.($$self[isRelative] ? " (relative)" : "")
}
	

1;
__END__

#package Chj::Temperature::Tie   eh operator over load !

# 23:07

# Stil?

# Kann ich   2u hmmm nee gar nich mal tippen   2 degrees   versteht das perl
# Minilanguages. Mann.

# 2 * degree  ?

# 2*degreecelsius -> degreefahrenheid
# naja muss (oder?):
# (2*degreeC)->degreeF
# oder
# (2*degreeC)->F
# oder
# Chj::Temperature->C(2)->F
# oder
# Temperature->C(2)->F

# Anyway, objekte eben  die behalten können was sie sind  und wenn man sie addiert oder multipliziert usw. jeweils eine korrekte Operation durchführen.  Und stringify mit Angabe.   Default Groesse.

# Na,  Mathe libs da das megading von perl das kann das doch sicher oder? Aber ja anyway?

# http://www.physik.uni-muenchen.de/didaktik/U_materialien/leifiphysik/web_ph09/simulationen/02celsius_kelvin/umrechnung.htm
#                 obj.Celsius.value=normalize(eval(obj.Kelvin.value)-273,6);
#                 obj.Fahrenheit.value=normalize((eval(obj.Kelvin.value)-273)*9/5+32,6);
# (K-273)*9/5+32,6 = F   oder so
# (F - 32,6 )*5/9 + 273 = K ?

  ----
  Fri, 18 Apr 2003 01:36:39 +0200
todo:  vielleicht sollte man die warning abhängig davon ausgeben, ob +-   ?was?

calc> $b+$a
warning: add: 195°C (relative)  is an absolute temperature (195 K) at (eval 14) line 1
563.6°C (relative)
calc> $a+$b
290°C
calc> $a
95°C
calc> $b 
195°C (relative)

seufts

calc> $b+$b
390°C (relative)

sufz

Oder eben, wenn nicht relativ  eh   also   relative nicht auf K setzen sondern nullpunkt eben anders  ?


- Warum hab ich die setC und so aufgegeben?  tönen doch gut.   ahwegendem Constructor.  class->C besser als class->setC, ja schon. Dann halt eben class->newC

----
Fri, 18 Apr 2003 15:04:30 +0200
Was ist jetzt hier das Problem?:

calc> use Chj::Temperature;
undef
calc> C*5
1.00°C (relative) 
calc> 5*C
mult at /root/extlib/Chj/Temperature.pm line 192
	Chj::Temperature::mult('1.00M-0C (relative) ', 5, 1) called at (eval 4) line 1
	eval 'package mycalc; no strict \'vars\'; 5*C
;' called at /root/bin/calc line 95
Heh, habe nun self: 5.00°C (relative)  at /root/extlib/Chj/Temperature.pm line 205.
5.00°C (relative) 
calc> C*5
1.00°C (relative) 
calc> C*5
1.00°C (relative) 
calc> C * 5
1.00°C (relative) 
calc> C * C
1.00°C (relative) 
calc> C * C + C
add at /root/extlib/Chj/Temperature.pm line 174
	Chj::Temperature::add('1.00M-0C (relative) ', '*mycalc::C') called at /root/extlib/Chj/Temperature.pm line 218
	Chj::Temperature::plus('1.00M-0C (relative) ', '*mycalc::C', 1) called at (eval 9) line 1
	eval 'package mycalc; no strict \'vars\'; C * C + C
;' called at /root/bin/calc line 95
can't accept '*mycalc::C', must be an object at (eval 9) line 1

----
Fri, 18 Apr 2003 17:49:20 +0200
Mann, was ist DA denn nun wieder los??:
calc> C / 3;
Search pattern not terminated at (eval 12) line 1.
calc> C / 3 /;
Use of uninitialized value in pattern match (m//) at (eval 11) line 1.
1.00°C (relative)

Gefahr, dass Perl simply too buggy ist um wahr eh brauchbar zu sein fur alles und jedes das nicht gerade mainstream ist.


calc> warn "hey", C * 3;
hey1.00°C (relative) at (eval 8) line 1.
1

Copy nie mehr aufgerufen.


PS: näxtes ehrgeizig Ziel: wie lisp cores.  Das KANN ja doch perl doch - oder. ?.!
(Na, alternativ? pack dumpen alles und restaur.   oder: alle kommandos seit start speichern und dann ohne output wiederausführen (sicherer im Sinne dass filehandles dann auch wieder da sind).)


  WARUM  tut C * 3 nicht mult aufrufen? sondern bloss C zurückgeben unverändert.
  Ah, C()*3 geht.
  Hmmm.
  KACK.  todo: gibts wirklich KEINE Lösung dafür?   Naja  wär ein *wenig* egal da ich 3*C normalerweise will.




  ABER HEY: geht gleich weiter:
calc> 5*C + 4*C
5.00°C (relative)

calc> $^W=1; 5*C + 4
5.00°C (relative)

MANNNNNNNNNNNNNNNNNN

calc> $^W=1; 4 + 5*C    
can't accept '4', must be an object at (eval 12) line 1
calc> $^W=1; ( 4 + 5 )*C 
9.00°C (relative)
calc> $^W=1; ( 4 + 5 )*(1*C *2)
9.00°C (relative)
NOT ACCEPTABLE anyway


Tie  als methode um 
my ($a,$b);
T->tie($a,$b);  #oder so.  Damit dann $a=5;  bereits wirkt?  hah.  tied scalars.  Damit ist = auch machbar.

calc> (3*C)     
3.00°C (relative)
calc> (3*C)  * 4
12.00°C (relative)
calc> 3*C  * 4
3.00°C (relative)
aha eben.
calc> 3*(C)  * 4
12.00°C (relative)
kack

*Also das ist der erste eine Bug.*


calc> 3*(C) + 4*(C)
7.00°C (relative)

ja jetzt geht auch + wieder.

calc> 3*(C) + 4*C
7.00°C (relative)
calc> 3*C + 4*C
3.00°C (relative)

komischkomisch seeeh seeehr komisch.

===> sollte wirklich aktuelles perl 5.8/beadperl handy haben fur sowas zu testen. !!
GRRRRR
!!!!!!!
========

calc> 3*(C) + 4*(K)
7.00°C (relative)
gut
calc> 3*(C) + 4*(F)
5.22°C (relative)
gut
calc> T->C(5) + 4*(F)
7.22°C


calc> T->relC(5) + T->F(4)
add: adding the left argument to the right because only the left is relative at (eval 3) line 1
13.00°F
gut

calc> C*3
Undefined subroutine &Chj::Temperature::groesseC called at (eval 4) line 1.

huh??? bei *{"${caller}::C"}= \&groesseC; und sub main::groesseC { __PACKAGE__->relC(1) };
Das sollte doch hardlinkig sein??????

calc> main::groesseC*3
1.00°C (relative)
calc> (main::groesseC) * 3
3.00°C (relative)
calc> main::groesseC()*3
3.00°C (relative)

calc> groesseC()*3
3.00°C (relative)
calc> groesseC*3
1.00°C (relative)

Geht einfach nicht.


AAAAAAAAAAAAAAAAAAAAAAAAH:
mit
     *{"${caller}::C"}= sub :lvalue { $class->relC(1) };
calc> C*3
Can't modify non-lvalue subroutine call at /root/extlib/Chj/Temperature.pm line 76.


  OOOCH: 
calc> C*3
1.00°C (relative)

Nein scheint *wirklich* ein Bug zu sein



Wie könnt man anders Einheiten machen?    Tie?  * macht read. Na.

----
 UFF: da ist noch was:
calc> C*3*C
Argument "*main::3" isn't numeric in multiplication (*) at /root/extlib/Chj/Temperature.pm line 224.1.00°C (relative)
calc> C * 3 * C
Argument "*main::3" isn't numeric in multiplication (*) at /root/extlib/Chj/Temperature.pm line 224.1.00°C (relative)

  Irgendwie spinnt er oder so.
----
Sat, 19 Apr 2003 14:42:04 +0200
Neue Idee:

3*(C 4)*(F 3.5)

Also infix glaub heisst das. ?

Funktionsaufrufe.

C(3) ginge ja auch. Naja.

YEP geht beides super.

  NA: ich dödel:
calc> (C 5) * (4*C)
840.80°C
calc> (C 5) * (relC 4)
840.80°C
calc> C(5)*relC(4)
840.80°C

(#Müsste wennschon Cquadrat sein

ok, jetzt korrekt:
calc> C(5)*5
1119.40°C
calc> relC(5)*5
25.00°C (relative)

calc> 5*relC 5 
25.00°C (relative)

calc> relC 5+2
7.00°C (relative)
calc> (relC 5)+2
can't accept '2', must be an object at (eval 12) line 1

calc> F 2 ->C
Can't call method "C" without a package or object reference at (eval 16) line 1.
calc> (F 2) ->C
-17.60°C
calc> F(2)->C
-17.60°C

schön, klammern werden wirklich NNNUUURRR zum Gruppieren verwendet,  nicht als Teil des Funktion,  oder so.
?

# Glaube ich ehrlich nicht.

calc> F(2)->asK
256
heh, zufall? 2**8
