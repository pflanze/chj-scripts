# Sun Sep 23 15:03:11 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Server::ConnectionHandler

=head1 SYNOPSIS

=head1 DESCRIPTION

Handles a connection

=cut


package Chj::Net::Server::ConnectionHandler;

use strict;
use Chj::xperlfunc ();

use Class::Array -fields=>
  -publica=>
  'connectionclass',
  'maxchildren',
  # internal running state:
  'ncurrentchildren',
  ;


# sub new {
#     my $class=shift;
#     my $s= $class->SUPER::new;
#     (@$s[])=@_;
#     $s
# }

sub handle_connection {
    my $s=shift;
    my ($conn)=@_;
    if my 
}



#sub DESTROY {
#    my $s=shift;
#    local $@;
#    # ç rausschmeissen wenn nicht benutzt, ebenso wie sub new
#    $s->SUPER::DESTROY;
#}

end Class::Array;
