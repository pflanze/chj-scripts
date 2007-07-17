# Mon Aug 29 19:57:55 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::reallysleep

=head1 SYNOPSIS

 use Chj::reallysleep;
 reallysleep 1;

=head1 DESCRIPTION

Really sleeps the given number of (fractional) seconds even if timer
interrupts etc. are interrupting normal sleep.

=cut


package Chj::reallysleep;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(reallysleep);

use strict;

use Time::HiRes ('sleep','time');

our $DEBUG;

sub reallysleep( $ ) {
    my ($seconds)=@_;
    die "reallysleep: invalid argument '$seconds'" unless $seconds >= 0;
    my $start= time;
    my $end= $start + $seconds;
    my $t= $start;
  DO: {
	sleep $end - $t;
	$t=time;
	if ($t < $end) {
	    warn "reallysleep: not reached end, $t < $end, so redo" if $DEBUG;
	    redo DO;
	}
    }
}

*Chj::reallysleep= \&reallysleep;

1
