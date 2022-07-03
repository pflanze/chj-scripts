#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::List

=head1 SYNOPSIS

=head1 DESCRIPTION

Functions to handle Pair based lists.
Should have split off Chj::FP::Pair::map into this already.

(Also since Chj::FP::Pair does not have any exports)

(Well, I see, wanted to do all OO or class based. Hm?)

=cut


package Chj::FP::List;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      empty_list
	      nullp
	      cons
	      list
	      list_map
	      list_reverse
	      list_for_each
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::FP::Pair;

sub empty_list () {
    Chj::FP::Pair->list();
}

sub list {
    Chj::FP::Pair->list(@_);
}

sub nullp ($ ) {
    $_[0] eq $Chj::FP::EmptyList
}

sub list_map ($ $ ) {
    my ($fn,$lis)=@_;
    # unlike the method, handle nil, too!
    nullp($lis) ? $lis : Chj::FP::Pair::map($lis,$fn)
}

sub cons ($ $ ) {
    Chj::FP::Pair->cons(@_);
}

sub list_reverse ($ ) {
    my ($l)=@_;
    my $m= empty_list;
    while (! nullp $l) {
	$m= cons($l->car, $m);
	$l= $l->cdr;
    }
    $m
}

sub list_for_each ($ $ ) {
    my ($proc,$l)=@_;
    while (! nullp $l) {
	&$proc ($l->car);
	$l= $l->cdr;
    }
}

1


__END__

Tests

calc> :l (list_map sub{$_[0]+1}, list(1,2,3))->values
2
3
4
calc> :l (list_map sub{$_[0]+1}, list())->values
calc> :l (list_map sub{$_[0]+1}, cons(4, list()))->values
5
calc> :l list_reverse(list(qw(a b c)))->values
c
b
a
calc> :l list_reverse(list(qw()))->values
calc> :l my @a; list_for_each (sub{push @a, "x".$_[0]}, list(qw(a b c))); @a
xa
xb
xc

