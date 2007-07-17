# Mon Jun  6 18:22:26 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Term::settitle

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Term::settitle;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(settitle);

use strict;

sub settitle {
    my ($title,$fh)=@_;
    $fh||=*STDOUT{IO};
    my $oldfh= select;
    select $fh;
    {
	local $|=1;
	print "\033]2;$title\007";
    }
    select $oldfh;
}


1
