#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Logsimple

=head1 SYNOPSIS

 use Chj::Logsimple;
 our $log= Chj::Logsimple->open_priv($path);
 # a Chj::IO::File object
 $log->x("hello");
 $log->xclose;

=head1 DESCRIPTION


=cut


package Chj::Logsimple;
@ISA="Chj::IO::File"; require Chj::IO::File;

use strict;

use Chj::xsysopen ();
#(btw y diff between empty list and nothing at all, if maybe type.)

sub open_priv {
    my $cl=shift;
    my ($path)=@_;
    my $fh= Chj::xsysopen::xsysopen_append($path, 0600);
    bless $fh, $cl
}

sub new {
    die "overridden for safety" # k?
}

sub x {
    my $s=shift;
    $s->xprint(join(" ",@_),"\n");
}


1
