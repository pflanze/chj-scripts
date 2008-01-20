# Thu Dec 11 12:30:33 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::AskChoose

=head1 SYNOPSIS

 perl -MChj::Util::AskChoose=askchoose_autonum_withcanceldef -e 'use strict; my $a= askchoose_autonum_withcanceldef (["N","[N]ix"],"fun","for","you"); print "Antwort war: $a\n"'

=head1 DESCRIPTION

User may enter one answer to a multiple choice question.

=cut

#'

package Chj::Util::AskChoose;
@ISA="Exporter"; require Exporter;
#@EXPORT= qw(askchoose);
@EXPORT_OK=qw(askchoose_autonum_withcanceldef);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Carp;

sub askchoose_autonum_withcanceldef {
    my ($canceldef, @optiontexts)=@_;
    my ($cancelchar,$canceltext)=@$canceldef; # cancelchar may be empty/undef, in which case an empty answer is interpreted as cancel. logischerweise.

    my $prompt;
    my %map;
    {
	my @p;
	my $z=1;
	for (@optiontexts){
	    #push @p, "[$z] $_";
	    push @p, "[$z]$_"; # it's visually clearer without a space between optionnumber and -text -- at least/especially in the case of the 'movefiles' script with .directory arguments.
	    $map{$z}=$_;
	    $z++;
	}
	$prompt= join(", ",$canceltext,@p);
    }
    $cancelchar="" unless defined $cancelchar;
    croak "askchoose_autonum_withcanceldef: cancelchar is used in numbering as well" if exists $map{$cancelchar};
    $map{$cancelchar}= undef;

    local$|=1;
    my $n=10;
  ASK: {
	print "$prompt: ";
	my $ans=<STDIN>;
	if (defined $ans) {
	    #chomp $ans;
	    $ans=~ s/\s+\z//s; $ans=~ s/^\s+//s;
	    if (exists $map{$ans}) {
		return $map{$ans};
	    } else {
		if (--$n > 0) {
		    redo ASK;
		} else {
		    croak "askchoose_autonum_withcanceldef: too many failed attempts to ask"
		}
	    }
	} else {
	    croak "askchoose_autonum_withcanceldef: eof on stdin"
	}
    }
}

1;
