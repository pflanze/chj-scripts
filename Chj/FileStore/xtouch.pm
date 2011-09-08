#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::xtouch

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FileStore::xtouch;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xtouch);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::FileStore::Stamp;

sub xtouch ( $ ) {
    my ($path)=@_;
    Chj::FileStore::Stamp->new($path)->xtouch
}


1
