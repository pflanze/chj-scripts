# Sat Dec 25 18:46:28 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Maildomain

=head1 SYNOPSIS

 use Chj::Maildomain qw(maildomain);
 my $fromaddress= 'admin@'.maildomain;

=head1 DESCRIPTION

Try to automatically detect the (default) maildomain on this machine.
Looks at qmail config files [and [maybe]at ip/ifconfig/net stuff.]

The maildomain sub Does cache the value. Maybe it should not. You can still call _init to make it reread it on the next call.

=head1 NOTE: WHY?

Because sometimes just using 'sendmail -t' without giving a From: address isn't enough:
using other than the current username, or when talking SMTP directly.

=head1 CAVEAT

Maybe this should be called (or taken out to a module called) Chj::Qmail::Control::me and so on.

=cut


package Chj::Maildomain;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(maildomain);

use strict;

use Chj::xopen qw(xopen_read);

my $controlpath= "/var/qmail/control";

sub _init {
    *maildomain=sub {
	my $me= xopen_read("$controlpath/me")->xreadline;
	chomp $me;
	#no warnings 'override';
	no warnings 'redefine';
	*maildomain= sub { $me };
	$me
    }
}


_init;

1
