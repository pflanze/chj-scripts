# Fri Mar  3 18:03:22 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Random::Formatted

=head1 SYNOPSIS

 random_hex_string(5); #=> 871378cf23
 random_passwd_string(5); #=> e5gs78y2
 # both are 40 bit internally.

=head1 DESCRIPTION


=cut


package Chj::Random::Formatted;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      random_hex_string
	      random_passwd_string
	     );

use strict;

use Chj::Random 'seed';#wir benützen hier immer seed. weil wir zu faul sind das in n userspace generator zu füttern noch. und handle an clients zu geben mit auftrag fork zu beachten.

#ps remember: in schm was geschrieben schon mal
#ja  warum alles noch mal ..
sub random_hex_string {
    # length argument is, as "usual", the length of the underlying data in bytes
    my $bin= &seed;
    unpack('H*',$bin)
}

# Mon, 03 Apr 2006 16:14:30 +0200
# from thea from elcms

#use constant PASSWDCHARS=> join("","a".."k","m","n","p".."z","2".."9"); # 32 chars
#sub randompasswdstring {
#    my ($numchars)=@_;
#    join("",map { substr(PASSWDCHARS, myrand(length(PASSWDCHARS)),1) } 1..$numchars );
#}
# hm in myrand i operated with 64bit buffers and integer calculations. ok, do that here as well?

# alternative: wenn es ausserhalb liegt, nächstes byte nehmen ?

# ah, 32 chars, = 5 bits
#ehr remember. from NL MsgID.pm:

our @chars= ("a".."k","m","n","p".."z","2".."9"); # 32 chars
sub _binary2text {
    my ($b)=@_;
    # 5bitwise schieben: kann perl das? Nur mit integers. Bitarrays?
    # oder eben: byteposition, und bitposition.
    # von links her. nun egal. hauptsache network!
    # network: big endian: big kommt am schluss. richtig.
    my $text="";
    use integer;
    for (my $bit=0; $bit< (length($b)*8-1); $bit+=5 ) {
	my $byte= $bit / 8;
	my $shift= $bit % 8;
	#warn "Bit $bit: Byteno=$byte, bitshift=$shift\n";
	my $I= unpack("v",substr($b,$byte,2))||ord(substr($b,$byte,1));
	#warn "I=$I; der relevante Teil ist dann: ".(($I >> $shift) & 31)."\n";
	$text.= $chars[($I >> $shift) & 31];
    }
    $text
}

# sub _text2binary {
#     my ($t)=@_;
#     my $b="";
#     use integer;
#     for my $i (0..length($t)-1) { # number of 5-bit piece
# 	my $char= lc(substr($t,$i,1));
# 	my $o= ord($char);
# 	$o= $o < 97 ? $o-48+26 : $o-97; # faster than lookup in array I guess
# 	my $bit= $i*5;
# 	my $byte= $bit / 8;
# 	my $shift= $bit % 8;
# 	$o <<= $shift;
# 	#unpack("n",substr($b,$byte,2))
# 	if ($shift <= 3) {
# 	    # one byte only to look at
# 	    substr($b,$byte,1)= chr(ord(substr($b,$byte,1)) | $o);
# 	} else {
# 	    # two bytes to look at
# 	    #substr($b,$byte,2)= pack("n",(unpack("n",substr($b,$byte,2)) | $o));
# 	    #but we have only *one* byte from previous run.
# 	    $o= ord(substr($b,$byte,1)) | $o;
# 	    substr($b,$byte,2)= pack("v",$o);
# 	}
#     }
#     $b
# }
# NOTE: the above has a bug that lead to a nullbyte being appended to the decrypted string. But why bother.
#hm gibt eh komplett was anderes, komisch?.

sub random_passwd_string {
    my ($seedlength)=@_;
    my $bin= seed($seedlength);
    _binary2text($bin)
}


1
