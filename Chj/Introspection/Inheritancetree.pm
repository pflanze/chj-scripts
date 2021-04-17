# Mon Mar  1 22:43:12 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Introspection::Inheritancetree

=head1 SYNOPSIS

 use Chj::Introspection::Inheritancetree 'inheritancetree';
 use Data::Dumper;
 $Data::Dumper::Sortkeys=1;
 use Chj::IO::Command; # as an example with multiple steps of inh.
 #use LWP;
 print Dumper(inheritancetree "main");

=head1 DESCRIPTION

Returned data structure:

{
  packagename => [ #list of dependencies    (this would prolly be a pairlis in lisp)
                    [ packagename,
                      [ #dependencies
                        packagename..
                      ]
..
} na toplevel sollte auch so ein pair ding sein!

ooder: auch lisp like,  erstes auch in die dep "pairlis" rein.
[#list  - oder vielleicht doch wieder hash hier. values gibt dann list
   [ packagename,
     [ # dep 1
       packagename, [ ],[ ],...
     ],
     [ # dep 2
       packagename, ...
     ]
   ]
]

Noch die Frage ob ich für Ausgabe nach Dumper dependencies so ordnen kann,
dass möglichst alle deps vorher ausgegeben wurden?

nehme ein entry, schau seine erste dep an pushe sie vorher, deren dep,pushvorher, derendep....
(wieder problem loops aber so what)
dann innerste zweite dep auch vor jene, ....   und n cache halten 

my @out; und da rin manipulieren??

oder eher andersch?
(verstehen statt imperativ)

Thu,  4 Mar 2004 12:14:52 +0100
Sort verwenden? zahl ermitteln. hm. wie: dep der dep anschauen. eben gleich selber sortieren

Hm, eine prepend funktion in Listen. die aber auch den primary entry point updated. und: muss dann bidirektionale liste sein. ev auch noch parent also?, ooder parent als special objekt.


=cut


package Chj::Introspection::Inheritancetree;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(inheritancetree dependencyordered);
use strict;
# use Chj::DataStructure::Megalist;

# sub dependencyordered($ ) {
#     my ($hash)=@_;
# #    my $out=[];
# #    my $prepend=sub {
# #	$_[0]

#     my $lis= new Chj::DataStructure::Megalist;

#     # zuerst mal nach Alphabet sortieren.
#     for my $key (sort keys %$hash) {
# 	my $val= $hash->{$key};
# 	my $me= Chj::DataStructure::Megalist::Element->new( $val);
# 	# nun dep s anschauen  und vorher einordnen.
# 	my $deps;$deps=sub {
# 	    my ($of,$firstone)=@_;
# 	    for my $dep ($of->[1,$#$of]) {
# 		my $depname=$dep->[0];
# 		warn "deps: depname=$depname";
# 		#next unless $hash->{$depname};# only consider deps present in main level (sonst bringts für dumper ja nix? well doch schon noch aber, well... ah well: doch ausgeben ! damit es toplevel angezeigt wird !!
# 		## brauch ich ein   find_and_move_to ding?
# 		#damit nicht mehrmals dasselbe reinkopiert wird.  well: *kann auch einfach am schluss ein eliminate machen!*, wenn ichs in eine perlliste ummappe.
# 		$firstone->insertvalue_before($dep);
# 	    }
# 	    und nun eben funktional und nicht for listen iterativ ?
		
# }

sub inheritancetree($ ; $ ) {
    my ($package,$show_all)=@_;
    #$package.="::";#   nein doch nicht?. sondern special case für "" unten.
    my $f= do{
	no strict 'refs';
	*{"${package}::"}{HASH}
    };
    my $cache={};
    my $searchnamespacehash;
    $searchnamespacehash= sub {
	my ($h,$packagename)= @_;
	my $realpackname= $packagename; $realpackname=~ s/::\z//;
	for my $key (keys %$h) {
	    if ($key eq 'ISA') {
#		my $desclis= [$realpackname];
#		$cache->{$realpackname}= $desclis;# save it right at the beginning so that it will already be there in case of circles
# 		for (@{$h->{$key}}) {
# 		    next if $_ eq 'Exporter' and not $show_all and not @{$h->{$key}}>1;# komische Regel.
# 		    #$cache->{"$realpackname"}{$_}=undef; # will be set to a hashref in the end.
# 		    #push @{$cache->{"$realpackname"}},[$_,undef]; # will be completed later
# 		    #push @$desclis,[$_,undef]; # will be completed later
# 		    # eh, isch gar kein pair mehr, sondern packname und rest sind pairs.
# 		    push @$desclis,[$_]; # will be completed later
# 		}
		my $descliscreate; ($descliscreate= sub {
		    my $realpackname=shift;
		    my $desclis= [$realpackname];
		    $cache->{$realpackname}= $desclis;# save it right at the beginning so that it will already be there in case of circles
		    push @$desclis,map { # map package names to desclist references
			# paul simon, spass lassen einfach zu singen
			$cache->{$_} or $descliscreate->($_)  #fun das schaut so ähnlich aus
		    } @{$h->{ISA}};
		    $desclis
		})->($realpackname);
		
	    } elsif ($key =~ /::\z/) {
		# subpackage
		next if $key eq 'main::';
		&$searchnamespacehash( $h->{$key},"$packagename$key");
	    }
	}
    };
    &$searchnamespacehash($f,length($package)? $package."::" : ""); # ugly special case.
#     # set all undefs to refs:
#     for my $pack (keys %$cache) {
# 	#for my $retarget (keys %{ $cache->{$pack} }) {
# 	#    $cache->{$pack}{$retarget}= $cache->{$retarget};
# 	#}
# 	#for (@{ $cache->{$pack} }) {
# 	#    $cache->{$pack}[1]= $cache->{ $cache->{$pack}[0] };  #eigentlich isch es ja scho eine huere komische datenstruktur.
# 	#}
# 	my $desclis= $cache->{$pack};
# 	##my $packname= $desclis->[0]; wen interessiert das hier?
# 	#for ($desclis->[1..$#{$desclis}]) {  #(just cdr..)
# 	#    
# 	#eh
# 	my $packname= $desclis->[0];
#       ach mann, ???. kann bei aufbau neu nich mehr nur einfach packagename nehmen sondern muss ref, d.h. automatisch machen gleich bei creation. und jenen eben einfüllen  auch schon bei creation in der rekursion drin.  ??  aber rekursion dort isch ja eben nicht isa hierarchie sondern namespace hierarchie dh kommt later on right   well wenn überhaupt von wegen exkludes, tja, sollt ich zwei rekursionen machen  und die namespacehierarchie rekursion nur unless done.
#     }
    $cache
}


1;
