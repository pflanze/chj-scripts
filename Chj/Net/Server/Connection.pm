# Sun Sep 23 14:49:38 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Server::Connection

=head1 SYNOPSIS

=head1 DESCRIPTION

A connection inside the server (a connection from a client.? 'usually' whatever)

=cut


package Chj::Net::Server::Connection;

use strict;

use Class::Array -fields=>
  -publica=>
  'server', # Chj::Net::Server parent object. should I call it just 'parent'? well could have multiple. ancestors. xy. dynamic. ones.
  'socket', # client(orwhatever) connection.
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Server,Socket])=@_;
    $s->init;
    $s
}


end Class::Array;
