#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Ifaces

=head1 SYNOPSIS

=head1 DESCRIPTION

Uses the list mode of is_if_up, but can filter out irrelevant
entries. Filtering can be done by giving interfaces explicitely, or by
subclassing and overriding the is_relevant_interface method with one
that doesn't just always give true.

=cut


package Chj::Net::Ifaces;

use strict;

use Class::Array -fields=>
  -publica=>
    (
     'opt_iface_selection',
     'hash',
    );

use Chj::is_if_up 'is_if_up';

sub new_now {
    my $class=shift;
    my $opt_iface_selection = @_ ? +{ map { $_=>1 } @_ } : undef;
    my $s= $class->new;
    $$s[Opt_iface_selection]= $opt_iface_selection;
    $s->init;
    $s
}

sub init {
    my $s=shift;
    my $opt_iface_selection = $$s[Opt_iface_selection];
    my $hash=
      +{
	map {
	    my ($name,$ip)=@$_;
	    (($opt_iface_selection ?
	      $$opt_iface_selection{$name}
	      :
	      $s->is_relevant_interface ($name)) ?
	     @$_
	     :
	     ())
	} is_if_up
       };
    #^ ok doesn't check for doubles. but *should* not happen right?
    # well perl _should_ have a hash constructor which complains.(...)
    $$s[Hash]=$hash;
}

sub interfacenames {
    my $s=shift;
    keys %{$$s[Hash]}
}

sub ips {
    my $s=shift;
    map {
	$$s[Hash]{$_}
    } $s->interfacenames
}

sub if_and_ip_s {
    my $s=shift;
    map {
	[$_, $$s[Hash]{$_}]
    } $s->interfacenames
}

sub Mk_sortedstringie {
    my ($method)=@_;
    sub {
	my $s=shift;
	join ("|",sort $s->$method)
    }
}
sub interfacenames_string;
*interfacenames_string= Mk_sortedstringie ("interfacenames");
sub ips_string;
*ips_string= Mk_sortedstringie ("ips");

sub maybe_ip_of_interface {
    my $s=shift;
    my ($interface)=@_;
    $$s[Hash]{$interface}
}

sub ip_of_interface {
    my $s=shift;
    my ($interface)=@_;
    $s->maybe_ip_of_interface ($interface)
      or die "interface not up or known: '$interface'";
}


# default is_relevant_interface method:
# (for a real example look at the recordip script)

sub is_relevant_interface {
    my $proto=shift;
    my ($if)=@_;
    1
}

end Class::Array;
