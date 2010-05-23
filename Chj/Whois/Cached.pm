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


=cut


package Chj::Whois::Cached;

use strict;

use Class::Array -fields=>
  -publica=>
  'dbdir',
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Dbdir])=@_;
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

sub xassert_domain {
    shift;
    my ($domain)=@_;
    $domain=~ m|^[^/.\0]+\.[^/.\0]+\z|
      or die "not matching domain pattern: '$domain'";#and the old 'is it dangerous to even use such strings (unsafe ones) in something like die?... [b'cause warn is already broken...]
}

sub xpath_of {
    my $s=shift;
    my ($domain)=@_;
    $s->xassert_domain ($domain);
    # stat? or: hope this works:
    #grrrr. I do not have an Xopen. right.
    $s->dbdir."/$domain";#and this is not yet de dingslet. convert oben. nid assert.
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

sub lookup {
    my $s=shift;
    my ($domain)=@_;
    ($s->maybe_lookup_from_cache ($domain)
     or
     $s->lookup_and_save_to_cache ($domain))
}

# No match for "DIRECTTRADEWEFEFEWF.COM".
use Chj::DNS 'maybe_ip_forward_lookup','maybe_ip_reverse_lookup';
use Chj::IO::Command;

sub lookup_and_save_to_cache {
    my $s=shift;
    my ($domain)=@_;

    my $res= do {
	if (my @fw= maybe_ip_forward_lookup ($domain)) {
	    [
	     "allocated",
	     [
	      forward=> \@fw
	     ]
	    ]
	} elsif (#my
		 @fw= maybe_ip_forward_lookup ("www.".$domain)) {
	    [
	     "allocated",
	     [
	      forward_www=> \@fw
	     ]
	    ]
	} else {
	    my $in= Chj::IO::Command-> new_sender("whois",$domain);
	    my $cnt= $in->xcontent;
	    $in->xxfinish;
	    if ($cnt=~ /^No match for.*$domain/i) {
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
    };
    my $path= $s->xpath_of($domain);
    UTF8DumpFile($path,$res);
    $res
}

sub free {
    my $s=shift;
    my ($domain)=@_;
    my $res= $s->lookup($domain);
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
