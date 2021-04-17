# Thu Mar  4 12:38:11 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::DataStructure::Megalist

=head1 SYNOPSIS

=head1 DESCRIPTION

There are lists and listelements. Lists are ordered collections of listelements. New listelements can be added bevore and after existing listelements. List objects always immediately know the first and last listelement of the whole list.

Well, actually the "list" object is two objects: Megalist and Megalist::Entrypoint. This is so that Megalist is not part of circular references and thus will be destroyed automatically.

see Chj/DataStructure/Megalist/test script for an example.

=cut



{
 package Chj::DataStructure::Megalist::Element;
 use strict;

 use Class::Array -fields=> (
			     'Prev',
			     'Next',
			     'Data'
			    );

 sub new {
     my $class=shift;
     my $self= bless[],$class;
     ($self->[Data])=@_;
     $self;
 }

 sub value :lvalue { shift->[Data] };
 #sub next { shift->[Next] };
 #sub prev { shift->[Prev] };
 sub next {
     my $self=shift;
     my $N= $self->[Next];
     #warn "N='$N' (@$N)\n";# am problempunkt isches wirklich ein array das ein element, ein Element, enthält: N='ARRAY(0x8177e3c)' (Chj::DataStructure::Megalist::Element=ARRAY(0x8177f98))
     #$N->isa(__PACKAGE__) ? $N : undef
     # wegen Alpha nun:
     $N->isa("Chj::DataStructure::Megalist::Entrypoint") ? undef : $N
 }
 sub prev {
     my $self=shift;
     my $N= $self->[Prev];
     #$N->isa(__PACKAGE__) ? $N : undef
     # dito
     $N->isa("Chj::DataStructure::Megalist::Entrypoint") ? undef : $N
 }

 sub insertvalue_before {
     my $self=shift;
     my $new= Chj::DataStructure::Megalist::Element->new(@_);
     my $P= $self->[Prev];
     $P->[Next]= $new; # special case!: this even works if $P is an ::Entrypoint object, it sets it's Last field in that case.
     $new->[Prev]= $P;
     $new->[Next]=$self;
     $self->[Prev]=$new  # returning $new!
 }
 sub insertvalue_after {
     my $self=shift;
     my $new= Chj::DataStructure::Megalist::Element->new(@_);
     my $N= $self->[Next];
     $N->[Prev]=$new;
     $new->[Next]= $N;
     $new->[Prev]=$self;
     $self->[Next]=$new  # returning $new!
 }

#  sub DESTROY {
#      warn "DESTROY of ".shift
#  }
}

