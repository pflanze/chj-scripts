# Wed Sep  5 14:52:20 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Striphead

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mail::Striphead;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::Mail::SimpleHead;

use Chj::repl;

#destructive?
sub striphead ($ ) {
    local our ($head)=@_;
    for our $header (@{$head->headersArray}) {
	
    }
    repl;
}

1
