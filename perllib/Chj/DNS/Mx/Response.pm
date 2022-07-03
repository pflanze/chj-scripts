# Tue Jun 19 14:27:22 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::DNS::Mx::Response

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::DNS::Mx::Response;

use strict;

use Class::Array -fields=>
  -publica=>
  'preference',
  'ttl',
  'name',
  'exchange',
  -namehash=> 'namehash' #there's no -lcnamehash hm
  ;

our @orig_fields=
  keys( %{
      do {
	  +{
	    'preference' => 0,
	    #'rdlength' => 22,
	    'ttl' => 6739,
	    'name' => 'foo-bar.ch',
	    #'class' => 'IN',
	    #'type' => 'MX',
	    #'rdata' => 'foobardyndnsorg', #what's that?
	    'exchange' => 'foobar.dyndns.org'
	   }
      }});

sub new_from_Net_DNS_RR_MX {
    my $class=shift;
    my $s= $class->SUPER::new;
    my ($orig)=@_;
    #an assertion:
    $$orig{type} eq "MX" or die "problem: it seems Net::DNS changed!";
    for (@orig_fields) {
	exists $$orig{$_} or die "problem: missing field '$_' (has Net::DNS changed?)";
	$$s[ $namehash{ucfirst $_} ]= $$orig{$_}
    }
    $s
}



end Class::Array;