{
 package Chj::DataStructure::Megalist::Entrypoint;##nachtrag(040612): warum nicht Head genannt? Wollte ich wirklich glauben, dass zirkuläre liste, wo der entrypoint selber auch ein element isch oder was? IST sie denn zirkulär?  Ja ist sie nun  komisch könnti ja eben auch andersch machen  viel uberlegen noch  (hohn einsack"?") ansonsten  jedenfalls warum nicht head?: weil head und tail  etwas anders besetzt sind bei listen.
 use strict;
 use Carp;

 use Class::Array -fields=> (
			     'Last',# ATTENTION: leav this order as is!, so that the index Last==Element::Prev
			     'First', # and First==Element::Next; the logic behind this is: we are the circular-link in the chain, between the end and the start of the list, and .. Next Next First Next .. is the order of steps in that case
			     'Data'
			    );
# unshift @ISA,"Chj::DataStructure::Megalist::Element";


 sub first { shift->[First] }
 sub last { shift->[Last] }

 sub appendvalue {
     my $self=shift;
     my $new= Chj::DataStructure::Megalist::Element->new(@_);
     if (my $L= $self->[Last]) {
	 # hm, code für handling wirklich hier?
	 $L->[Chj::DataStructure::Megalist::Element::Next]= $new;
	 $new->[Chj::DataStructure::Megalist::Element::Prev]= $L;
     } else {
	 # first element
	 $self->[First]=$new;
	 $new->[Chj::DataStructure::Megalist::Element::Prev]= $self; #! eben hier uebergang.
     }
     $new->[Chj::DataStructure::Megalist::Element::Next]= $self; #!
     $self->[Last]=$new; # and return $new !
 }

 sub destroy { # ooch: muss man ja manuell aufrufen!! darum noch wrapper unten
     my $self=shift;
     my $N=$self->[First];
     while ($N and not $N->isa(__PACKAGE__)) {
	 undef $N->[Chj::DataStructure::Megalist::Element::Prev];
	 $N=$N->[Chj::DataStructure::Megalist::Element::Next];
     }
     undef $self->[First];
     undef $self->[Last];
 }

 sub value { # Alpha.
     #croak __PACKAGE__."::value: there's no value in the EntryPoint";
     "\n" ; #dangerous world. I use it for checking if the previous part contains a \n at the end. So no modification needed.
     # no , croak again, I've done an elegant if/else now since that's needed anyway
     # oder doch wieder rein (und dann halt zwar als "\n" statt "")  weil ich sonst in Chj/MySQL/Cnf nicht pseudosektions-lastelement angeben kann.
 }# nun ich lass ISA murks doch weg? und machs so?:
# sub insertvalue_after  hm nein doch wirklich identischer code?.  BE CAREFUL EMPTOR
 # tataa, und ich hatte einen krachenden bug deswegen.  also ugly copypaste-&-modify here.
 sub insertvalue_before {
     my $self=shift;
     my $new= Chj::DataStructure::Megalist::Element->new(@_);
     if (my $P= $self->[Last]) {
	 $P->[Chj::DataStructure::Megalist::Element::Next]= $new;
	 $new->[Chj::DataStructure::Megalist::Element::Prev]= $P;
     } else {
	 $new->[Chj::DataStructure::Megalist::Element::Prev]= $self;
	 $$self[First]=$new;
     }
     $new->[Chj::DataStructure::Megalist::Element::Next]=$self;
     $self->[Last]=$new  # returning $new!
 }
 sub insertvalue_after {
     my $self=shift;
     my $new= Chj::DataStructure::Megalist::Element->new(@_);
     if (my $N= $self->[First]) {
	 $N->[Chj::DataStructure::Megalist::Element::Prev]=$new;
	 $new->[Chj::DataStructure::Megalist::Element::Next]= $N;
     } else {
	 $new->[Chj::DataStructure::Megalist::Element::Next]= $self;
	 $$self[Last]=$new;
     }
     $new->[Chj::DataStructure::Megalist::Element::Prev]=$self;
     $self->[First]=$new  # returning $new!
 }
 sub next {
     my $self=shift;
     $self->[First];
 }
 sub prev {
     my $self=shift;
     $self->[Last];
 }

 sub values {
     my $self=shift;
     #ps. perl fehlt eine funktion um iterativ eine liste aufzubauen ohne ein array dazwischen?! grep und map helfen nicht ausser wenn ich ne fake list mache zuerst UND noch einen iterator externen mitführ?.  AH ich weiss ja gar ned vieviele elemente drin sind.
     #my $pos= $self->[First];
     #map {
     my @v;
     my $e=$$self[First];
     while ($e) {
	 #push @v,$e->value;
	 #$e=$e->next;
	 # faster:
	 push @v,$$e[Chj::DataStructure::Megalist::Element::Data];
	 #$e=$$e[Chj::DataStructure::Megalist::Element::Next];
	 $e=$e->next;#abbruchkriterium
     }
     @v
 }

#  sub DESTROY {
#      warn "DESTROY of ".shift
#  }
}


{
 package Chj::DataStructure::Megalist;
 use strict;

 use Class::Array -fields=> (
			     'EP',
			    );

 sub new {
     my $class=shift;
     my $self= bless [],$class;
     #my $NNN= new Chj::DataStructure::Megalist::Entrypoint;
     #$self->[Entrypoint]= Chj::DataStructure::Megalist::Entrypoint->new;
     #Can't call method "new" without a package or object reference
     # WWWOOOOOWW. absolut super. musste ja mal kommen  (Design bug von perl, und ich laufe mit class array mitten rein)
     #$self->[Entrypoint]= "Chj::DataStructure::Megalist::Entrypoint"->new;
     # hab nun field umbenannt
     $self->[EP]= Chj::DataStructure::Megalist::Entrypoint->new;
     $self
 }

 sub entrypoint { # Alpha. und auch wenns ein doofer name isch :~
     my $self=shift;
     $$self[EP];
 }

 sub DESTROY {
     my $self=shift;
     local ($@,$!);
     #$self->[EP]->destroy;
     # Sun, 13 Jun 2004 06:13:01 +0200
     #fun: nun isch EP undef?? seit ich verlinkung wie ich glaubte korrigiert hab.
     $$self[EP]->destroy if $$self[EP];#########verdächtig.
 }

 our $AUTOLOAD;
#  sub AUTOLOAD {
#      my $self=$_[0];
#      #goto $self->[Entrypoint]->can($AUTOLOAD);  nope geht nicht, can't find label SCALAR(...)
#      #goto &{$self->[Entrypoint]->can($AUTOLOAD)};
#      no strict 'refs';
#      my ($subname)= $AUTOLOAD=~ /([^:]+\z)/g;
#      goto &{"Chj::DataStructure::Megalist::Entrypoint::$subname"};
#  }
# ooooooooaah
 sub AUTOLOAD {
     my $self=shift;
     unshift @_,$self->[EP]; #!
     no strict 'refs';
     my ($subname)= $AUTOLOAD=~ /([^:]+\z)/g;
     goto &{"Chj::DataStructure::Megalist::Entrypoint::$subname"};
 }

}

1;
