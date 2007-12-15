# Sun Oct 21 17:54:10 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::CommandBidirectional

=head1 SYNOPSIS

 use Chj::IO::CommandBidirectional;
 # don't forget to maybe set up a sigpipe handler
 my $ssh= Chj::IO::CommandBidirectional->new_inout("ssh",$host,"bash");
 $ssh->xprint("echo hello\n"); $ssh->xflush;
 print scalar $ssh->xreadline;

=head1 DESCRIPTION

=head1 SEE ALSO

L<Chj::IO::Command>, L<Chj::IO::CommandCommon>, L<Chj::IO::Socketpair>

=cut


package Chj::IO::CommandBidirectional;

use strict;

use base qw(
	    Chj::IO::CommandCommon
	    Chj::IO::Socketpair
	    );

use Chj::xsocketpair ();

sub new_inout {
    my $class=shift;
    my ($self,$other)= Chj::xsocketpair();
    bless $self, $class;
    $self->xlaunch3($other,$other,undef, @_)
}

1
