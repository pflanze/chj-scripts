#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::MIME::EncWords

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::MIME::EncWords;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(decode_mimewords encode_mimewords);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use MIME::EncWords ();
use utf8;
use Chj::TEST;

sub decode_mimewords ($) {
    my $str= MIME::EncWords::decode_mimewords ($_[0]);
    utf8::decode $str;
    $str
}

*encode_mimewords= *MIME::EncWords::encode_mimewords;

TEST{ decode_mimewords '=?UTF-8?Q?Jean-Fran=C3=A7ois_Mongrain?=' }
  "Jean-François Mongrain";
TEST{ decode_mimewords '=?ISO-8859-1?Q?Jean-Fran=E7ois?= Mongrain' }
  "Jean-François Mongrain";

1
