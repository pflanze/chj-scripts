# Sun Dec  3 19:43:19 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::with_output_to_string

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::with_output_to_string;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(with_output_to_string);

use strict;
use IO::Handle; # es sei denn ich will mein eignes.?

sub with_output_to_string ( $ $ ; $ ) {
    my ($strref,$code, $do_printonexn)=@_;
    my $out= new IO::Handle;
    open $out,">",$strref or die $!;
    my $wantarray= wantarray;
    my @res= eval {
	local *STDOUT= $out;
	$wantarray ? ($code->()) : (scalar $code->())
    };
    close $out or die "closing string port: $!";
    if (ref$@ or $@) {
	my $e=$@;
	#print STDOUT "output so far: '", $$strref,"'\n"
	#  or die "can't output str buffer to old STDOUT?: $!";
	#hm. wofür genau.
	(print STDERR "got exn, output so far: '", $$strref,"'\n"
	 or die "got exn, can't output to STDERR: $!")
	  if $do_printonexn;
	die $e
    } else {
	$wantarray ? @res : $res[0]
    }
}

*Chj::with_output_to_string= \&with_output_to_string;


1
