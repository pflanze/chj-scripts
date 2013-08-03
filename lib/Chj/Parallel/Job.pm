#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

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
