# Sat Jun 12 20:11:05 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::MySQL::Cnf

=head1 SYNOPSIS

=head1 DESCRIPTION

Better than MySQL::Config or some sort of.
You are always better off just doing it yourself than firing down time the line of searching cpan, trying it out, finding out it doesnt what u need

#? Parse a port. string port, file port, whatever.


=head1 TODOOOOOOOO

- scheint, undef geht doch ned als rückgabe wert, weil so skip-networking u.ä. wertlos sind.  auch muss ich parsing anpassen.
- hmm, manchmal kommen comments VOR dem [section] marker.  comments auch als leerzeile interpretieren? am besten wär, "leerzeile und dann comments und kein leer mehr" in dieser reihenfolge isch leer. well.

=cut


package Chj::MySQL::Cnf;

use strict;
use Carp;
use Chj::xopen qw(xopen_read);
use Chj::xtmpfile;#### eben, wie?

use Chj::DataStructure::Megalist;

use Class::Array -fields=> (
			    'Path',
			    #'Str',
			    #'Contentlines',# @  no sense.
			    #'Db', # sectionname=>key=>[characterpos_of_value,len,value]
			    # subvalues not split here yet, thus would have to recreate hm
			    'List',# contains both value parts and the stuff inbetween. hm, to be able to add stuff, it's also broken up just before any new [section] line. Well, each line by itself  [except in future if there are multi-line-values]
			    'Sectionends', # pointers to the last non-empty element of a section (for appends). sectionname=>[listelementrefs]
			    #'Eof', # last element of whole file  what for??? => [List]->last. eehr no doesn' work (with empty file) like that. ; again different: last||entrypoint rule; Eof would be bad because would have to be nachgeführt, too.    Even better!: since checking for above two, I can decide whether to call value!
			    'Db', # sectionname=>key=>[listelementrefs] (hopefully only one?)
			    'Scope_section',
			   );


sub get_by_path {
    my $class=shift;
    my $self= $class->SUPER::new;
    ($$self[Path])=@_;
    my $f= xopen_read $$self[Path];
    my $list= new Chj::DataStructure::Megalist;
    my $sectionname=""; # empty group at first yeah :)
    my $lastnonemptyel ##wieder raus, weil ich dann doch gescheiter elegant ifs.  oder doch wieder rein, weil sonst bei creierendem set eine sektion  [] kreiert wird wenn das file leer war resp wenn die sektion leer war meinich.
      = $list->entrypoint; # half life
    #my $lastel= $lastnonemptyel; ach forgetit, macht auch nix wenn ich leerzeilen unten drinlasse
    while (defined(my $line=$f->xreadline)){
	if ($line=~ /^\s*[#;]/) { # comment; todo: As of MySQL 4.0.14, a comment can start from a middle of a line, too.
	    $lastnonemptyel= $list->appendvalue($line);
	} elsif ($line=~ /^\s*$/) {
	    $list->appendvalue($line);
	} elsif ($line=~ /^\s*\[([^]]+)\]/) {
	    my $newsectionname=$1;
	    push @{$$self[Sectionends]{lc $sectionname}}, $lastnonemptyel;
	    $sectionname=$newsectionname;
	    $lastnonemptyel=$list->appendvalue($line);
	} elsif ($line=~ /^(\s*([^\s=]+)\s*=\s*)(.*?)(\s*)\z/s) {
	    my ($pre,$key,$val,$post)=($1,$2,$3,$4);
	    $list->appendvalue($pre); # includes key!
	    my $el=$list->appendvalue($val);
	    $lastnonemptyel=$list->appendvalue($post);
	    push @{ $$self[Db]{lc $sectionname}{lc $key} }, $el;
	} else {
	    warn "line does not match any criteria: '$line'";
	    $lastnonemptyel= $list->appendvalue($line);
	}
    }
    push @{$$self[Sectionends]{lc $sectionname}}, $lastnonemptyel;
    #$$self[Eof]=$lastnonemptyel;
    $f->xclose;
    $$self[List]=$list;
    $self
}

sub set_scope_section {
    my $self=shift;
    ($$self[Scope_section])=@_;
}

sub get {
    my $self=shift;
    my ($key)=@_;
    if (my $el= $$self[Db]{lc $$self[Scope_section]}{lc $key}[-1]) { # take the last occurence of it. ##
	$el->value
    } else {
	#croak "no value found for section '$$self[Scope_section]', key '$key'";
	undef
    }
}

sub set {
    my $self=shift;
    my ($key,$value)=@_;##to do eben values irgendwie subvalue gschmois
    if (my $el= $$self[Db]{lc $$self[Scope_section]}{lc $key}[-1]) { # dito ##
	# overwrite existing value
	$el->value= $value;
    } else {
	# append new entry to last occurrence of section
# 	my $sectendref= \  $$self[Sectionends]{lc $$self[Scope_section]}[-1];
# 	my $el=$$sectendref;
# 	croak "no such section '$$self[Scope_section]'"
# 	  unless $el;##currently throwing an error unless such a section exists
# 	$el= $el->appendvalue("$key= ");
# 	$el= $el->appendvalue($value);
# 	push @{$$self[Db]{lc $$self[Scope_section]}{lc $key} },$el;
# 	$el= $el->appendvalue("\n");
# 	$$sectendref= $el;
#-> Modification of non-creatable array value attempted, subscript -1  (already at line containing \ above). hm maybe it still works in the non-emptysection case
	my $el= $$self[Sectionends]{lc $$self[Scope_section]}[-1];
	if (!$el) {
	    # create new section at end of file.
# 	    #$el= $$self[Eof];
# 	    $el= $$self[List]->last||$$self[List]->entrypoint;
# 	    #$el= $$self[List]->entrypoint;  so schräg, das last isch wirkli nötig?. ah klar: after last, after entrypoint.
# 	    unless ($el->value =~ /\n\z/s) {
# 		$el= $el->insertvalue_after("\n");
# 	    }
	    if ($el= $$self[List]->last) {
		unless ($el->value =~ /\n\z/s) {
		    $el= $el->insertvalue_after("\n");
		}
	    } else {
		$el= $$self[List]->entrypoint;
	    }
	    $el= $el->insertvalue_after("[$$self[Scope_section]]\n");
	    # append it to the list of sections. (well the section end is just to be changed again below,heh, but I guess this is ok)
	    push @{$$self[Sectionends]{lc $$self[Scope_section]}}, $el;
	} else {
	    unless ($el->value =~ /\n\z/s) {
		$el= $el->insertvalue_after("\n");
	    }
	}
	$el= $el->insertvalue_after("$key= ");
	$el= $el->insertvalue_after($value);
	push @{$$self[Db]{lc $$self[Scope_section]}{lc $key} },$el;
	$el= $el->insertvalue_after("\n");
	# replace sectionend of the last section
	my $arr= $$self[Sectionends]{lc $$self[Scope_section]};
	$arr->[$#$arr]=$el;#hugh
    }
}

sub to_string {
    my $self=shift;
#     my $el= $self->[List]->first;
#     my @v;
#     while ($el) {
# 	push @v, $el->value;
# 	$el=$el->next;
#     }
#     join "",@v
    #mann ich dubel hab für das ja was geschrieben.
    join "",$$self[List]->values
}

1;
