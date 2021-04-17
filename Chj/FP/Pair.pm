# Tue Sep 14 03:10:35 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Pair

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Pair;

use strict;
use utf8;
use Chj::Predicates;
use Carp;

use Class::Array -fields=>
  -publica=>('Car',
	     'Cdr');

{
    package Chj::FP::EmptyList;
    my $emptylist="EmptyList";
    $Chj::FP::EmptyList= bless \$emptylist,__PACKAGE__;
    sub values {
	()
    }
    sub stringify {
	"()"
    }
}


sub new {
    my $class=shift;
    bless [ $_[0],$_[1] ],$class;
}

sub cons {
    my $proto=shift;
    if (ref $proto) {
	# my $list= Chj::FP::Pair->new("Foo");
	# $list=$list->cons("Bar");
	return ref($proto)->new(shift,$proto);
    } else {
	# Chj::FP::Pair->cons("Foo",$list);#same as new
	return $proto->new(@_);
    }
}

sub list {
    my $proto=shift;
#    if (@_>1) {
    if (@_) {
	bless [shift, $proto->list(@_)], $proto   #ps dies ist nicht tail rec
#    } elsif (@_==1) {
#	bless [shift,],$proto
#	  # hm falsch: wenn @_==0  sollte es doch gar nix ausgeben.  ?   oder?
    } else {
	#() auch falsch. richtig:
	#undef  # leider kann meine implementation dann eben nicht unterscheiden zwischen '() und #f
	  #gsi:
	  #> '()
	  #()
	  #> #f
	  ##f
	  #> (list)
	  #()
	  # ich brauche einen runtimetypisierten nullpointer, typisiertes undef.
	  #calc> :l bless undef, "Fun"
	  #Can't bless non-reference value at (eval 33) line 1.
	  #calc> :l bless \ undef, "Fun"
	  #Modification of a read-only value attempted at (eval 34) line 1.
	  # und eine ref auf etwas ist nicht mehr nullpointer/undef.
	# also lass ich es eben doch bei undef,  das verwende ich als end code bei cdr bisher schon.
	$Chj::FP::EmptyList;
    }
}

sub cddr {
    #shift->[Cdr][Cdr]
    my $p=shift;#  or croak "cddr: argument is false";
    $p= $$p[Cdr] or croak "cddr: cdr is not set";
    $$p[Cdr]
}
sub cdddr {
    #shift->[Cdr][Cdr][Cdr]   #ps. das failed ja  wenn liste zu kurz. aber ja: scheme tut das auch. PAIR expected. OHOH: todo: ich faile ja gar nicht hier, autovivication mann. (und gibt dann, und zwar eins zu früh (eh nein, eben, '() ist undef bei mir), undef und darauf geht values nicht.)  DASS '()->list bei mir einen fehler gibt isch ev eben doch schitty.
    my $p=shift;#  or croak "cdddr: argument is false";
    $p= $$p[Cdr] or croak "cdddr: cdr is not set";
    $p= $$p[Cdr] or croak "cdddr: cddr is not set";
    $$p[Cdr]
}

sub cadr {
    #shift->[Cdr][Car]
    my $p=shift;#  or croak "cadr: argument is false"; eh ich tubel, dann gibt method invocation schon fehler.
    $p= $$p[Cdr] or croak "cadr: cdr is not set";
    $$p[Car]
}
sub caddr {
    #shift->[Cdr][Cdr][Car]
    my $p=shift;#  or croak "caddr: argument is false";
    $p= $$p[Cdr] or croak "caddr: cdr is not set";
    $p= $$p[Cdr] or croak "caddr: cddr is not set";
    $$p[Car]
}
sub cadddr {
    #shift->[Cdr][Cdr][Cdr][Car]   # ev sollte eben vorsichtig gewesen sein weil das autovivify macht  was falsch ist.##todo.
    my $p=shift;#  or croak "cadddr: argument is false";
    $p= $$p[Cdr] or croak "cadddr: cdr is not set";
    $p= $$p[Cdr] or croak "cadddr: cddr is not set";
    $p= $$p[Cdr] or croak "cadddr: cdddr is not set";
    $$p[Car]
}

