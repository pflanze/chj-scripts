#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parallel

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Parallel_for_each);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::xperlfunc;
use Chj::Linux::numcpus;

our $Parallel_n= numcpus; # number of cpus to use

use POSIX ();

sub Parallel_for_each {
    my ($vec,$proc)=@_;
    my @shifts= (0..($Parallel_n-1));
    my $len= @$vec;
    my @child= map {
	my $shift=$_;
	if (my $pid= xfork) {
	    $pid
	} else {
	    for (my $i= $shift; $i< $len; $i+= $Parallel_n) {
		&$proc($$vec[$i])
	    }
	    POSIX::_exit(0);
	}
    } @shifts;
    #my @stati= map { xwait $_ } @child;
    #or, directly,
    for (@child) { xxwaitpid $_,0 };
}


1
