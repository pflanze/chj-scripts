#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Whois::Cached

=head1 SYNOPSIS

=head1 DESCRIPTION

look up whois info for a domain, but only if dns doesn't resolve it to
an ip (and neither with www. prefix) and then (and for first step,
too) cache the info, too.

If dnsonly is true, then no actual whois lookups are being done, but
undef returned in that case.

=cut


package Chj::Whois::Cached;

use strict;

use Class::Array -fields=>
  -publica=>
  'dbdir',
  'dnsonly',#bool  [kans nid in namen coden? kein is?well]
  'no_dns', #bool, "artificially make dns fail" (do not look up, assume it fails, go directly to whois)
  ;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Dbdir,Dnsonly,No_dns])=@_;
    $s
}


# cache dir:
# key= filename= domain.
# value= file contents =  yaml file.

# well should abstract that to a separate module. somehow..

use Chj::YAML 'UTF8LoadFile','UTF8DumpFile'; # and stores??
#or just simply \0 separated?.
#or not?

# locking ? . WARNING: no locking done.

sub xlcdomain {
    shift;
    my ($domain)=@_;
    $domain=~ m|^[^/.\0]+\.[^/.\0]+\z|
      or die "not matching domain pattern: '$domain'";#and the old 'is it dangerous to even use such strings (unsafe ones) in something like die?... [b'cause warn is already broken...]
    lc $domain
}

sub xpath_of {
    my $s=shift;
    my ($domain)=@_;
    my $lcdomain= $s->xlcdomain ($domain);
    $s->dbdir."/$lcdomain"
}

use POSIX 'ENOENT'; #well portability?...
#uswusf so isch perl wl

sub maybe_lookup_from_cache {
    my $s=shift;
    my ($domain)=@_;
    my $path= $s->xpath_of($domain);
    if (open my $in, "<:utf8", $path) {#[hum utf well]
	UTF8LoadFile ($in)
    } else {
	if ($! == ENOENT) {
	    ()
	} else {
	    die "opening '$path': $!";
	}
    }
}

#use Chj::oerr;
sub Oerr {
    for (@_) {
	my $r= &$_;
	return $r if defined $r;
    }
    undef
}
sub lookup {
    my $s=shift;
    my ($domain)=@_;
    Oerr(sub { $s->maybe_lookup_from_cache ($domain) },
	 sub { $s->lookup_and_save_to_cache ($domain) })
}

# No match for "DIRECTTRADEWEFEFEWF.COM".
use Chj::DNS 'maybe_ip_forward_lookup','maybe_ip_reverse_lookup';
use Chj::IO::Command;

sub Whois_freechecker ($ ) {
    my ($lcdomain)=@_;
    my ($lctld)= $lcdomain=~ /\.(\w+)\z/
      or die "???";
    my $c=
      +{
	com=> [
	       sub {
		   ($_[0]=~ /\nNo match for.*$lcdomain/i
		    or
		    # +-sick: not so sure this is really designating
		    # truly a free entry.. but assume it is.
		    $_[0]=~ /Registrar: DOMAINPEOPLE, INC..*\nThe Registry database contains ONLY .COM, .NET, .EDU domains and\nRegistrars.Domain not found.\n\z/s
		    )
	       },
	       sub {
		   ($_[0]=~ /\nRegistrars.Registrant:\n/
		    or
		    $_[0]=~ /\nexpires:/i
		    or
		    $_[0]=~ /\nRegistrant:/
		    or
		    $_[0]=~ /\nAdmin Name(?::|\.\.)/
		    or
		    $_[0]=~ /\nRegistrant Contact:/
		    or
		    $_[0]=~ /\n *Administrative [Cc]ontact/
		    or
		    $_[0]=~ /\nHolder Contact\n/
		    or # various possibilities, check:
		    $_[0]=~ /\nnserver:/
		    or
		    $_[0]=~ /\n *Registrar:/
		    )
	       }
	      ],
	ch=> [
	      sub {
		  $_[0] eq "We do not have an entry in our database matching your query.\n\n"
	      },
	      sub {
		  $_[0]=~ /\nHolder of domain name:\n/
	      }
	     ]
       }->{$lctld}
	 or die "don't know how to analyze results for TLD '$lctld' yet";
    my ($is_free,$is_allocated)=@$c;
    sub {
	if (&$is_free ($_[0])) {
	    1
	} elsif (&$is_allocated ($_[0])) {
	    0
	} else {
	    die "analysis failed, neither detected as free nor as allocated: '$lcdomain', '$_[0]'";
	}
    }
}

sub lookup_and_save_to_cache {
    my $s=shift;
    my ($domain)=@_;
    my $lcdomain= $s->xlcdomain($domain);

    my $res= do {
	if (!($s->no_dns) and my @fw= maybe_ip_forward_lookup ($lcdomain)) {
	    [
	     "allocated",
	     [
	      forward=> \@fw
	     ]
	    ]
	} elsif (!($s->no_dns) and
		 #my
		 @fw= maybe_ip_forward_lookup ("www.".$lcdomain)) {
	    [
	     "allocated",
	     [
	      forward_www=> \@fw
	     ]
	    ]
	} else {
	    if ($s->dnsonly) {
		return undef # the 'return' is important.. to avoid saving
		  #well. it *does* avoid caching dns. but I'm not worried about this so ok?
	    } else {
		my $freechecker= Whois_freechecker ($lcdomain);
		my $in= Chj::IO::Command-> new_sender("whois","-H",$lcdomain);
		my $cnt= $in->xcontent;
		$in->xxfinish;
		if (&$freechecker($cnt)) {
		    [
		     "free"
		    ]
		} else {
		    [
		     "allocated",
		     [
		      whois=> $cnt
		     ]
		    ]
		}
	    }
	}
    };
    my $path= $s->xpath_of($domain);
    UTF8DumpFile($path,$res);
    $res
}

sub free {
    my $s=shift;
    my ($domain)=@_;
    my $res= $s->lookup($domain);
    defined $res
      or return undef;
    my $r= $$res[0];
    if ($r eq "allocated") {
	0
    } elsif ($r eq "free") {
	1
    } else {
	die "domain '$domain' ???"
    }
}

end Class::Array;
