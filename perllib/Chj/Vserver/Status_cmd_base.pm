# Mon Nov  1 22:34:24 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vserver::Status_cmd_base

=head1 SYNOPSIS

=head1 DESCRIPTION

base class with code for all external calls of the vserver
command. (which is a shell script btw)

=cut


package Chj::Vserver::Status_cmd_base;
use strict;
use Chj::IO::Command;
use Carp;

use Class::Array -fields=>
  'cmddata',
  'cmdexitcode',
  ;
end Class::Array;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    confess unless @_==2;
    my ($name,$commando)=@_;
    my $cmd= Chj::IO::Command->new_combinedsender("vserver",$name,$commando);
    $$s[Cmddata]= $cmd->xcontent;
    $$s[Cmdexitcode]= $cmd->xfinish;
    $s
}


1;
