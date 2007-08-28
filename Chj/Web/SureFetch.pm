# Thu Jun 19 14:40:34 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Web::SureFetch

=head1 SYNOPSIS

use Chj::Web::SureFetch;
my $contentref= surefetch 'http://www.ethlife.ethz.ch/';

=head1 DESCRIPTION

Dies on errors, or if the fetched page looks suspicious, i.e. empty, or with
text looking like it's error page.
Currently uses LWP.

=head1 GLOBALS

=over 4

=item $Chj::Web::SureFetch::sleep = 5;

Sleep for so long between refetches after errors.

=back

=cut


package Chj::Web::SureFetch;
@ISA='Exporter'; require Exporter;
@EXPORT= qw(surefetch);

use strict;
use LWP::UserAgent;
use Carp;

our $sleep=5;
our $verbose=1;

sub onlyone(\@) {
    my ($err)=@_;
    my @err;
    my $last;
    for (@$err) {
	if (!defined $last or $last ne $_){
	    push @err,$_
	}
	$last=$_
    }
    join " / ",@err
}

sub surefetch {
    my ($url,$wantarray)=@_; # not rely on wantarray since it might not be backwards compatible. (array contexts dis eh a pointments)
    my $contentref;
    my $result;
  TRY: {
	my @error;
	for (1..3) {
	    my $ua = LWP::UserAgent->new()   or die "??";
	    $ua->agent("Mozilla/LibWWW-Perl ($0)");
	    my $req = new HTTP::Request GET => $url   or die "??";
	    #$req->header('Accept' => 'text/plain');
	    #$req->header('Accept' => 'text/html'); ## ist das ok so?  oder einfach beide raus.?
	    $result = $ua->request($req);
	    if ($result->is_success) {
		$contentref = \ $result->content;
		if ($$contentref =~ /ERROR/ && $$contentref =~ /404/) {
		    push @error, "Page contains ERROR and 404";
		} elsif ($$contentref=~ /Fehler aufgetreten/) {
		    push @error, "Page contains 'Fehler aufgetreten'";
		} elsif ($$contentref=~ /axkit.*error/i) {
		    push @error, "Page contains /axkit.*error/i";
		} else {
		    last TRY;
		}
	    } else {
		push @error, $result->status_line
	    }
	    if ($sleep) {
		print STDERR "surefetch '$url': going to sleep for $sleep seconds.." if $verbose;
		sleep $sleep;
		print STDERR "done sleeping.\n" if $verbose;
	    }
	}
	croak "surefetch('$url'): repeated error: ".(onlyone @error);
    }
    return $wantarray ? ($contentref, $result) : $contentref;
}

1;
