#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parallel::Job

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel::Job;

use strict;

use Chj::Struct ["id","pclosure","vals"];

sub run {
    my $s=shift;
    $s->pclosure->call(@{$s->vals})
}

sub noreturn {0}

{
    package Chj::Parallel::JobNoreturn;
    use Chj::Struct [], 'Chj::Parallel::Job';
    sub noreturn {1}
    _END_
}

_END_
