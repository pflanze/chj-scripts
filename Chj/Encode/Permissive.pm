# Tue Jul 20 22:47:45 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Encode::Permissive

=head1 SYNOPSIS

 use Chj::Encode::Permissive 'encode_permissive';
 my $isostr= encode_permissive $somestr, 'latin2', 'latin1';

=head1 DESCRIPTION

do not croak on errors, but instead represent chars as ? if they cannot be
encoded to the target encoding

=cut


package Chj::Encode::Permissive;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(encode_permissive);
use strict;

use Text::Iconv;
use Carp;
#use bytes;

my $questionmark32bit= do {
    my $conv= Text::Iconv->new("ascii","utf-32");#####macht header
    #substr($conv->convert("?"),4,4)
    #substr($conv->convert("?"),4,4)  # looks like 0000 feff is put in front.
    $conv->convert(".");#dry run to get rid of header.
    $conv->convert("?") #na, trockenencoding zuerst hilft auch.
};
#print STDOUT "questionmark32bit='$questionmark32bit'\n";
#     my $s= new_receiver Chj::IO::Command "xxd";
#     $s->xprint($questionmark32bit);
#     $s->xxfinish;
# }
# "\x00\x00\x00\x3f";

# sub dumpstring {
#     use Chj::IO::Command;
#     #(new_receiver Chj::IO::Command "xxd")->xprint(@_);
#     my $s= new_receiver Chj::IO::Command "xxd";
#     $s->xprint(@_);
#     $s->xxfinish;
# }
# dumpstring $questionmark32bit;

sub bits_of_encoding { # number of bits per char (8,16,32). 0=variable (utf-8), [ reserved:  undef= variable (not utf-8) ].
    my ($enc)=@_;
    if ($enc=~ /^utf-?8\z/i) {
	0
    } elsif ($enc=~ /^utf-?16\z/i) {
	16
    } elsif ($enc=~ /^utf-?32\z/i) {
	32
    } else {
	8   ##well, other variable encodings that are not utf-8?
    }
}

my %drychar=(
	     8=>".",
	     16=>do {
		 my $conv= Text::Iconv->new("ascii","utf-16"); $conv->convert("."); #dry run
		 $conv->convert(".")
	     },
	     32=>$questionmark32bit,
	     0=>do {
		 my $conv= Text::Iconv->new("ascii","utf-8"); $conv->convert("."); #dry run
		 $conv->convert(".")  #(well I knew that was givin '.' but anyway)
	     },
	    );

sub encode_permissive {
    my $from=$_[1]||"ascii";
    my $to=$_[2]||"latin1";
    ## is input multibyte?
    #if ($from=~ /^\s*utf/i) {
    # # just convert it,
    # ach. nach utf-8 und DANN 1 char nach dem anderern drannehmen.?.
    #use utf8;#hm. ok? put here for perl 5.6.
    #my $conv1= Text::Iconv->new($from,"utf-8");

    #my $conv= Text::Iconv->new($from,$to);
    #$conv->convert($_[0]);

    #idee: utf-16. oder 32.

    # na  unknown-8bit  hat zu exception geführt hier.
    my $conv1= eval { Text::Iconv->new($from,"utf-32") };
    if ($@) {
	if ($@=~ /unsupported conversion/i) {
	    $from="ascii";## oder ev latin1.
	    $conv1= Text::Iconv->new($from,"utf-32");
	} else {
	    die $@
	}
    }
    $conv1->convert($drychar{bits_of_encoding($from)});#dry run to get rid of header.
    my $zwi= $conv1->convert($_[0]);
    if (defined $zwi){
      quer:
	#print "Zwi:\n";
	#$zwi= "\x00\x00\xfe\xff".$zwi; ich versteh nicht. dies hier macht ein ? rein.
	#dumpstring $zwi;
	my $questionmark= do {
	    my $conv= Text::Iconv->new("ascii",$to); $conv->convert(".");#dry run to get rid of header
	    $conv->convert("?")
	};
	my $conv2= Text::Iconv->new("utf-32",$to); $conv2->convert($questionmark32bit);#dry run to get rid of header.
	my $len= (length $zwi)/4;
	my $out="";
	#for (my $i=0; $i++; $i<$len) {
	#for(1;1;1){
	for (my $i=0; $i<$len; $i++) {
	    #print STDERR "1";
	    my $c= $conv2->convert(	substr($zwi,$i*4,4) );
	    if (defined $c) {
		$out.=$c;
	    } else {
		$out.=$questionmark;
	    }
	}
	$out
    } else {
	# die "iconv error (? can this happen that you cannot convert to utf-32?)"; yes:
	# string contains chars that are not present in 'from' encoding.
	my $bits= bits_of_encoding $from;
	if (!$bits){
	    # hm, what should we do? can't convert charwise.
	    #croak "encode_permissive: conversion of source string from utf-8 to utf-32 failed - giving up";
	    carp "encode_permissive: conversion of source string from utf-8 to utf-32 failed - assuming ascii";
	    return encode_permissive($_[0],"ascii",$to);
	} elsif ($bits == 16) {
	    #warn "16 bit source. convert char wise";
	    $zwi="";
	    my $len=(length $_[0])/2;
	    for (my $i=0;$i<$len; $i++) {
		my $c= $conv1->convert(substr($_[0],$i*2,2));
		if (defined $c) {
		    $zwi.=$c;
		} else {
		    $zwi.=$questionmark32bit;
		}
	    }
	    goto quer;
	} elsif ($bits == 32) {
	    $zwi=$_[0];
	    goto quer;# failing chars should be converted rightly
	} else {
	    #warn "8 bit source. convert char wise";
	    $zwi="";
	    my $len=(length $_[0]);
	    for (my $i=0;$i<$len; $i++) {
		my $c= $conv1->convert(substr($_[0],$i,1));
		#warn "Char: '$c'";
		if (defined $c) {
		    $zwi.=$c;
		} else {
		    $zwi.=$questionmark32bit;
		}
	    }
	    #print "zwi ist '$zwi'\n";
	    goto quer;
	}
    }
}

1;
