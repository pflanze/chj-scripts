# Wed Jan  5 18:04:00 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::listutil

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

http://search.cpan.org/~vparseval/List-Any-0.03/lib/List/Any.pm (I didn't know that one existed before 2005/02/27 / before I've written Chj::listutil)

=cut


package Chj::listutil;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   any
	   every
	   grepmap
	   findidx
	   equal
	  );
#@EXPORT_OK=qw();

#	   maps_to_true
#	   maps_to_false
# ah, any and every
# hm multi list traversal? srfi-1
# egal. andere für jenes
# ps. zu any vgl. auch find!

use strict;
use utf8;

sub any ( & ; @ ) {
    my $c=shift;
    for(@_) {
	return 1 if &$c
    }
}

sub every ( & ; @ ) {
    my $c=shift;
    for(@_) {
	return 0 unless &$c
    }
    1
}

sub grepmap ( & ; @ ) {
    my $c=shift;
    my @res;
    for(@_) {
	my @r= &$c;
	my $grep=shift @r;# the rest are the @map result values to be inserted.
	if ($grep) {
	    push @res,@r
	}
    }
    @res
}

sub findidx ( & ; @ ) {
    my $c=shift;
    if (wantarray) {
	my $i=-1;
	#grepmap ehr. müsste jeweils 2 values, OB rausgeben und WAS rausgeben, returnen von test function.
	# well warum nicht?.
	grepmap {
	    $i++;
	    &$c ? (1,$i) : (0)
	} @_
    } else {
	# stop on first
	my $i=-1;
	for(@_) {
	    $i++;
	    return $i if &$c;
	}
	undef
    }
}

# Tue, 06 Jun 2006 03:45:14 +0200
# eigentlich dachte ich ich hätte das schon mal geschrieben, aber finde nix.
# not very efficient, but I only use it for "human compare tasks" or such. (validity  assertions  checks. or test cases.)  (ahh: /home/chris/perldevelopment/Filepaths/Chj/Filepath/Tests.pm but no, there's not a real equal)

sub equal ( $ $ );
sub equal ( $ $ ) {
    my ($A,$B)=@_;
    #use Chj::singlequote 'singlequote_many'; warn "comparing ".singlequote_many($A,$B);
    # not only operate on lists, but also on more?
    return 1 if $A eq $B;#(compares stringified form.well. ok?.)
    if (UNIVERSAL::isa($A,"ARRAY")) {
	return 0 unless UNIVERSAL::isa($B,"ARRAY");
	return 0 unless @$A == @$B;
	for (my $i=0; $i<=$#$A; $i++) {
	    return 0 unless equal($$A[$i],$$B[$i]);
	}
	return 1
    } elsif (UNIVERSAL::isa($A,"HASH")) {
	return 0 unless UNIVERSAL::isa($B,"HASH");
	return equal ([ %$A ], [ %$B ]);
    } else {
	return 0;# but we're not so sure, right?.  obj's? ... ?  (a good oo lang would provide an equal method already for any object  overridable usw
    }
}

# calc> :l equal ["ab","c"], ["a"."b",do{my $c="c";$c}]
# 1
# calc> :l equal ["ab","c"], ["a"."b",do{my $c="cC";$c}]
# 0


1
