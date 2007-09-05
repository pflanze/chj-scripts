# Wed Sep  5 15:00:45 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Striphead

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mail::Striphead;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::Mail::SimpleHead;

use Chj::repl;

use Class::Array -fields=>
  -publica=>
  'LcHosts', # hash (collection) of the lc hosts which  eh whose  name  we look out for  in the head  to know where to strip.
  ;


sub new_with_hosts { # spezielle funktion um parametrisierung immerhin so chance zu geben und ah jo kann destrucktiv oder  curriend  später noch andere Werte ergänzen.
    my $class=shift;
    my $s= $class->SUPER::new;
    $$s[LcHosts]= +{ map { lc($_)=> undef } @_};
    $s
}


sub interesting_headers ($ ) {
    my $s=shift;#ah udn head dann spater isch ACUh  eine on the fly  currying. end stadium dort wo dan ausgewertetwird.
    local our ($head)=@_;
    map {
	my $header=$_;
	my $value= $header->value;
	if ($value=~ /\bfrom\b(.*)\bby\b(.*)/s) {
	    my ($rawfrom,$rawto)=($1,$2);
	    # ps solche parser sollten doch auch  raus gelagert wirklich!!!!!  gehören sie!!!!!!
	    #  wo?.  klasse.   functions.   parametrizedones maby.  MEINUNG~
	    #if (my ($from)= $rawfrom=~ /(\S+)/) {
	    #eh ich volldepp
	    if (my ($to)= $rawto=~ /(\S+)/) {
		if (exists ${$$s[LcHosts]}{lc $to}) {
		    $header
		} else {
		    ()
		}
	    } else {
		warn "HM? '$value'";
		()
	    }
	} else {
	    #warn "no from by in received header: '$value'";#
	    ()
	}
    } $head->headers ("received")
}

sub xinteresting_header ($ ) {
    my $s=shift;
    local our ($head)=@_;
    my @ih= $s->interesting_headers ($head);
    if (@ih == 1) {
	$ih[0]
    } else {
	die do {
	    @ih ? "more than one matching header found (".(scalar @ih).")"
	      : "no matching header found"
	  }
    }
}

sub stripped_head_string { # including the empty line after the head
    my $s=shift;
    local our ($head)=@_;
    local our $idx= $s->xinteresting_header($head)->headersarrayindex;
    local our $ary= $head->headersArray;
    #repl;
    join("\n",(map { $_->as_string } @$ary[$idx+1..$#$ary]),"","")
}

end Class::Array;
