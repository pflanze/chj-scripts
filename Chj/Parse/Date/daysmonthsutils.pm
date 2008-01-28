# Thu Dec 20 07:42:58 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::daysmonthsutils

=head1 SYNOPSIS

=head1 DESCRIPTION

Helper function list_of_arrays_to_hash__with_startidx to create (big)
hash tables with string -> number mappings. It expects one to many
arrays, whose items it lowercases and additionally
decimal-point-removes and then with the corresponding index in that
array, put into the table. Multiple key occurrences are no problem
(not fatal) as long as they all use the same value.

=cut


package Chj::Parse::Date::daysmonthsutils;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(list_of_arrays_to_hash__with_startidx);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub list_of_arrays_to_hash__with_startidx {
    my ($startidx)=@_; # probably 0 or 1
    sub {
	my @arrays=@_;
	my $h={};
	my $xAdd= sub {
	    my ($key,$val)=@_;
	    $key=lc $key;
	    if (exists $$h{$key}) {
		if ($$h{$key} == $val) {
		    #ok
		} else {
		    die "key conflict on '$key'"
		}
	    } else {
		$$h{$key}=$val;
	    }
	};
	for my $ary (@arrays) {
	    my $i=$startidx;
	    for my $dayname (@$ary) {
		&$xAdd ($dayname,$i);
		$dayname=~ s/\.//sg and &$xAdd ($dayname,$i);
		$i++
	    }
	}
	$h
    }
}

1
