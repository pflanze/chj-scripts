#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Git::Branch

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Git::Branch;

use strict;

use Class::Array -fields=>
  -publica=>
  'selected',
  'name'
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Selected,Name])=@_;
    $s
}

sub fullname {
    my $s=shift;
    $s->name
}

sub basename {
    my $s=shift;
    my $str= $s->name;
    $str=~ s|.*/||;
    $str
}

#hm override name to stip 'remotes/' ?


end Class::Array;
