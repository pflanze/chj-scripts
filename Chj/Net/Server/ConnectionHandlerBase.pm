# Sun Sep 23 17:53:13 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Server::ConnectionHandlerBase

=head1 SYNOPSIS

=head1 DESCRIPTION

Must be completed with a handle_connection method.

=cut


package Chj::Net::Server::ConnectionHandlerBase;

use strict;

use Class::Array -fields=>
  -publica=>
  #'connectionclass', # parent. ? nope?
  'handler', # object/class with handle_connection method
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Handler])=@_;
    $s
}

end Class::Array;
