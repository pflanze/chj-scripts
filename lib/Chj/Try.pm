#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Try

=head1 SYNOPSIS

 use Chj::Try;
 Try {
    warn("hello");
    die "bar";
    warn("baz");
 } "foo"; # "foo" could be an object with an 'identify' method
 warn "done";

 #=>
 # WARN['foo']: hello
 # ERROR['foo']: bar
 # done

 Try {
    die bless [], "MyExn"
 } "foo",
   [["MyExn"=> sub {"ok"}]];
 #=> "ok"

=head1 DESCRIPTION


=cut


package Chj::Try;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Try);
@EXPORT_OK=qw(IfTryScalar
	      standard_warn);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Carp;

use Chj::TEST;
use Data::Dumper;

# Try.pm localizes $SIG{__WARN__} to change the effect of 'warn'
# statements.

# The default implementation of what 'warn' does, i.e. if
# $SIG{__WARN__} is not set, needs to still be available to whatever
# is being put into $SIG{__WARN__} if one just wishes to extend the
# default implementation (and not reimplement from scratch). The clean
# way for Perl to offer that default implementation might have been to
# actually put it in $SIG{__WARN__} on startup, then it could have
# been taken from there before local'izing. Since that's not the case,
# and the author of this module doesn't know of any way to access this
# default implementation [*], it is (hopefully completely)
# reimplemented here:

# [*] note that calling 'warn' from within the $SIG{__WARN__} handler
# might lead to endless recursion, also, there's no way to get a
# reference to warn (\&warn won't work because it's not a subroutine)
# so that it could be tail called to avoid wrong location reporting,
# and Carp::carp does add needless second location string to its
# output (perhaps only in this case because it's exactly recursing
# (dunno why just once)).

sub standard_warn {
    my ($package, $filename, $line) = caller;
    if (@_) {
	if ($_[-1]=~ /\n\z/) {
	    print STDERR @_;
	} else {
	    print STDERR @_," at $filename line $line\n";
	}
    } else {
	print STDERR "Warning: something's wrong at $filename line $line\n";
    }
}

sub default_warn {
    my $first= $_[0];
    if (defined $first and ref ($first) eq "KIND") {
	my $kind= $$first;
	shift;
	@_=("${kind}: ", @_); goto \&standard_warn;
    } else {
	goto \&standard_warn;
    }
}

$SIG{__WARN__} ||= \&default_warn;

sub ctx2str {
    my ($ctx)=@_;
    if (my $identify= UNIVERSAL::can($ctx,"identify")) {
	&$identify($ctx)
    } else {
	my $str= Dumper($ctx);
	$str=~ s/^\$VAR1 = //;
	$str=~ s/;\n\z//s;
	$str
    }
}

sub IfTryScalar {
    my ($thunk,$ctx,$success,$fail,$maybe_catch_map)=@_;
    my $ctxstr;
    my $res;
    if (eval {
	no warnings 'redefine';
	my $prev_warn= do {
	    if (my $w= $SIG{__WARN__}) {
		if (UNIVERSAL::isa($w,"Chj::Try_handler")) {
		    # don't stack those on top of each other, instead:
		    \&standard_warn
		} else {
		    $w
		}
	    } else {
		\&standard_warn
	    }
	};
	local $SIG{__WARN__}= bless sub {
	    $ctxstr||= ctx2str ($ctx);
	    my $first= $_[0];
	    my ($kind,@rest)=
	      ((defined $first and ref ($first) eq "KIND")
	       ? ($$first, @_[1..$#_])
	       : ("__WARN__", @_));
	    @_=( "${kind}[$ctxstr]: ",@rest );
	    goto $prev_warn;
	}, "Chj::Try_handler";
	$res= &$thunk;
	1
    }) {
	@_=($res); goto $success
    } else {
	my $e=$@;
	if ($maybe_catch_map and ref $e) {
	    for (@$maybe_catch_map) {
		my ($class,$handler)=@$_;
		if (UNIVERSAL::isa($e,$class)) {
		    @_=($e); goto $handler
		}
	    }
	}
	$ctxstr||= ctx2str ($ctx);
	carp "ERROR[$ctxstr]: $e";
	@_=(); goto $fail
    }
}

sub noop {
    ()
}

sub Try (&$;$) {
    my ($thunk,$ctx,$maybe_catch_map)=@_;
    my $wantarray= wantarray;
    if (defined $wantarray) {
	IfTryScalar
	  (sub {
	       $wantarray ? [&$thunk] : scalar &$thunk
	   },
	   $ctx,
	   sub {
	       my ($a)=@_;
	       $wantarray ? @$a : $a
	   },
	   \&noop,
	   $maybe_catch_map)
    } else {
	IfTryScalar
	  ($thunk,
	   $ctx,
	   \&noop,
	   \&noop,
	   $maybe_catch_map)
    }
}

TEST {
    my @foo=(1,3,4);
    [Try { @foo } "foo"]
}
  [1,3,4];

TEST {
    my @foo=(1,3,4);
    Try { @foo } "foo"
}
  3;

TEST {
    Try {
	die bless [], "Chj::Try::MyExn"
    } "foo",
      [["Chj::Try::MyExn"=> sub {"ok"}]];
}
  "ok";

TEST {
    local @Chj::Try::MyExn::ISA= ();
    local @Chj::Try::MySubExn::ISA= ("Chj::Try::MyExn");
    Try {
	die bless [], "Chj::Try::MySubExn"
    } "foo",
      [["Chj::Try::MyExn"=> sub {"ok"}]];
}
  "ok";

TEST {
    local @Chj::Try::OtherExn::ISA= ();
    local @Chj::Try::MySubExn::ISA= ("Chj::Try::OtherExn");
    Try {
	die bless [], "Chj::Try::MySubExn"
    } "foo",
      [["Chj::Try::MyExn"=> sub {"ok"}]];
}
  undef;

TEST {
    local @Chj::Try::MyExn::ISA= ();
    local @Chj::Try::OtherExn::ISA= ();
    local @Chj::Try::Sub1Exn::ISA= ("Chj::Try::OtherExn");
    local @Chj::Try::Sub2Exn::ISA= ("Chj::Try::MyExn");
    Try {
	die bless [], "Chj::Try::Sub1Exn"
    } "foo",
      [["Chj::Try::MyExn"=> sub {"My"}],
       ["Chj::Try::OtherExn"=> sub {"Other"}],
       ["Chj::Try::Sub1Exn"=> sub {"precise"}]];
}
  "Other";


1
