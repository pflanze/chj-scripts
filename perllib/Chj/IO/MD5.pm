#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::MD5

=head1 SYNOPSIS

 my $f= xopen_read "foo";
 print $f->Chj::IO::MD5::md5_hex,"\n";
 $f->xclose; #hoping to catch any potential errors now? SIGH..

=head1 DESCRIPTION

a mixin for Chj::IO::File and subclassed objects that simply slurp all
data from the given filehandles until EOF for the digest (at least the
methods that currently are implemented, md5, md5_hex, md5_base64).

Note: these methods don't rewind the filehandle. So they can only be
called once of course / only one can be called on one particular handle.

=cut


package Chj::IO::MD5;

use strict;

use Digest::MD5;

sub mkMd {
    my ($method)=@_;
    sub {
	my $s=shift;
	my $ctx = Digest::MD5->new;
	$ctx->addfile($s);
	$ctx->$method
    }
}

*md5 = mkMd("digest");
*md5_hex = mkMd("hexdigest");
*md5_base64 = mkMd("b64digest");

1
