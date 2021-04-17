# Tue Feb 15 16:38:31 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Predicates - type predicate and conversion functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Predicates;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   is_symbol is_glob
	   is_number
	   string_of_symbol
	   symbol_of_string
	  );

use strict;


sub is_symbol {
    ref(\$_[0]) eq 'GLOB'
}
*is_glob= \&is_symbol;


sub is_number { # alternative Devel::Peek gaht nöd guet, SvIV direkt selber wäre besser.
    my ($str)=@_;
    #$str=~ /^[+-]?(?:\d+\.?|\d*\.\d+)\z/
    if ($str=~ /^-?\d+(?:\.\d+)?(?:e[+-]\d+)?\z/) {
	my $num= $str + 0;
	"$num" eq $str
    } else {
	0
    }
}


sub string_of_symbol {
    my ($sym,$suppresspackage)=@_;
    my $str=substr($sym,1);
    if ($suppresspackage) {
	$str=~ s/^\Q$suppresspackage\E:://;
	if ($suppresspackage eq "") {
	    $str=~ s/^main:://;
	}
    }
    $str
}

sub symbol_of_string {
    my ($str,$package)=@_;
    unless ($str=~ /::/) {
	$package||=caller;
	$str= "${package}::$str"
    }
    no strict 'refs';
    *{$str}
}



1
__END__
  grr, Data::Dumper kann unterscheiden, offenbar hat er selber XS code dafür.
  warum nicht modular.

