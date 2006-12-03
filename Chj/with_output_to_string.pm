# Sun Dec  3 19:43:19 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::with_output_to_string

=head1 SYNOPSIS

 calc> $out=""; with_stderr_to_string \$out, sub { warn "Hallo\n"; die "fun"  },1
 got exn, output so far: 'Hallo
 '
 fun at (eval 43) line 1.
 calc> $out=""; with_stderr_to_string \$out, sub { print "Hallo\n"; die "fun"  },1
 Hallo
 got exn, output so far: ''
 fun at (eval 44) line 1.
 calc> $out=""; with_output_to_string \$out, sub { warn "Hallo\n"; die "fun"  },1
 got exn, output so far: 'Hallo
 '
 fun at (eval 45) line 1.


=head1 DESCRIPTION

 with_{output,std{out,err}}_to_string(stringref, coderef [, do_printonexn? ]) -> result of coderef

Redirects stdout and/or stderr to a string while calling coderef.
(Does not result the string, but the result(s) of the coderef.
Store the stringref on the outside and dereference it to get the outputs.)

If do_printonexn is true, and with_*_to_string is exited by an
exception, a message containing the contents of $$stringref is printed
to STDERR.

=cut


package Chj::with_output_to_string;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   with_stdout_to_string
	   with_stderr_to_string
	   with_output_to_string
	  );

use strict;
use IO::Handle; # es sei denn ich will mein eignes.?

sub mk {
    my ($do_stdout,$do_stderr)=@_;
    sub ( $ $ ; $ ) {
	my ($strref,$code, $do_printonexn)=@_;
	my $out= new IO::Handle;
	open $out,">",$strref or die $!;
	my $wantarray= wantarray;
	my @res= eval {
	    local *STDOUT= $do_stdout ? $out : *STDOUT{IO};
	    local *STDERR= $do_stderr ? $out : *STDERR{IO};
	    $wantarray ? ($code->()) : (scalar $code->())
	};
	close $out or die "closing string port: $!";
	if (ref$@ or $@) {
	    my $e=$@;
	    (print STDERR "got exn, output so far: '", $$strref,"'\n"
	     or die "got exn, can't output to STDERR: $!")
	      if $do_printonexn;
	    die $e
	} else {
	    $wantarray ? @res : $res[0]
	}
    }
}

*with_stdout_to_string= mk(1,0);
*with_stderr_to_string= mk(0,1);
*with_output_to_string= mk(1,1);


*Chj::with_output_to_string= \&with_output_to_string;


1
