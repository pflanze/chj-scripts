#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Alist

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Alist;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      empty_alist
	      alist_add
	      alist_ref
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::FP::Pair;

sub empty_alist {
    $Chj::FP::EmptyList
}

sub alist_add ($ $ $ ) {
    my ($l,$k,$v)=@_;
    #$l->cons($Chj::FP::EmptyList->cons($k,$v))
    #hu is my library stuff so broken. or wll whatever.
    Chj::FP::Pair->cons
	(Chj::FP::Pair->cons($k,$v), $l);
}

sub alist_ref ($ $ $ ) {
    my ($l,$key,$fail)=@_;
    while ($l ne $Chj::FP::EmptyList) {
	my $a= $l->car;
	if ($a->car eq $key) {
	    return $a->cdr
	}
	$l= $l->cdr;
    }
    &$fail
}

1

__END__
Tests
calc> :l alist_ref (alist_add(empty_alist ,'a',1), 'a', undef)
1
calc> :l alist_ref (alist_add(empty_alist ,'a',1), 'b', sub{'notfound'})
notfound
calc> :l alist_ref (alist_add(alist_add(empty_alist ,'a',1), 'a', 2), 'a', sub{'notfound'})
2
calc> :l alist_ref (alist_add(alist_add(empty_alist ,'a',1), 'a', 2)->cdr, 'a', sub{'notfound'})
1
