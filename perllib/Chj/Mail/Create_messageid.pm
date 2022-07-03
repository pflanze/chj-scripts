#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Create_messageid

=head1 SYNOPSIS

 use Chj::Mail::Create_messageid;
 Create_messageid ( "fromaddressorheader_or_returnpath" ) # -> '<random@domain.x.y>'

=head1 DESCRIPTION

(originally taken from send_as_mail)

=cut


package Chj::Mail::Create_messageid;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Create_messageid);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;


use Chj::Random::Formatted 'random_hex_string';

sub Create_messageid ( $ ) {
    my ($from_or_returnpath)=@_;
    my $s= $from_or_returnpath;
    $s=~ s/^.*\@//s;
    $s=~ s/>.*//s;
    "<".random_hex_string(16).'@'.$s.">"
}

1
