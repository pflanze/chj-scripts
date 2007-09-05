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

use strict;

use Chj::Mail::SimpleHead;

#use Chj::repl;

our @modes= qw(LAST SINGLE);

use Class::Array -fields=>
  -publica=>
  'LcHosts', # hash, lc(fqhostname) to one of the @modes, denoting the name(s) of the host which receives the mails, to which we want to cut down the mail head. ah and the mode is followed by a priority.   $fqhostname => [ $MODE , $prio ];  lower value of $prio means "higher priority".
  ;


sub new_with_hosts { # spezielle funktion um parametrisierung immerhin so chance zu geben und ah jo kann destrucktiv oder  curriend  später noch andere Werte ergänzen.
    my $class=shift;
    my $s= $class->SUPER::new;
    $$s[LcHosts]= do {
	my $h= +{ @_ };
	my $hh;
	for my $k (keys %$h) {
	    $$hh{lc $k}= $$h{$k}
	}
	$hh
    };# SO macht man das weisch!  es isch eben NICHT einfach selbstverständlichbuilt in to prl weisch.
    $s
}

sub Header_maybe_received_to ($ ) {
    my ($header)=@_;
    my $value= $header->value;
    if ($value=~ /\bfrom\b(.*)\bby\b(.*)/s) {
	my ($rawfrom,$rawto)=($1,$2);
	if (my ($to)= $rawto=~ /(\S+)/) {
	    $to
	} else {
	    warn "HM? '$value'";
	    ()
	}
    } else {
	#warn "no from by in received header: '$value'";#
	()
    }
}


sub xinteresting_header ($ ) {
    my $s=shift;
    local our ($head)=@_;
    local our $found= {};
    for our $header ($head->headers ("received")) {
	if (my $lcto= lc (Header_maybe_received_to ($header))) {
	    if (my $p= ${$$s[LcHosts]}{$lcto}) {
		my ($kind,$prio)= @$p;#p wie pair tja well wohl oder nid so. multivalue. tupl. $t?
		if ($kind eq "SINGLE") {
		    if (exists $$found{$lcto}) {
			die "multiple headers found for '$lcto'";
		    } else {
			$$found{$lcto}= $header
		    }
		} elsif ($kind eq "LAST") {
		    $$found{$lcto}= $header
		} else {
		    die "usage error: invalid kind '$kind'";
		}
	    }
	    # else 'do nothing'
	} # else non-interesting header
    }
    # now order/group the values of $found by priorities:
    local our $grouped= {}; # prio => array of objs. well no. just one. multiple are an error right away.
    while (local our ($lcto,$header)= each %$found) {
	local our $prio= $$s[LcHosts]{$lcto}[1];
	if (local our $obj= $$grouped{$prio}) {
	    if ($obj eq $header) {
		# ok
	    } else {
		die "multiple results of the same priority '$prio'"
	    }
	} else {
	    $$grouped{$prio}= $header
	}
    }
    if (defined (local our $selectedprio = (sort { $a cmp $b } keys %$grouped)[0])) {
	$$grouped{$selectedprio}
    } else {
	die "none of the defined receiving hosts found in the head"
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
