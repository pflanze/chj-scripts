#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::ArrayLib

=head1 SYNOPSIS

 use Chj::FP::ArrayLib ':all';
 array_fold sub {my ($v,$r)=@_; $v+$r }, 0, [5,6,7]
 #-> 18
 use Chj::FP::List;
 (array_fold \&cons, $Chj::FP::EmptyList, [5,6,7])->string
 #-> (7 6 5)

=head1 DESCRIPTION

Functions for arrays.

=cut


package Chj::FP::ArrayLib;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(array_fold
	      array_uniq
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# a fold-left
sub array_fold ( $ $ $ ) {
    my ($fn,$res,$ary)= @_;
    for my $v (@$ary) {
	$res= &$fn($v,$res);
    }
    $res
}

sub array_uniq ( $ $ ) {
    my ($ary,$eq)=@_;
    return [] unless @$ary;
    my $v= $$ary[0];
    my $res= [$v];
    for (my $i=1; $i < @$ary; $i++) {
	my $v2= $$ary[$i];
	if (not &$eq ($v,$v2)) {
	    $v= $v2;
	    push @$res, $v;
	}
    }
    $res
}

1

__END__
TEST
calc> :l array_fold sub {my ($v,$r)=@_; $v+$r }, 0, [5,6,7]
18
calc> :l (array_fold \&cons, $Chj::FP::EmptyList, [5,6,7])->string
(7 6 5)

calc> :d array_uniq [ 1,2,3,3,4,6,9,9 ], \&number_eq
$VAR1 = [
          1,
          2,
          3,
          4,
          6,
          9
        ];
calc> :d array_uniq [ 3,3,4,6,9,9 ], \&number_eq
$VAR1 = [
          3,
          4,
          6,
          9
        ];
calc> :d array_uniq [ 3,3,9,9 ], \&number_eq
$VAR1 = [
          3,
          9
        ];
calc> :d array_uniq [ 3,3,3 ], \&number_eq
$VAR1 = [
          3
        ];
calc> :d array_uniq [ ], \&number_eq
$VAR1 = [];
