# Sun Oct 21 00:13:52 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::Socketpair

=head1 SYNOPSIS

=head1 DESCRIPTION

Inherits from Chj::IO::File.

=cut


package Chj::IO::Socketpair;
@ISA= "Chj::IO::File";
require Chj::IO::File;

use strict;

sub quotedname {
    "socketpair"
}

1
