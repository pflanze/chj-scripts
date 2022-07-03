# Fri Apr 27 13:10:49 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Maillogfilter

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::App::Maillogfilter;
@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw(map_line);
@EXPORT=qw(map_line);
#%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;

use Digest::MD5 'md5_hex';

our $MAILRE= qr/(?:\w+(?:[+.=-]\w+)?)+\@\w+(?:[.-]\w+)*/; ###  todo  real one; well the good thing is that adresses like 'ethlifedev-chrismail@[192.168.8.1]' are getting through which is perhaps what I want when looking at qmail (not qpsmtp, which are different) logs (using qm-log).


sub map_line {
    my ($line)=@_;
    $line=~ s/<($MAILRE)>/
       "<{".md5_hex($1)."}>"
    /sge;
    $line=~ s/($MAILRE)/
       "{".md5_hex($1)."}"
    /sge;
    $line
}

# can process about 36'000 lines/sec of qpsmtp logs on elvis (2ghz
# athlon) which is not very fast (the rest of the pipeline including
# zcat and tai is 10 times faster).

1
