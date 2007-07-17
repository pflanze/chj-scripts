# Wed Nov  5 15:13:25 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Parse::Hexdump

=head1 SYNOPSIS

 use Chj::Parse::Hexdump 'parse_hexdump';
 my $data= parse_hexdump(<<'END');
 0x0020	  436f 6e74 656e 742d	P....m..Content-
 0x0030	 7479 7065 3a20 6d75 6c74 6970 6172 742f	type:.multipart/
 0x0040	 666f 726d 2d64 6174 613b 2062 6f75 6e64	form-data;.bound
 0x0050	 6172 793d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d	ary=------------
 0x0060	 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d32	---------------2
 0x0070	 3631 3136 3236 3034 3232 3533 3833 0d0a	61162604225383..
 END

 - or -
 my $parser= new Chj::Parse::Hexdump::Parser;
 $parser->add(..line..,..line..);
 print $parser->fetch;
 $parser->add(...);
 $parser->add(...);
 print $parser->fetch;

=head1 DESCRIPTION


=cut


{
 package Chj::Parse::Hexdump::Parser;
 use Class::Array -fields=> ("Parts");

 sub add {
     my $self=shift;
     for (@_) {
	 push @{$$self[Parts]},Chj::Parse::Hexdump::parse_hexdump($_);
     }
 }

 sub fetch {
     my $self=shift;
     my $old=$$self[Parts];
     undef $$self[Parts];
     return join("",@$old);
 }
}

package Chj::Parse::Hexdump;
require Exporter; @ISA="Exporter";
@EXPORT_OK=qw(parse_hexdump);

use strict;

my $DIGIT='[0-9a-fA-F]';

sub parse_hexdump {
    my $datarf= \$_[0];
    my @linestr;
    while ($$datarf=~ /(.*)/mg) {
	my $v=$1;
	next unless length $v;
	if ($v=~ /^0x$DIGIT+\s+((?:${DIGIT}{2} ?)+)/) {
	    my $hex=$1;
	    my $linestr="";
	    while ($hex=~ /(${DIGIT}{2})/g) {
		$linestr.=chr(hex($1));
	    }
            push @linestr,$linestr;
        }
        else {
	    warn "invalid line '$v'";##  exception?
	}
    }
    join("",@linestr)
}

1;
