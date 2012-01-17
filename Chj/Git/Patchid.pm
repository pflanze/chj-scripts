#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Git::Patchid

=head1 SYNOPSIS

 use Chj::Git::Patchid;
 Patchid($commitid)

 #hm bad again(?) assumes env/cwd to determine git repo

=head1 DESCRIPTION


=cut


package Chj::Git::Patchid;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub Patchid_cache_dir {
    
}

sub Patchid ( $ ) {
    
}

1
