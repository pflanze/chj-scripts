# Sun Oct 21 00:16:15 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xsocketpair

=head1 SYNOPSIS

=head1 DESCRIPTION

Returns two Chj::IO::Socketpair filehandles/objects.

=head1 NOTE

You should trap SIGPIPE or the program will exit before an exception
is thrown.(right?)

=head1 SEE ALSO

L<Chj::IO::Socketpair>, L<Chj::IO::File>

=cut


package Chj::xsocketpair;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(xsocketpair);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::IO::Socketpair;
#use POSIX (); ehr no, 'socketpair' is in perl core!! which is kinda cool of course (should work on win right?)
use Socket;
use Carp;

sub xsocketpair {
    my ($maybe_domain,
	$maybe_type,
	$maybe_protocol)=@_;
    my $domain= defined($maybe_domain) ? $maybe_domain : PF_UNIX;
    my $type= defined($maybe_type) ? $maybe_type : SOCK_STREAM;
    my $protocol= defined($maybe_protocol) ? $maybe_protocol : 0; # it warns on undef, so really have to choose the 0.
    my @p= map { new Chj::IO::Socketpair } (1..2);
    socketpair($p[0], $p[1], $domain,$type,$protocol)
	or croak "xsocketpair($domain,$type,$protocol): $!"; # well really out put the choosen values intead of the passed ones?
    @p  # check for wantarray and die if not ?
}


*Chj::xsocketpair= \&xsocketpair;

1
