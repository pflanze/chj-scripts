# Mon Jan 15 13:45:53 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
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


 A "Collection" here is either:
   - an array
   - a hash which contains the item in the value position and it's
     stringification in the key position (called "Hashcoll")
   - an object with "items" and "itempairs" methods.

 The functional routines generally always return "Hashcoll"ections, but
 accept either kind of collections as inputs. There are also some
 destructive routines which work on "Hashcoll" as input type.

=cut

#used by:
# - google-searcher script

package Chj::Collection;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      Collection Collection_add Collection_addnew Collection_subtract Collection_items
	      Collection_merge_with Collection_merge
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

sub Hashcoll_add_d ($ $ ; $ ){ # destructive
    my ($first,$second,$overwrite)=@_;
    for my $key (Items($second)) {
	$$first{$key}= $key if ($overwrite or not exists $$first{$key});
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

sub mkCollection_add {
    my ($overwrite)=@_;
    sub {
	return {} unless @_;
	my $first= shift;
	return $first unless @_;# no copy. unlike (append foo) which still creates a copy ?.
	my $result= _copy ($first);
	for (@_) {
	    Hashcoll_add_d ($result, $_, $overwrite)
	}
	$result
    }
}

*Collection_add= mkCollection_add (1);

*Collection_addnew= mkCollection_add (0);

sub Collection_merge_with ($ ; @ ) { # not &, for old fp reasons..
    my $merge= shift;
    return {} unless @_;
    my $first= shift;
    return $first unless @_;# no copy. unlike (append foo) which still creates a copy ?.
    my $result= {};
    for ($first, @_) {
	for my $item (Items $_) {
	    my $key= "$item";
	    if (exists $$result{$key}) {
		#$$result{$key}= $merge->($$result{$key}, $item);  nope, could be that the key has changed now (albeit unlikely since that would be strange)
		my $new= $merge->($$result{$key}, $item);
		my $newkey= "$new";
		if ($newkey eq $key) {# in the hope that this could be a bit faster.
		    $$result{$key}= $new;
		} else {
		    delete $$result{$key};
		    $$result{$newkey}= $new;
		}
	    } else {
		$$result{$key}= $item; # [or also call $merge? or a single-argument $filter?]
	    }
	}
    }
    $result
}

our $current_merge= sub ($ $ ) {
    $_[0]->merge_with ($_[1])
};

sub Collection_merge {
    Collection_merge_with ($current_merge, @_)
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
