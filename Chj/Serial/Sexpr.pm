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
  # => (list "heelo" 233.4 0.3 0.4 #f (alist ("bar" . 0) ("foo" . 1)) (error "unknown kind of reference" "IO::Handle"))

  # or use xprint_to_sexpr_line_with_sharing for data structures with
  # repeated references (or cycles):
  my $ones= [ 1, undef]; $$ones[1]=$ones;
  xprint_to_sexpr_line_with_sharing ((bless *STDOUT{IO},"Chj::IO::File"), $ones); print "\n";
  # => (named 1 (list 1 (ref 1)))


=head1 DESCRIPTION


=cut


package Chj::Serial::Sexpr;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xprint_to_sexpr_line
	      xprint_to_sexpr_line_with_sharing);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub valid_keyword_or_symbol {
    my ($str)=@_;
    # what goes without escaping for Scheme
    $str=~ /^[_a-zA-Z-][\w+-]*\z/
}

sub keyword_or_symbol_to_printstring {
    my ($str)=@_;
    if (valid_keyword_or_symbol $str) {
	$str
    } else {
	$str=~ s/\\/\\\\/g;
	$str=~ s/\|/\\|/g;
	$str=~ s/\n/\\n/g;
	$str=~ s/\r/\\r/g;
	$str=~ s/\t/\\t/g;
	# and more, hum. wll. XXXsafety?
	'|'.$str.'|'
    }
}

sub dispatch {
    my ($v,
	$do_array, $do_hash, $do_object, $do_number, $do_string, $do_undef,
	$do_type_error)= @_;
    if (defined $v) {
	if (my $t= ref $v) {
	    if ($t eq "ARRAY") {
		&$do_array
	    }
	    elsif ($t eq "HASH") {
		&$do_hash
	    }
	    else {
		if (UNIVERSAL::isa($v, "HASH")
		    and
		    my $m= UNIVERSAL::can($v, "_serialize_classname")) {
		    my $classname= &$m($v);
		    &$do_object($classname);
		} else {
		    &$do_type_error($t)
		}
	    }
	} else {
	    if ($v=~ /^[+-]?\d+(\.\d*(e[+-]\d+)?)?\z/s) {
		&$do_number
	    } else {
		# treat as string, OK?
		&$do_string;
	    }
	}
    } else {
	&$do_undef
    }
}

use Chj::schemestring 'schemestring_oneline';

sub refcounts {
    my ($v)=@_;
    my $refcounts={};
    my $add= sub {
	my ($add, $v)=@_;
	my $addv= sub {
	    #$$refcounts{$v}++;
	    my $oldcount= $$refcounts{$v};
	    $$refcounts{$v}++;
	    $oldcount
	      #wow that makes it work. WTH Perl.
	};
	my $HASH= sub {
	    if (not &$addv) {
		for my $k (keys %$v) {
		    &$add ($add, $$v{$k});
		}
	    }
	};
	dispatch
	  ($v,
	   sub {
	       # ARRAY
	       if (not &$addv) {
		   for my $v (@$v) {
		       &$add ($add, $v);
		   }
	       }
	   },
	   $HASH, # HASH
	   $HASH, # hash based objects with _serialize_classname method
	   sub {
	       # number
	   }, sub {
	       # string or similar
	   }, sub {
	       # undef
	   }, sub {
	       # unknown
	   });
    };
    &$add ($add, $v);
    # strip those that have count 1?
    for my $k (keys %$refcounts) {
	delete $$refcounts{$k} if $$refcounts{$k}==1;
    }
    $refcounts
}


# print it all to one line

sub xprint_to_sexpr_line {
    my ($out, $v)=@_;
    xprint_to_sexpr_line_ ($out,$v, undef);
}

sub xprint_to_sexpr_line_with_sharing {
    my ($out, $v)=@_;
    xprint_to_sexpr_line_ ($out,$v, refcounts($v));
}

sub xprint_to_sexpr_line_ {
    my ($out, $v, $maybe_share)=@_;
    my $named={};
    my $new_name= do {
	my $i=1;
	sub {
	    ($i++)
	}
    };

    my $rec= sub {
	my ($rec, $v)=@_;
	my $printv= sub {
	    dispatch $v, sub {
		# ARRAY
		$out->xprint("(list");
		for my $v (@$v) {
		    $out->xprint(" ");
		    &$rec ($rec, $v);
		}
		$out->xprint(")");
	    }, sub {
		# HASH
		$out->xprint("(table");
		for my $k (sort keys %$v) {
		    $out->xprint(" ");
		    $out->xprint("(item ", schemestring_oneline($k), " ");
		    &$rec ($rec, $$v{$k});
		    $out->xprint(")");
		}
		$out->xprint(")");
	    }, sub {
		# hash based objects with _serialize_classname method
		my ($classname)=@_;
		$out->xprint("(object '$classname");
		for my $k (sort keys %$v) {
		    $out->xprint(" ");
		    $out->xprint(keyword_or_symbol_to_printstring($k),": ");
		    &$rec ($rec, $$v{$k});
		}
		$out->xprint(")");
	    }, sub {
		# number
		$out->xprint($v);
	    }, sub {
		# string or similar
		$out->xprint(schemestring_oneline ($v));
	    }, sub {
		# undef
		# (The only way to output #f ? or output #!unspecified or something?)
		$out->xprint("#f");
	    }, sub {
		my ($t)=@_;
		$out->xprint("(error ",
			     schemestring_oneline("unknown reference type"),
			     " ",
			     schemestring_oneline($t),
			     ")");
	    };
	};

	if (ref $v and $maybe_share and $$maybe_share{$v}) {
	    if (my $name= $$named{$v}) {
		$out->xprint ("(ref ", $name, ")");
	    } else {
		my $name= &$new_name;
		$$named{$v}= $name;
		$out->xprint ("(named ", $name, " ");
		&$printv;
		$out->xprint (")");
	    }
	} else {
	    &$printv
	}
    };
    &$rec ($rec, $v);
}

1
