#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Linux::numcpus

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Linux::numcpus;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(numcpus);
@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::xopen 'xopen_read';

our $numcpus;
sub numcpus {
    $numcpus ||= do {
	my $f= xopen_read "/proc/cpuinfo";
	my $n=0;
	while (<$f>) {
	    $n++ if /^processor\s*:/;
	}
	$f->xclose;
	$n > 0 or die "can't find processor lines in /proc/cpuinfo";
	$n
    }
}

1
