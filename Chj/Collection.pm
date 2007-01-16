# Mon Jan 15 13:45:53 2007  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Collection

=head1 SYNOPSIS

=head1 DESCRIPTION

Interface common ?  for  minus etc handling.  on hashes foretc.

..but: we're using functions now (multidispatch as alternative?), so how call it an interface. well how call it in the firstplac.?

yep only works on hashes for now.

Does not modify it's arguments.

=cut


package Chj::Collection;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      Collection Collection_add Collection_subtract Collection_items
	      Hashcoll_add_d Hashcoll_filter_d
	     );
%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;

sub Items ($ ){# olle OO dispatch.
    my ($v)=@_;
    if (ref ($v) eq "ARRAY") {
	@$v
    } elsif (ref ($v) eq "HASH") {
	#keys %$v  hmmmm (rely on that the values are the keys. real things. when we say items.)
	values %$v
    } elsif (my $m= UNIVERSAL::can ($v,"items")) {
	$m->($v)
    } else {
	die "no 'method' for getting items from: $v"
    }
}

sub Itempairs ($ ){# olle OO dispatch.
    my ($v)=@_;
    if (ref ($v) eq "ARRAY") {
	map { $_=> $_ } @$v
    } elsif (ref ($v) eq "HASH") {
        %$v
    } elsif (my $m= UNIVERSAL::can ($v,"itempairs")) {
	$m->($v)
    } elsif ( $m= UNIVERSAL::can ($v,"items")) {# $m from above is still in scope
	map { $_=> $_ } $m->($v)
    } else {
	die "no 'method' for getting itempairs from: $v"
    }
}


# hash output: and those named Hashcoll_* are expecting
# 'hashtable-collections' ("hashes" which contain the item as both key
# and value)

sub _add ($ $ ){
    my ($first,$second)=@_;
    { Itempairs($first), Itempairs($second) }
}

sub Hashcoll_subtract_d ($ $ ){ # destructive
    my ($first,$second)=@_;
    for my $key (Items($second)) {
	delete $$first{$key}
    }
    $first
}

sub _subtract ($ $ ){
    my ($first,$second)=@_;
    Hashcoll_subtract_d { Itempairs($first) },$second;
}

sub Hashcoll_add_d ($ $ ){ # destructive
    my ($first,$second)=@_;
    for my $key (Items($second)) {
	$$first{$key}= $key; #okay?  or undef? orwhat?... should i call $key $item ?.
    }
    $first
}

sub _copy ($ ){
    my ($coll)=@_;
    +{ Itempairs ($coll) }  #don't 'forget' the +
}

sub Hashcoll_filter_d (& $ ) { # destructive filtering function.
    my ($keep_pred,$hashcoll)=@_;
    for (values %$hashcoll) {
	if (not $keep_pred->($_)) {
	    delete $$hashcoll{$_}
	}
    }
    $hashcoll  # (same as input)
}


# constructor:

sub Collection {
    +{ map { $_=> $_ } @_ }
}

# generic functions:

sub Collection_add {
    return {} unless @_;
    my $first= shift;
    return $first unless @_;# no copy. unlike (append foo) which still creates a copy ?.
    my $result= _copy ($first);
    for (@_) {
	Hashcoll_add_d ($result, $_)
    }
    $result
}

sub Collection_subtract {
    die "not enough arguments" unless @_>=1;
    # now unlike (- x) which returns -x this will return the argument unchanged.
    my $first= shift;
    return $first unless @_;# no copy. (see also above)
    my $result= _copy ($first);
    for (@_) {
	Hashcoll_subtract_d ($result,$_)
    }
    $result
}

*Collection_items = \&Items;


1
