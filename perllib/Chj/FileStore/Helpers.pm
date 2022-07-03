#
# Copyright 2004-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FileStore::Helpers

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FileStore::Helpers;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(_escape_key
	   _unescape
	   _escape_val
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use utf8; use warnings FATAL => 'uninitialized';

###ps. lame copy  PIndex.pm <-> MIndex.pm
sub _escape_key {
    #my $self=shift;
    my ($str)=@_;
    #$str=~ s/\%/\\\%/sg;
    $str=~ s|\%|\%25|sg;
    $str=~ s|/|\%2f|sg;
    $str=~ s|\0|\%00|sg;
    $str=~ s|\n|\%0a|sg;# weil sonst perl warnings gibt bei exists etc 'unsuccessful stat on filename with newline' auch wenn nicht am ende.
    "=".$str
}

sub _escape_val {
    my ($str)=@_;
    $str=~ s|\%|\%25|sg;
    $str=~ s|\0|\%00|sg;# ich könnte hier auch s|\0|\\0|sg machen weil eine normalanerkannte solche escape besteht die dann umgewandelt wird; bei / isch das andersch, gibt es keine allganerk escape die den / nicht enthaelt. daher escape_key andersch noetig
    $str=~ s|/|\%2f|sg;# nun auch nötig
    #$str=~ s|,|\%2c|sg;#das trennzeichen nein.
    $str=~ s|\n|\%0a|sg;# weil sonst perl warnings gibt bei exists etc 'unsuccessful stat on filename with newline' auch wenn nicht am ende.
    "=".$str
}


sub _unescape { ##todo should that die if receiving something not starting with a = ?
    my ($str)=@_;
    $str=~ s|\%0a|\n|sg;
    $str=~ s|\%00|\0|sg;
    $str=~ s|\%2f|/|sg;
    $str=~ s|\%25|\%|sg;
    #$str=~ s|\%2c|,|sg;
    substr($str,1)
}


1
