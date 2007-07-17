# Fri Aug 20 02:19:18 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Trash

=head1 SYNOPSIS

 use Chj::Trash 'trash';
 trash "some/item";

=head1 DESCRIPTION


Neues Prinzip:

Trash/unixtime-$$/quotedoriginalplace/item(s)
               ^--^ oder vice versa besser:
Trash/quotedoriginalplace/unixtime-$$/item(s)

OOOODER:
Trash/unixtime:$$:$i:quotedoriginalpath
"cool" aber
OOOH:
pfadlängenproblem. EH.

Also:
Trash/unixtime:$$:$i:itemname/itemname
                             /.orig blabla öhm? conflictwieder. -> oben  i-itemname. oder simply "item".

Trash/unixtime:$$:$i:itemname/item
                             /origplace -> symlink

OOOCH:
und was wenn itemname zusammen mit meinem zeugs zu lang wird?
(idee  symlink item->aufs item im ordner  aber dann habe ich wiede rkonfliktproblem)
also:
Trash/unixtime:$$:$i/item/itemname
                    /origplace
ODER:
Trash/unixtime:$$:$i/item
                    /origpath
-> und dann auf origpath schauen die ganze zeit.
(oder ev doch itemname, sofern nicht zu lang, auch in trashitemname nehmen - jedenfalls gescheiter als nochmals n dir nur um itemname lassen zu können. viel gescheiter.)






und auch gleich  auf jeder partition einen trash haben können?
und dann zwei trash befehle, einer mit -force quasi, der mv aufrufen tut wenn nötig.


Wie ohne xlinkunlink atomizität gewährleisten? rename auf zufallspfad zuerst, dann kann es nicht nochmals jemand renamen, also nun schauen ob target belegt, wenn nicht, zweites rename. Geht aber ned mit move - ev symlink hinputten als lock? oder echt lock ?

=cut


package Chj::Trash;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(trash
	      path_quote
	      path_dequote
	      trashcan
	     );
use strict;
use Carp;
#use Chj::Web::FileescapeUrl qw(fileescapeurl); schit nein hat einen bug.
use Chj::Cwd::realpath "xrealpath";

our $trashcan;
sub trashcan {
    return $trashcan if defined $trashcan;
    my $t;
    if ($t=$ENV{TRASHCAN}) {
    } elsif (-e ($t=$ENV{HOME}."/Desktop/Trash/")) {
    } elsif (-e ($t=$ENV{HOME}."/Desktop/Mülleimer/")) {
    } else {
	croak "Could not find your trash can";
    }
    $trashcan=$t
}

# #sub quotedpath($ ) {
# sub path_quote($ ) {
#     my ($path)=@_;
#     # / nach -,  - nach \-, \- nach \\-
#     $path=~ s|\\|\\\\|sg;
#     $path=~ s|-|\\-|sg;
#     $path=~ tr|/|-|;
#     # oooder: / nach -, - nach --, -- nach --- usw.  eh nein gleicher bug.
#     # na, - nach --, / nach -. aber still gleicher bug bei adjacent weiss man nicht mehr welches der / war auch wenn man sieht dass ungerade.
#     $path;
# }
# sub path_dequote($ ) {
#     my ($str)=@_;
#     #$str=~ s|\\(.)|my $c=$1;
#     #if ($c eq "\\") {
#     #	"\\"
#     #} elsif ($c eq
#     # man. was alles zurück?. \ \  \ -   . -    also  . . hm.
#     #$str=~ s%(^|.)-%
#     #  my $c=$1;
# #     while($str=~ s%(.)(.)%
# # 	my ($a,$b)=($1,$2);
# # 	if ($a eq "\\") {
# # 	    $b
# # 	} else {
# # 	    if ($b eq "-") {
# # 		"$a/"
# # 	    } else {
# # 		"$a$b"
# # 	    }
# # 	}
# # 	  %sec){
# # 	#warn "nun eines weiter, kann man das überhaupt?";
# # 	#pos($str)--;#und das?
# # 	my $pos=pos $str;
# # 	warn "pos=$pos";
# # 	pos($str)=$pos-1;
# #     }
# #     #%sge;#geht nicht weil es um 1 zeichen schieben müsste aber um 2 tut.
#     # unenlightenment.
#     my $copy="";
#     #my $lastchar;#=substr($str,0,1);
#     my $lastwasbackslash;
#     for (my $i=0; $i<length $str; $i++) {
# 	my $curchar=substr($str,$i,1);
# 	if ($lastwasbackslash) {
# 	    $copy.= $curchar;
# 	    undef $lastwasbackslash;
# # 	} else {
# # 		if ($curchar eq "-") {
# # 		    $copy.="$lastchar/";
# # 		} else {
# # 		    if ($curchar eq "\\") {
# # 			$lastchar=$curchar;#?

# # 		    } else {
# # 			$copy.="$lastchar$curchar";
# # 		    }
# # 		}
# # 	    }
# 	} else {
# 	    # undefined lastchar;
# 	    if ($curchar eq "\\") {
# 		#$lastchar= $curchar;
# 		$lastwasbackslash=1;
# 	    } elsif ($curchar eq "-") {
# 		$copy.="/";
# 	    } else {
# 		$copy.=$curchar;
# 	    }
# 	}
#     }
#     #$copy.= $lastchar if $lastchar;
#     #$copy.="\\" if $lastwasbackslash;# \ at the end of string. hmmm. would not follow rules.
#     $copy
# }

# sub _test {
#     "--abc-d-e" eq path_quote "//abc/d/e" or die;
#     '\\\\233f2f-saf\\\\\\---\\\\-' eq path_quote '\233f2f/saf\-//\/' or die;
#     '\233f2f/saf\-//\/' eq path_dequote '\\\\233f2f-saf\\\\\\---\\\\-' or die;
#     print "ok\n";
# }



our $iteration=0;

sub trash($ ) {
    # implementation subject to change
    my ($path)=@_;
    # do not call realpath on $path since we want to trash the given item not it's target; we want to realpath the parent.
    #(todo, should really be standard functions, really....)
    my $parent= $path=~m|/| ? do {
	my $p=$path;
	$p=~ s|[^/]+\z||s;
	$p
    } : ".";
    $parent= xrealpath $parent;
    my $itemname= do {
	my $p=$path;
	$p=~ s|^.*/||s;
	$p
    };
    my $trashcan=trashcan;
    #my $trashitem= time().":$$:$iteration:".path_quote("$parent/$itemname");
    #my $trashitem= time().":$$:$iteration:$itemname";
    my $trashitem= time().":$$:$iteration";
    $iteration++;
    mkdir "$trashcan/$trashitem"
      or croak "trash: mkdir '$trashcan/$trashitem': $!";
    symlink "$parent/$itemname","$trashcan/$trashitem/origpath"
      or croak "trash: link '$parent/$itemname','$trashcan/$trashitem/origpath': $!";
    my $tmppath= "$trashcan/$trashitem/tmp-".rand(100000);
    rename "$parent/$itemname",$tmppath
      or do {
	  #### cross device link.
	  croak "trash '$path': rename to '$tmppath': $!";
      };
    rename $tmppath,"$trashcan/$trashitem/item"
      or croak "trash: rename '$tmppath','$trashcan/$trashitem/item': $!";
}

1;
