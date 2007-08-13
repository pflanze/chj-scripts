# Mon Aug 13 18:49:35 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Encode::Imap

=head1 SYNOPSIS

=head1 DESCRIPTION

Modified utf-7 encoding as used by IMAP servers like (courier and) dovecot.

=head1 NOTES

The dot "." is not converted, neither is "/".

Thunderbird, when entering a subfolder name with a dot, leads to the
actual creation of nested folders. When entering a subfolder with "/"
in the name, that is converted to a "." and then behaves the
same. When entering a subfolder with multiple dots (and/or slashes),
it is silently ignored.

So be sure to convert slashes (and dots) yourself before using the
result in filesystem paths!

=cut

# (Test suite in work:test-cj-encode-imap.scm!)

package Chj::Encode::Imap;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(encode_imap decode_imap);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Encode;


sub encode_imap {
    my ($str)=@_;
    my $s= encode "utf-7",$str;
    # escape the not-yet escaped escape char &:
    $s=~ s/\&/\&-/sg;
    # revert escaping of the escape char +, and change it if it's used as escape char:
    $s=~ s/\+(.?)/
        $1 ? (($1 eq "-") ? "+" : "&".$1) : "+" #hm the latter can't happen, right?
    /seg;
    $s
}

sub decode_imap {
    my ($str)=@_;
    # artificially escape the utf-7 escape char to avoid problems:
    $str=~ s/\+/+-/sg;
    # turn around &:
    $str=~ s/\&(.?)/
       $1 ? (($1 eq "-") ? "&" : "+".$1) : "+"
    /seg;
    decode "utf-7",$str
}


1
