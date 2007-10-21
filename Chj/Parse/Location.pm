# Mon Oct 22 00:13:32 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Location

=head1 SYNOPSIS

=head1 DESCRIPTION

Should just declare the common Interface. (Fields? no, methods. how?)

  'user',
  'host',
  'port',
  'path',
  #'scheme' ? or is this already URI subclass specific?

be dynamic  see.

=cut


package Chj::Parse::Location;

use strict;

use Class::Array -fields=>
  -publica=>
#   'user',
#   'host',
#   'port',
#   'path',
#hm how to define them abstractly?  is it missing in perl?
  ;


end Class::Array;
