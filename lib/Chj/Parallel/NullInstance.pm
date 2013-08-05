#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parallel::NullInstance

=head1 SYNOPSIS

=head1 DESCRIPTION

pseudo Instance to use instead of Chj::Parallel::Instance if the
concurrency value is 1, that runs everything in the same process.

=cut


package Chj::Parallel::NullInstance;

use strict;

use Chj::FP2::Stream ();
use Scalar::Util 'weaken';

use Chj::Struct [
		];


sub stream_for_each {
    my $self=shift;
    #warn "NullInstance";
    @_==3 or @_==2 or die;
    my ($pclosure, $s, $maybe_batchsize)=@_;
    weaken $_[1];
    @_=(sub {
	    $pclosure->call(@_)
	},
	$s);
    goto (\&Chj::FP2::Stream::stream_for_each)
}


_END_
