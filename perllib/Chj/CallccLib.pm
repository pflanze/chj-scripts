#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::CallccLib

=head1 SYNOPSIS

 use Chj::callcc2;

 callcc sub {
     my ($exit)=@_;
     my $entry= [ xref($rec,'s',$exit), xref($rec,'_p',$exit) ];
     push @foo, $entry;
 };

=head1 DESCRIPTION

Procedures/functions that take abort continuations.

=cut


package Chj::CallccLib;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xref);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;


sub xref ($ $ $ ) {
    my ($hsh,$key,$maybe_exit)=@_;
    my $val= $$hsh{$key};
    if (defined $val) {
	$val
    } else {
	if ($maybe_exit) {
	    &$maybe_exit;
	} else {
	    die "key not present in hash: '$key', ".Dumper ($hsh);
	}
    }
}


1
