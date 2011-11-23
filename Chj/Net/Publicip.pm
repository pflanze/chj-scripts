# Tue Apr 13 17:12:18 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::Publicip

=head1 SYNOPSIS

 use Chj::Net::Publicip qw(publicip publicip_force);
 my @ips = publicip; # returns all found ip's, sorted so that the most likely one comes first.
 my $public = publicip; # returns the "best looking" public-looking ip, undef if no or only private-looking ips have been found.
 my $someip = publicip_force; # "force" flag; returns the "next best" non-publicly looking one if no clear public one has been found.
 # all of those can optionally take a list of interfaces to check,
 # *** XX: which is now being ignored? ***

=head1 DESCRIPTION


=cut


package Chj::Net::Publicip;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(publicip publicip_force looks_private);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

##XX UNUSED now. (but referred to by 'publicip' in chj-bin)
our @defaultifaces= qw(eth0 eth1 ppp0);

{
    package Chj::Net::Publicip_IP;
    use Class::Array -fields=> -publica=>
      (
       'iface',
       'ip',
      );
    sub new { my $cl=shift; bless [@_],$cl}

    our $if_publ=
      +{
	lo=> 0,
	eth=> 1,
	ppp=> 2,
       };

    sub publicity_likelyness {
	my $s=shift;

	my $if= $s->iface;
	$if=~ s|(\d+)$||; my $ifno=$1;
	my $val1= $$if_publ{$if};
	defined $val1 or $val1=0.5;

	my $val2;
	my $ip= $s->ip;
	if ($ip=~ m|^127\.0\.0\.(\d+)|) {
	    $val2= $1/1000;
	} elsif ($ip=~ m|^10\.0\.(\d+)\.|) {
	    $val2=0.5 + $1/1000;
	} elsif ($ip=~ m|^192\.168\.(\d+)\.|) {
	    $val2=0.8 + $1/1000;
	} else {
	    $val2= 1
	}

	$val1*10 + $val2
    }
    end Class::Array
}

## worthless now. what to do ?
sub last_best_exitcode {
    undef
}

# merlyn in #perl to the rescue:
sub _ipv4hex2list {
    reverse unpack "C*", pack "H*", shift
}

use Chj::IO::Command;

sub _ips {
    my $ipout= Chj::IO::Command->new_sender("ip","addr");
    my @ips;
    while (<$ipout>) {
	chomp;
      cont:
	if (my ($iface)= m/^\d+:\s*(\w+):/) {
	    my $is_down= /state DOWN/;
	    while (<$ipout>) {
		chomp;
		if (/^\s+/) {
		    if (my ($ip)= m{^\s+inet\s+([^ /]+)}) {
			push @ips, scalar new Chj::Net::Publicip_IP ($iface, $ip)
			  unless $is_down;
		    }
		} else {
		    #last
		    #ehr, stupid, skip the read,
		    goto cont;
		}
	    }
	} else {
	    die "no match for 'ip' output line: '$_'";
	}
    }
    $ipout->xxfinish;
    \@ips
}

sub _publicip {
    my ($opt_f,@_ifaces)=@_;

    my $ips= _ips;

    my @sortedips=
      sort { $b->publicity_likelyness <=> $a->publicity_likelyness }
	grep { $opt_f or $_->publicity_likelyness >= 1 } ## ok ?
	  @$ips;

    if (wantarray) {
	return map { $_->ip } @sortedips;
    } else {
	if (@sortedips) {
	    $sortedips[0]->ip
	} else {
	    return undef
	}
    }
}

sub publicip {
    _publicip(0,@_)
}
sub publicip_force {
    _publicip(1,@_)
}


1;
