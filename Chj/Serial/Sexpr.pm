# Copyright 2012 by Christian Jaeger
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Serial::Sexpr

=head1 SYNOPSIS

  use Chj::Serial::Sexpr 'xprint_to_sexpr_line';

  xprint_to_sexpr_line((bless *STDOUT{IO},"Chj::IO::File"),
     ["heelo", 233.4, 0.3, "0.4", undef, {foo=> 1, bar=> 0}, *STDIN{IO}]);
  print "\n";
  # yields:
  (list "heelo" 233.4 0.3 0.4 #f (alist ("bar" . 0) ("foo" . 1)) (error "unknown kind of reference" "IO::Handle"))

=head1 DESCRIPTION


=cut


package Chj::Serial::Sexpr;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xprint_to_sexpr_line);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::schemestring 'schemestring_oneline';

# print it all to one line
sub xprint_to_sexpr_line {
    my ($out, $v)=@_;
    if (defined $v) {
	if (my $t= ref $v) {
	    if ($t eq "ARRAY") {
		$out->xprint("(list ");
		my $need_space=0;
		for my $v (@$v) {
		    if ($need_space) {
			$out->xprint(" ");
		    } else {
			$need_space=1
		    }
		    xprint_to_sexpr_line ($out, $v);
		}
		$out->xprint(")");
	    }
	    elsif ($t eq "HASH") {
		$out->xprint("(alist ");
		my $need_space=0;
		for my $k (keys %$v) {
		    if ($need_space) {
			$out->xprint(" ");
		    } else {
			$need_space=1
		    }
		    $out->xprint("(", schemestring_oneline($k), " . ");
		    xprint_to_sexpr_line ($out, $$v{$k});
		    $out->xprint(")");
		}
		$out->xprint(")");
	    }
	    else {
		$out->xprint("(error ",
			     schemestring_oneline("unknown reference type"),
			     " ",
			     schemestring_oneline($t),
			     ")");
	    }
	} else {
	    if ($v=~ /^[+-]?\d+(\.\d*(e[+-]\d+)?)?\z/s) {
		# number
		$out->xprint($v);
	    } else {
		# treat as string, OK?
		$out->xprint(schemestring_oneline ($v));
	    }
	}
    } else {
	# only way to output #f ?
	# or output #!unspecified or something?
	$out->xprint("#f");
    }
}

1
