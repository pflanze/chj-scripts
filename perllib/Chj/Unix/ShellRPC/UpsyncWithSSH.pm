# Tue Oct 23 00:10:14 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::UpsyncWithSSH

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::ShellRPC::UpsyncWithSSH;

use strict;

use Chj::Unix::ShellRPC::Upsync;

use Chj::Unix::ShellRPC::SSH -extend=>
  -publica=>
  ;

unshift our @ISA, 'Chj::Unix::ShellRPC::Upsync'; # push would also be ok.right?.


end Class::Array;
