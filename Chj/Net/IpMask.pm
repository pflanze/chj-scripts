# Sat Sep  3 21:23:15 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::IpMask

=head1 SYNOPSIS

 use Chj::Net::IpMask;
 my $p= new_nethex Chj::Net::IpMask "0f318481","c0ffffff";
 print $p->ip,"/",$p->mask,"\n"; # 129.132.49.15/255.255.255.192

=head1 DESCRIPTION

(Written for vserver /proc/$pid/status ip4root parsing)

=cut


package Chj::Net::IpMask;
use strict;
use Carp;

use Class::Array -fields=>
  -publica=>
  'IntIp',
  'IntMask',
  ;


sub new_nethex {
    my $class=shift;
    @_==2 or croak "new_hex expects 2 arguments";
    my $s= $class->SUPER::new;
    (@$s[IntIp,IntMask])=map {
	#pack '%h', $_
	#pack 'h', $_  h4  alles falsch, gibt eh string aus nicht int
	nethexstr2int($_)
    } @_;
    $s
}

sub int2dotstr {
    my ($i)=@_;#no method
    #use integer;
#     int($i /255/255/255)."."
#       #.(int($i /255/255)&255)."."
#       #.(int($i /255)&255)."."
#       .(int($i /255/255)%256)."."
# 	.(int($i /255)%256)."."
# 	  .($i & 255);
#     my $o="";
#     my $r;
#     for(1..4) {
# 	$r= $i % 256;
# 	$i= int($i / 256);
# 	$o.=$r;
#scham? und reverse order noch
    ($i & 255)."."
      .(int($i /256)&255)."."
	.(int($i /256/256)&255)."."
	  .int($i /256/256/256)
}

#use Chj::BinHexOctDec ();

sub nethexstr2int { # und zwar low nibble first also  x (network order)
    my ($str)=@_;
    length($str)==8 or croak "nethexstr2int('$str'): length != 8";
    #Chj::BinHexOctDec->
    #use integer;
#     hex(substr $str,0,2)*255*255*255
#       +hex(substr $str,2,2)*255*255
# 	+hex(substr $str,4,2)*255
# 	  +hex(substr $str,6,2);
    hex($str)
}

sub ip {
    my $s=shift;
    int2dotstr($$s[IntIp])
}
sub mask {
    my $s=shift;
    int2dotstr($$s[IntMask])
}


end Class::Array;
