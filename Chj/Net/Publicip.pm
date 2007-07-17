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
 # otherwise @Chj::Net::Publicip::defaultifaces is used.

=head1 DESCRIPTION


=cut


package Chj::Net::Publicip;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(publicip publicip_force looks_private);
use strict;


use Chj::xopen;
use lib "/root/extlib"; ##urgh
use is_if_up;


our @defaultifaces= qw(eth0 eth1 ppp0);


sub looks_private {
    local ($_)=@_;
    /^192\.168\./ and return 1;
    /^10\.0\./ and return 1; ## true?
    ## etc.
    $_ eq '127.0.0.1' and return 2;
    0
}

my $last_exitcodes;
sub last_best_exitcode {
    # welcher exitcode kam am häufigsten vor?
    (sort { $b->[1] <=> $a->[1] } map { [ $_, $$last_exitcodes{$_} ] } keys %$last_exitcodes)[0]->[0] ||0
}

#sub _ipv4hex2list {
#    my @fl= unpack "hhhhhhhh", shift;
#print "fl=",    join("-",@fl),"\n";
#    $fl[6]*16+$fl[7],$fl[4]*16+$fl[5],$fl[2]*16+$fl[3],$fl[0]*16+$fl[1]
#}
#calc> join(",",unpack "hhhhhhhh","0105a8c0")
#0,1,0,5,1,8,3,0
#calc> join(",",unpack "HHHHHHHH","0105a8c0")
#3,3,3,3,6,3,6,3
#  es isch chrank

# merlyn in #perl to the rescue:
sub _ipv4hex2list {
    reverse unpack "C*", pack "H*", shift
}

sub _publicip {
    my ($opt_f,@ifaces)=@_;
    my (@foundpriv,@foundpub);
    $last_exitcodes={};
    my $flag_vserver;
    for my $iface (@ifaces ? @ifaces : @defaultifaces) {
	#warn "check $iface";
	eval {
	    my $ip= is_if_up($iface);
	    if (defined $ip) {
		if (length $ip) {
		    my $priv= looks_private $ip;
		    if (!$priv) {
			if (wantarray) {
			    push @foundpub,$ip;
			} else {
			    #return $ip;
			    # ach shit, kann nicht aus eval direkt return machen sigh
			    # last ginge noch  aber warning?
			    # und:
			    push @foundpub,$ip;
			    no warnings;
			    last;# FOR;
			}
		    } elsif ($priv==1) {
			push @foundpriv,$ip;
		    }# else ??? todo check
		} else {
		    $$last_exitcodes{2}++
		}
	    } else {
		$$last_exitcodes{$? >> 8}++
	    }
	};
	if ($@) {
	    if ($@=~ /no match for 'inet addr'/) {
		# looks like vserver case, can't read interface adresses.
		# still check all interfaces through, maybe one has a visible address
		$flag_vserver=1;
	    } else {
		die
	    }
	}
    }

    if ($flag_vserver) {
	# also check this:
	my $c= (xopen "/proc/self/status")->xcontent;
	# ipv4root: 0105000a/00ffffff 0105a8c0/00ffffff
	if ($c=~ /^ipv4root: *(.*)/m){
	    my $ifaces=$1;
	    for my $hexface (reverse split /\s+/,$ifaces) { # reverse, since in my vserver setup, localhost addresses are listed first in the status, then the other private one. ##todo should probably make all this cleaner by using a scoring approach, instead of just yes-no in looks_private().
		my ($ip,$mask)=split /\//, $hexface;
		$ip= join ".",_ipv4hex2list $ip;
		# und jetzt denselben zirkus wie oben
		#copy
		    my $priv= looks_private $ip;
		    if (!$priv) {
			if (wantarray) {
			    push @foundpub,$ip;
			} else {
			    return $ip;
			}
		    } elsif ($priv==1) {
			push @foundpriv,$ip;
		    }# else ??? todo check
		#/copy
	    }
	} else {
	    warn "strange, vserver or not vserver?";
	}
    }

    if (wantarray) {
	return @foundpub,@foundpriv
    } else {
	if (@foundpub) {
	    return $foundpub[0]
	} else {
	    if ($opt_f) {
		return $foundpriv[0];
	    } else {
		return undef;
	    }
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
