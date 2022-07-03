#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::DNS

=head1 SYNOPSIS

 use Chj::DNS ':all';
 @res or $res = maybe_ip_forward_lookup $name;
	dito    maybe_ip_reverse_lookup $ip

=head1 DESCRIPTION


=cut


package Chj::DNS;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
	      maybe_ip_forward_lookup
	      maybe_ip_reverse_lookup
	     );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Net::DNS;

our $resolver= Net::DNS::Resolver->new; #hm. should I still  creator  methods  OO or so ?(or modulebased parametrization)

sub mk_lookup {
    #my ($type, $method)=@_;
    #hm interessant  weil ich bei rdatastr noch . wegnehmen muss, muss ich eignen code haben.
    my ($type,$fn)=@_;
    sub ( $ ) { #wirkt das oder nid?.-> es wirkt (undwie, vgl. grr below)
	my ($ip)=@_;
	my $query= $resolver->search ($ip); #ok?
	if ($query) {
	    my @res;
	    local our $rr;
	    for $rr ($query->answer) { #not answers. sowat stupid~.
		#use Chj::repl; repl;
		next unless $rr->type eq $type;
		push @res, &$fn ($rr);
	    }
	    wantarray ? @res : $res[0]
	} else {
	    #debug "maybe_ip_reverse_lookup for ip '$ip' failed";
	    ()
	}
    }
}

sub maybe_ip_forward_lookup ( $ ); # against 'only used once' warning. grr.
*maybe_ip_forward_lookup= mk_lookup("A",sub { $_[0]->address });
sub maybe_ip_reverse_lookup ( $ );
*maybe_ip_reverse_lookup= mk_lookup("PTR",sub {
				  my $res= $_[0]->rdatastr;
				  $res=~ s/\.\z//
				    or die "no match for dot at end in '$res'";
				  $res
			      });


1
