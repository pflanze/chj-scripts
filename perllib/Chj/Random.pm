# Fri Mar  3 18:03:31 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Random

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Random;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(seed);

use strict;
use Carp ;

our $randev= "/dev/urandom";
sub seed {
    @_==1 or croak "expecting 1 argument";
    my ($length)=@_;
    defined $length or die "undefined length given";#!!!!! @_ alone isn't enough. and perl doesn't croak upon type errors.
    open my $in, "<", $randev
      or croak "could not open '$randev' for reading: $!";
    my $seed;
    my $len = sysread ($in,$seed,$length);
    if (! defined $len) {
	croak "could not read from '$randev': $!"; ##  eagain und so  ?
    }
    if (! $len) {
	croak "got eof from '$randev', how can this happen?";## signal interrupts?
    }
    if ($len == $length) {
	close $in
	  or die "error closing '$randev': $!";
	$seed
    } else {
	croak "couldn't read $length bytes from '$randev', got only $len";
	# NOTE: this can happen with /dev/random (not urandom) on a 2.6.27.10{-grsec?} kernel, when the pool seems to be depleted, then it will only give what it has, funny :)
    }
}


1
