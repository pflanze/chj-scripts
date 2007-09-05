# Wed Sep  5 12:03:31 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::SimpleHead::Header

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single header entry.

Note that lineno() starts with 0 (as coded in SimpleHead.pm, currently).

=cut


package Chj::Mail::SimpleHead::Header;

use strict;

use MIME::Words 'decode_mimewords';
use Chj::Encode::Permissive 'encode_permissive';
use Chj::chompspace;

#use overload '""'=> 'stringify';

use Class::Array -fields=>
  -publica=>
  'Headersarrayindex',
  'Originalkey', # non-lowercased
  'Space', # the whitespace between the colon and the value
  'Value', # not decoded!
  'Lineno',
  ;


sub new_h_o_s_v_l {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Headersarrayindex, Originalkey, Space, Value, Lineno])=@_;
    $s
}

sub valueref {
    my $s=shift;
    \ do{ $$s[Value] }
}

# "cj 4.8.04: spaces am ende von headers haben dazu geführt dass
# folders kreiert wurden welche in squirrelmail/courier-imap nicht
# subscribebar waren. weil wohl spaces am ende in
# courierimapsubscribes weggelöscht werden on read supi. daher wirkli
# nun hier zentral? isch eigentlich falsch.  aber mal
# einfcahheitshaltberhier."
# Well can now access value method for un-decoded value.

sub chompedvalue {
    my $s=shift;
    chompspace($$s[Value])
}

sub decodedvalue {
    my $s=shift;
    my ($as_charset)=@_;
    join("",
	 map{ encode_permissive $_->[0],$_->[1],$as_charset }
	 decode_mimewords(chompspace($$s[Value])))
}

sub as_string { # without the terminating newline.
    my $s=shift;
    "$$s[Originalkey]:$$s[Space]$$s[Value]"
}


# ----------------------------------------------------------------------
# does not really belong into the base package here anymore maybe. But
# live is complicated otherwise I think, or do I miss some OO tech
# still?

sub maybe_received_by ($ ) { # should only be called on 'Received' headers ("of course").
    my ($header)=@_;
    my $value= $header->value;
    if ($value=~ /\bfrom\b(.*)\bby\b(.*)/s) {
	my ($rawfrom,$rawby)=($1,$2);
	if (my ($by)= $rawby=~ /(\S+)/) {
	    $by
	} else {
	    warn "HM? '$value'";
	    ()
	}
    } else {
	#warn "no from by in received header: '$value'";#
	()
    }
}


end Class::Array;

*stringify = *chompedvalue; #*decodedvalue;    strange but that's how it worked?. in mailmover{,lib}.


