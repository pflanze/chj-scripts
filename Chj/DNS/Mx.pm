# Tue Jun 19 14:18:28 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::DNS::Mx

=head1 SYNOPSIS

=head1 DESCRIPTION


tiny (senseless?) oo wrapper around Net::DNS::mx

chris@elvis-5 chris > calc -MChj::DNS::Mx
calc> :l $r= new Chj::DNS::Mx
calc> :d $r->orig_mx("foo-bar.ch")  #returns a *list*
$VAR1 = bless( {
                 'preference' => 0,
                 'rdlength' => 22,
                 'ttl' => 6739,
                 'name' => 'foo-bar.ch',
                 'class' => 'IN',
                 'type' => 'MX',
                 'rdata' => 'foobardyndnsorg',
                 'exchange' => 'foobar.dyndns.org'
               }, 'Net::DNS::RR::MX' );

note that Net::DNS::RR::MX does not seem to have sensible methods?

calc> :d @r= $r->mx("foo-bar.ch")
$VAR1 = bless( [
                 0,
                 5610,
                 'foo-bar.ch',
                 'foobar.dyndns.org'
               ], 'Chj::DNS::Mx::Response' );
calc> :l $r[0]->dump_publica
Chj::DNS::Mx::Response=ARRAY(0x8674ca4):
  preference: '0'
  ttl: '5610'
  name: 'foo-bar.ch'
  exchange: 'foobar.dyndns.org'


=cut


package Chj::DNS::Mx;

use strict;

use Net::DNS ();

use Class::Array -fields=>
  -publica=>
  "resolver",
  ;

use Chj::DNS::Mx::Response;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Resolver])=@_;
    $$s[Resolver]||= Net::DNS::Resolver->new;
    $s
}

sub orig_mx {
    my $s=shift;
    @_==1 or die "expecting 1 argument";
    my ($name)=@_;
    Net::DNS::mx ($$s[Resolver],$name);
}

sub mx {
    my $s=shift;
    map {
	Chj::DNS::Mx::Response->new_from_Net_DNS_RR_MX($_)
      }
      $s->orig_mx(@_);
}

end Class::Array;
