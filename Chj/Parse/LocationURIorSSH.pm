# Mon Oct 22 00:28:30 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::LocationURIorSSH

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::LocationURIorSSH;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(MaybeLocationURIorSSH);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::Parse::Location::URI;
use Chj::Parse::Location::SSH;

sub MaybeLocationURIorSSH ( $ ) {
    my ($uri_or_string)=@_;
    do {
	if (my $u= Chj::Parse::Location::URI->new($uri_or_string)) {
	    if ($u->is_valid(qw(ssh rsync))) { #  http https ftp   well what use is it providing these also? even bad? eg. if you have a server called http. 'scp foo http:' is completely valid...; should I request "//" following the scheme? how would I do this?
		$u
	    } else {
		()
	    }
	}
    } or do {
	Chj::Parse::Location::SSH->maybe_new($uri_or_string);
    }
}



1
