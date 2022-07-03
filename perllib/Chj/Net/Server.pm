# Sun Sep 23 13:41:50 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Server

=head1 SYNOPSIS

use IO::Socket::UNIX;
use Chj::Net::Server;

unlink $socketpath;
our $sock= IO::Socket::UNIX->new(
                                 Type=> SOCK_STREAM,
                                 Local=> $socketpath,
                                 Listen=> 10, # not a boolean, but a queue length right?.
                                 #ReuseAddr=> 1, doesn't help. thus unlink above.
                                )
  or die "new: $!";#!
our $server= Chj::Net::Server->new($sock, sub {
    my ($server)=@_;

});
$server->set_maxchildren(10); # could have been given as 3rd argument to new call.
$server->run;


=head1 DESCRIPTION

Class which is base of framework for running 'client code' in one-child-per-connection.
ah. that could be made open. well. so for now this' the runnning mode.



=cut


package Chj::Net::Server;

use strict;
use utf8;

use Class::Array -fields=>
  -publica=>
#  'socket',
  'connectionhandler',# obj with handle_connection method receiving connection socket
  'handlerclass'
  ;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Socket, Handlerclass, Maxchildren])=@_;
    $s->init;
    $s
}

sub init { # initialize internal state.(remaining variables.)
    my $s=shift;
    $$s[Ncurrentchildren]=0;
}

sub run {
    my $s=shift;
    while (my $conn= $$s[Socket]->accept) {
	my $handler= $$s[Handlerclass]->new($s,$conn);#kann eben genaugleichwie in fp  nur durch analyse durch compiler statisiert werden ? !!.(parametrisierung dieser __PACKAGE__ würde es explizit allowen, thus ohne analyse ermoeglichen.)
	$s->handle_connection($conn)
    }
}


sub err_too_many_connections {
    my $s=shift;
    my($conn)=@_; ##  eben man sollte ne conn klasse machen gell. dortdrauf dann all das wIRKLICHGEEEEERRRr.
    ç
}


#sub DESTROY {
#    my $s=shift;
#    local $@;
#    # ç rausschmeissen wenn nicht benutzt, ebenso wie sub new
#    $s->SUPER::DESTROY;
#}

end Class::Array;
