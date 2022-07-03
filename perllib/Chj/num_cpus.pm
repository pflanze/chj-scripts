# Sun May 11 16:12:08 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::num_cpus

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::num_cpus;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(num_cpus);
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub num_cpus {
    my $n= eval {
	require Linux::Cpuinfo;
	Linux::Cpuinfo->new->num_cpus
    };
    if (ref $@ or $@) {
	my $e="$@"; chomp $e;
	warn "WARNING: could not test for the number of cpus ($e)";
	0 ##hm ugly?. or nice?
    } else {
	$n
    }
}

1

