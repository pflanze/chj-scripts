# Sat Feb 26 13:57:54 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Scalar::Util - weaken/isweak and other functions

=head1 SYNOPSIS

=head1 DESCRIPTION

Provide most of the functions from Scalar::Util, in particular the
weaken/isweak functions, using Scalar::Util if possible, otherwise using
WeakRef if possible and providing alternative implementations if possible.

It doesn't export function that couldn't be defined.

The reason for this is just that my perl stuff works with both perl 5.6.x
(with or without additional modules installed) and perl 5.8.x (which
has Scalar::Util by default: debian sarge has it in perl-base).

=cut


package Chj::Scalar::Util;
@ISA="Exporter"; require Exporter;

my @weakstuff=qw(weaken isweak);
my @pureperl=
  qw(openhandle blessed refaddr reftype tainted readonly looks_like_number);
my %pureperl= map { $_=>1 } @pureperl;
my @from_real_scalar_util= qw(dualvar isvstring set_prototype);

my @what_real_scalar_util_might_have = (@weakstuff,@pureperl,@from_real_scalar_util);
# ^- Version 1.13 (sarge) has all this, version 1.06 (woody) not.

#@EXPORT_OK=();
#*EXPORT_OK=[];
#ah:
#BEGIN{
    #@EXPORT_OK=();
    #*EXPORT_OK=[];
    # öh ??
#}
use vars '@EXPORT_OK', '$DEBUG';

#$DEBUG=1;#(allein hilft das auch nicht zur deklaration.)
$DEBUG=0;

use strict;

eval {
    # try the "real thing"
    require Scalar::Util;
    #import Scalar::Util @what_real_scalar_util_might_have;
    #@EXPORT_OK=@what_real_scalar_util_might_have;
    # nope, only import what's available:
    # (and the rest?  ??)
    my $scalarutil_has= {
			 map {
			     $_ => 1
			 } @Scalar::Util::EXPORT_OK
			};
    my @missing_perldefinable;
    for my $what (@what_real_scalar_util_might_have) {
	if ($scalarutil_has->{$what}) {
	    import Scalar::Util $what;
	    push @EXPORT_OK,$what;
	    warn "using '$what' from Scalar::Util" if $DEBUG;
	} else {
	    warn "Scalar::Util doesn't have '$what'" if $DEBUG;
	    push @missing_perldefinable,$what if $pureperl{$what};
	}
    }
    if (@missing_perldefinable) {
	define_pureperl(@missing_perldefinable);
    }
};
if (ref$@ or $@) {
    if($DEBUG) {
	warn __PACKAGE__.": trying to load Scalar::Util: $@";
    }
    # provide alternatives:
    eval {
	require WeakRef;
	import WeakRef @weakstuff;
	push @EXPORT_OK,@weakstuff;
    };
    if(ref$@ or $@ and $DEBUG) {
	warn __PACKAGE__.": trying to load WeakRef.pm: $@";
    }
    define_pureperl(@pureperl);
}


sub define_pureperl {
    my(@which)=@_;
    my %needed= map { $_=>1 } @which;
    
    # ---- copied from Scalar::Util (@EXPORT_FAIL line removed, and changed for conditional definitions) ----
    eval <<'ESQ';

# The code beyond here is only used if the XS is not installed
    
    if ($needed{blessed} or $needed{reftype}) {
	# Hope nobody defines a sub by this name
	eval 'sub UNIVERSAL::a_sub_not_likely_to_be_here { ref($_[0]) }'; die if $@;
    }
    
    if ($needed{blessed}) {
	eval '
	       sub blessed ($) {
		   local($@, $SIG{__DIE__}, $SIG{__WARN__});
		   length(ref($_[0]))
		     ? eval { $_[0]->a_sub_not_likely_to_be_here }
		       : undef;
	       }
        ';
        die if $@;
    }

    if ($needed{refaddr}) {
	eval <<'END';
 	    sub refaddr($) {
		my $pkg = ref($_[0]) or return undef;
		bless $_[0], 'Scalar::Util::Fake';
		my $i = int($_[0]);
		bless $_[0], $pkg;
		$i;
	    }
END
        die if $@;
    }

    if ($needed{reftype}) {
        eval <<'END';
	    sub reftype ($) {
	      local($@, $SIG{__DIE__}, $SIG{__WARN__});
	      my $r = shift;
	      my $t;

	      length($t = ref($r)) or return undef;

	      # This eval will fail if the reference is not blessed
	      eval { $r->a_sub_not_likely_to_be_here; 1 }
		? do {
		  $t = eval {
		      # we have a GLOB or an IO. Stringify a GLOB gives it's name
		      my $q = *$r;
		      $q =~ /^\*/ ? "GLOB" : "IO";
		    }
		    or do {
		      # OK, if we don't have a GLOB what parts of
		      # a glob will it populate.
		      # NOTE: A glob always has a SCALAR
		      local *glob = $r;
		      defined *glob{ARRAY} && "ARRAY"
		      or defined *glob{HASH} && "HASH"
		      or defined *glob{CODE} && "CODE"
		      or length(ref(${$r})) ? "REF" : "SCALAR";
		    }
		}
		: $t
	    }
END
        die if $@;
    }

    if ($needed{tainted}) {
	eval '
	    sub tainted {
	      local($@, $SIG{__DIE__}, $SIG{__WARN__});
	      local $^W = 0;
	      eval { kill 0 * $_[0] };
	      $@ =~ /^Insecure/;
	    }
	';
        die if $@;
    }

    if ($needed{readonly}) {
	eval '
	    sub readonly {
	      return 0 if tied($_[0]) || (ref(\($_[0])) ne "SCALAR");

	      local($@, $SIG{__DIE__}, $SIG{__WARN__});
	      my $tmp = $_[0];

	      !eval { $_[0] = $tmp; 1 };
	    }
        ';
        die if $@;
    }

    if ($needed{looks_like_number}) {
        eval '
	    sub looks_like_number {
	      local $_ = shift;

	      # checks from perlfaq4
	      return 1 unless defined;
	      return 1 if (/^[+-]?\d+$/); # is a +/- integer
	      return 1 if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/); # a C float
	      return 1 if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i) or ($] >= 5.006001 and /^Inf$/i);

	      0;
	    }
        ';
        die if $@;
    }
ESQ
#cj hm well::
#calc> looks_like_number( ".3e333")
#1
#calc> .3e333
#inf
    # ---- /copy from Scalar::Util ----
  ;
die $@ if ref $@ or $@;
push @EXPORT_OK,@which;

}

1
