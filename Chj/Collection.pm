# Mon Jan 15 13:45:53 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Collection

=head1 SYNOPSIS

 use Chj::Collection ':all';

 our $c1= Collection 1,2,3,2;
 our $c2= Collection 3,4,5;
 our $joined= Collection_add $c1,$c2;
 our $joined_custom= Collection_merge_with sub { our ($a,$b)=@_; $a }, $c1,$c2;
 #   which is pointless here.
 # our $joined_custom_objs= Collection_merge $c1,$c2;
 #   would only work if either the items were blessed into a class
 #   with a "merge_with" method, or $Chj::Collection::current_merge
 #   is localized
 our $c1_without_c2= Collection_subtract $c1,$c2;
 our $c2_without_c1= Collection_subtract $c2,$c1;
 our $all_nonduplicates= Collection_add $c1_without_c2, $c2_without_c1;
# our $always_true= Collection_equalp $all_nonduplicates, Collection_intersect $c1,$2;
#nochnichtvorhanden und EH EHfalsch.
 our $the_duplicates= Collection_intersect $c1,$c2;
 our $always_empty= Collection_intersect $all_nonduplicates, $the_duplicates;

 # currently collections rely on having values; so to make "real hash
 # style collections" work we need this, ugh: (maybe this should change though)
 our $coll= Collection_from_hash +{ foo=> undef, bar=> undef };

 # Collection_subtract could be called Collection_remove, especially
 # the Hashcoll_subtract_d could deserve that name.

=head1 DESCRIPTION

"merge" and "add" are join operations, where "merge" allows to look at
the objects with identical 'keys' and generate new ones by use of the
merge_with method or dynamic parameter.

'The other common set(?) operations are:'

"subtract" is  XXX.

"intersect" is XXX.


old docs:

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


=head1 BUGS

No way for customizing key generation is provided (only a custom merge
operation) currently.

=cut

#'

#used by:
# - google-searcher script

package Chj::Collection;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      Collection
	      Collection_from_hash
	      Collection_add Collection_addnew Collection_merge_with Collection_merge
	      Collection_subtract
	      Collection_intersect
	      Collection_items
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
# turn the argument list into a 'proper' collection.

# This does an implicit "join" operation (only one of the objects with
# 'identical keys' survives).

sub Collection {
    +{ map { $_=> $_ } @_ }
}

#sigh. turn value-less hashes to things that work here  hmm  or should I change Items back above  ?????
sub Collection_from_hash ( $ ) {
    +{ map { $_=> $_ } keys %{$_[0]} }
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


# "merge" is a special form of "join" which allows to custom merge
# items 'with identical keys'.

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
    #return {} unless @_;# die überbleibsel von keiner menge ist auch keine menge. --HMM falsch? das hier ist eh nicht intersect? gam (-) gibt error.
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

sub Hashcoll_of_collection ($ ) {
    ((ref $_[0] eq "HASH") ? $_[0]
     :
     #(ref $_[0] eq "ARRAY") ? Collection (@{$_[0]}) #moreperformantvariant?
     #:
     #die "unknown collection type of '$_[0]'") #undwaswennobjirgendwas?.
     Collection (Items $_[0]))# und was wenn es eine pseudo hash collection ist?
}

sub Collection_intersect {
    return {} unless @_;#DO NOT FORGET edge cases [when working with nonrecursive syntax]
    my $first= shift;
    # expect all of the others to be hash collections (for fast lookup):
    my @rest= map {
	Hashcoll_of_collection ($_)
    } @_;
    my $result= {};
  VALUE: for my $value (Items $first) {
	my $key= "$value";#ok? or use Itempairs ?
	for my $hashcoll (@rest) {
	    if (!exists $hashcoll->{$key}) {
		next VALUE;
	    }
	}
	$result->{$key}=$value; ###provide 'merge' operations ?
	#BTW IST JA IDENTISCH ZU merge operation einfach dass im else case nicht added wird sondern skipped (und zwar early).!
    }
    $result
}


1
__END__

"GOT.
main> :d Collection_subtract ([1],[2]);
$VAR1 = {
          '1' => 1
        };
main> :d Collection_subtract ([1],[1]);
$VAR1 = {};
das IST ja gar nicht überschiebe (intersec)
"
