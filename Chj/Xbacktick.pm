#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Xbacktick

=head1 SYNOPSIS

 use Chj::Xbacktick;
 use Chj::Chomp;
 Chomp(Xbacktick("date -R"))

 #or: Xbacktick_ref, to avoid copying the result

=head1 DESCRIPTION

ugly, ucfirst named stuff. That *does* $? checking (and using
Chj::Unix::exitcode for the exception message).

Well dunno yet how to specify non-shell thingie in the 1 argument
case. doh. todo.

But, you *can* use code refs! Since I'm using Chj::IO::Command
underneath. If that's not fun.


=head1 SEE ALSO

hmm. Chj::shellorso util orso  thingies?. Chj::xbacktick is old.

=cut


package Chj::Xbacktick;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Xbacktick_ref Xbacktick);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::IO::Command; # heh. not just ` `, because of the multi arg case.
use Carp;

sub Xbacktick_ref {
    @_>=1 or croak "expecting at least 1 argument";
    my $in= Chj::IO::Command->new_sender (@_);
    my $cntrf= $in->xcontentref;
    $in->xxfinish;
    $cntrf
}

sub Xbacktick {
    my $rf= Xbacktick_ref (@_);
    $$rf
}

1
