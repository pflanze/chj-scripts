# Sat Mar 31 21:44:28 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Squirrelmailabook::Entry

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Squirrelmailabook::Entry;

use strict;

use Class::Array -fields=>
  -publica=>
  'username',
  'firstname',
  'lastname',
  'email',
  'comments'
  ;

sub new_from_line {
    my $s=shift;

}



end Class::Array;
