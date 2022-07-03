#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Browser

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Browser;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Browser_exec Browser_run);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::xperlfunc ':all';
use Chj::singlequote 'singlequote_sh';

sub _Browser {
    my $exec= shift;
    sub {
	my $browser= $ENV{BROWSER} or die "missing BROWSER env var";
	## should I fall back to local-webbrowser as mdshax does and srfi did?

	my $cmd=
	  join(" ",
	       $browser,
	       map { singlequote_sh $_ } @_);
	## or split using bash as I did in srfi?
	
	$exec->( $cmd);
    }
}

*Browser_exec= _Browser (\&xexec);
*Browser_spawn= _Browser (\&xspawn);
*Browser_launch= _Browser (\&xlaunch);
*Browser_run= _Browser (\&xsystem);
*Browser_dryrun= _Browser(sub {$_[0]});

1
