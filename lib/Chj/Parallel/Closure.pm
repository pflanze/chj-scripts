#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parallel::Closure

=head1 SYNOPSIS

=head1 DESCRIPTION

see Chj::PClosure

=cut


package Chj::Parallel::Closure;

use strict;

use Chj::Struct ["procname", # string (*)
		 "env", # array
		];

# (*) even globs are not serializable by Storable.

sub call {
    my $s=shift;
    unshift @_, @{$$s{env}};
    no strict 'refs';
    goto *{$$s{procname}}{CODE}
}

_END_
