# Sun Aug 10 21:10:52 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Linux::Network

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Linux::Network;

use strict;


#use Class::Array -fields=> ();
# ------------------------------------
package Chj::Linux::Network::Interfaces;
#use Chj::xopen;
use Chj::IO::Command;
my $ifconfig= "/sbin/ifconfig";
sub new {
    my $class=shift;
    local $ENV{LANG}="C";#just to be sure
    my $contr= \ Chj::IO::Command->new_reader($ifconfig,"-a")->xcontent;
    # split into blocks:
    my @block;
    my %indexed;
    my %hierachical;
    for my $block (split /\n{2,}/,$$contr) {
	$block=~ /^(\S+)\s+(.*)/s
	  or die "invalid format: '$block'";
	my ($iface,$rest)= ($1,$2);
	push @block,$block;
	$indexed{$iface}=$rest;
	$iface=~ /^([^:]+)(?::([^:]+))?$/
	  or die "invalid format: '$iface'";
	my ($main,$sub)=($1,$2);
	$hierachical{$main}{$sub||""}=$rest;
    }
    my $self= {indexed=>\%indexed,
	       hierachical=> \%hierachical,
	       blocks=>\@block,
	      };
    bless $self,$class
}
#sub __extractinfo { # str to (inet address, bcast, masq, up, broadcast, running, multicast)

sub __isup {
    my ($str)=@_;
    $str=~ /\n *UP/s
}

sub is_up {
    my $self=shift;
    map {
	exists $self->{indexed}{$_} ?
	  __isup($self->{indexed}{$_})
	    : undef } @_;
}



# ------------------------------------
package Chj::Linux::Network::Route;
use Chj::xopen;

my $file= "/proc/net/route";

sub new {
    my $class=shift;
    my $self= \ xopen ($file)->xcontent;
    # kill title line
    $$self=~ s/^iface\s+destination\s+gateway\s+[^\n]+\n//is
      or die "'invalid' $file file format ($$self)";
    bless $self,$class
}

sub _initscan {
    my $self=shift;
    pos( $$self)=0;
}

sub _nextline {
    my $self=shift;
  line: {
	if ($$self=~ /\G([^\n]*)\n/sg) {
	    my $line=$1;
	    redo line unless $line;
	    $line=~ /^(\S+)\s+(\S+)\s+(\S+)\s+/
	      or die "format error";
	    #warn "funden";
	    my ($iface,$dest,$gateway)=($1,$2,$3);
	    #return ($1,$2,$3)
	} else {
	    warn "fertig";
	    ()
	}
    }
}

sub hex2dot {
    my ($str)=@_;
    #join(".", map{ hex $_ } split /../, $str)
    ##hey wie splittet man an positions?
    #join(".", map{ hex $_ } substr ($str,0,2,"") )
    my @a;
    while (length ($_=substr ($str,0,2,"")) ) {
	push @a, hex $_
    }
    join(".",@a)
}

sub defaultgateway {
    my $self=shift;
    $self->_initscan;
    while (my ($dest,$gw)= ($self->_nextline)[1,2]) {
	#warn "dest='$dest', gw='$gw'";
	if ($dest eq '00000000') {
	    if ($gw eq '00000000') {
		die "strange?";
	    } else {
		return hex2dot($gw)
	    }
	} else {
	    # continue
	}
    }
    return undef;
}


1;
