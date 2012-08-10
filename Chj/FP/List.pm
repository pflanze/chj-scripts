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