sub map {# attention: returns a pair list again, not a perl list :)
    my $s=shift;
    my ($code)=@_;
    ref($s)->new(scalar $code->($$s[Car]),
		 ($$s[Cdr] && $$s[Cdr] != $Chj::FP::EmptyList) ? $$s[Cdr]->map($code) : $Chj::FP::EmptyList);
}

# perl specific:
sub values { #turn into a perl list. funny that the CORE::values function for hashes is doing the same.
    my $s=shift;
    #hm.
    #can't build a perl list accross function calls, right?. and recursion w/o function calls are impossible as well. and map{} works on perl lists...
    #thus: hang onto the imperative branch
    my @ret;
#     my $getone;$getone=sub{
# 	my ($s)=@_;
# 	push @ret,$s->[Car];
# 	$s->[Cdr] ? $getone->($s->[Cdr]) : ();
#     };$getone->($s);
    #ok, be sane.
    while(defined $s and $s != $Chj::FP::EmptyList) {## sollte ich  eher auf  inklusive  also auf Pair  prüfen?
	push @ret,$s->[Car];
	$s=$s->[Cdr];
    }
    @ret
}

# sub stringify {
#     my $s=shift;
#     my $car= $$s[Car];
#     my $cdr= $$s[Cdr];
#     "(".
#       join(" . ",  #DAMIT
# 	   do{
# 	       if (ref $car) {
# 		   if ($car->isa("Chj::FP::Pair")) {
# 		       $car->stringify
# 		   }else {
# 		       "$car" ## hm
# 		   }
# 	       } else {
# 		   "\"$car\""; ####
# 	       }
# 	   },
# 	   defined ($cdr) ? do {
# 	       # "must" be a pair?
# 	       $cdr->stringify;
# 	       #} : ())
# 	       } : "()")# und DAMIT  stimmts dann. aber gibt eben die dottedform.
#       .")"
# }

sub stringify_atom { ## not a method
    my ($car)=@_;
    if (is_glob $car) {
	string_of_symbol $car,"main" ##well.
    } else {
	# escape scheme-like:
	## hm, damit geht var interpol verlorn.
	my $str="$car";
	if (is_number $str) {
	    $str
	} else {
	    $str=~ s/\"/\\\"/sg;
	    "\"$str\""
	}
    }
}
sub stringify_element { # atom or list (or..?)
    my ($car)=@_;
    if (!defined $car) {
	"#f" ## well.  auch noch ein todo hängend?
    } elsif (ref $car) {
	if (ref($car) eq 'HASH') {
	    "{".join(" ",
		     map {
			 #stringify_atom($_), ###hmm.
			 $_,
			   stringify_element($car->{$_})
		     } sort keys %$car
		     )."}"
	} elsif ($car->isa("Chj::FP::Pair")) {
	    $car->stringify
	} elsif ($car == $Chj::FP::EmptyList) {
	    "()"  #heh, brauche die methode in Chj::FP::EmptyList gar nicht?
	} else {
	    "$car" ## hm
	}
    } else {
	#"\"$car\"";
	stringify_atom $car
    }
}

sub stringify {
    my $s=shift;
    my $car= $$s[Car];
    my $cdr= $$s[Cdr];
    my $out= "(";
  LOOP: {
        $out.= stringify_element $car;
        #if (defined $cdr and ref $cdr and $cdr->isa(__PACKAGE__)) { ## viele Wege nach Rom
	# Fälle:
	# - [undef (hm wirklich?) oder] $Chj::FP::EmptyList:  reguläres listenende.
	# - ref $cdr and $cdr->isa(__PACKAGE__): reguläre listenfortsetzung.
	# - sonst (ref oder nicht ref): dotted end.
	if (defined $cdr) {
	    if (ref $cdr) {
		if ($cdr->isa(__PACKAGE__)) {
		    $car= $$cdr[Car];
		    $cdr= $$cdr[Cdr];
		    $out.=" ";
		    redo LOOP;
		} elsif ($cdr == $Chj::FP::EmptyList) {
		    last LOOP;
		}
		# else let through to dotted end.
	    }
	    # else let through to dotted end.
        } else {
	    last LOOP ##well - if doing it strict with expecting $Chj::FP::EmptyList, that'd be a dotted end.
	}
	# dotted end:
	$out.= " . ". stringify_element $cdr;
    };
    $out.")"
}

*string = *stringify; # Fri, 28 Apr 2006 00:58:35 +0200, ok?


Class::Array::end;
