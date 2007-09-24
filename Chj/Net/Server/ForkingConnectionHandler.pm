# Sun Sep 23 17:55:30 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Server::ForkingConnectionHandler

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Net::Server::ForkingConnectionHandler;

use strict;

use Chj::Net::Server::ConnectionHandlerBase -extend=>
  -publica=>
  'maxchildren',
  # internal running state:
  'ncurrentchildren',
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new(shift);
    (@$s[Maxchildren])=@_;
    $s
}


sub handle_connection {
    my $s=shift;
    my ($conn)=@_;
    # the 'default' fork based implementation.
    if ($$s[Ncurrentchildren] < $$s[Maxchildren]) {
	if (my $pid= xfork) {
	    $$s[Ncurrentchildren]++;
	} else {
	    my $res= $s->call_handler($conn);  # DIES offeriert den override per methode, statt callback coderef.lusha
	    exit($res); ## requires a status code so. but ye ok ~~. oldunsix.
	}
    } else {
	# hm how to handle this. exception?.die. error code.  call. send sth over the net ?. what.
	$s->err_too_many_connections($conn)  #can still throw error e.g. if not exists.
    }
}


end Class::Array;
