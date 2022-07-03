# Fri Aug 22 17:08:19 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::DroneBL - access to the DroneBL database of abusable IPs

=head1 SYNOPSIS

 our $dronebl= new Chj::Net::DroneBL;
 $dronebl->lookup($ipstring)
  # returns () if the ip is not listed, the type[s?] otherwise.

=head1 DESCRIPTION

See http://dronebl.org/docs/howtouse

=cut


package Chj::Net::DroneBL;

use strict;

use Net::DNS;


use Class::Array -fields=>
  -publica=>
  'resolver',
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    $$s[Resolver]= Net::DNS::Resolver->new;
    $s
}

sub lookup {
    my $s=shift;
    my ($ip)=@_;
    my @ip= split /\./,$ip;
    @ip==4 or die "not an ipv4 address: '$ip'";
    my $revip=
      join(".",
	   reverse
	   map {
	       (/^(\d{1,3})\z/ ?
		($1 < 256 ?
		 $1
		 : die "invalid '$1'")
		: die "invalid: '$_'")
	   }
	   @ip);
    my $addr= "$revip.dnsbl.dronebl.org";
    if (my $query= $$s[Resolver]->search($addr)) {
	map {
	    ($_->type eq "A" ?
	     $s->result_parse($_->rdatastr) :
	     ())
	} ($query->answer)
    } else {
	() # or undef?
    }
}

sub result_parse {
    shift;
    my ($str)=@_;
    $str=~ /^127\.0\.0\.(\d+)\z/
      or die "invalid result '$str'";
    $1
}

end Class::Array;
