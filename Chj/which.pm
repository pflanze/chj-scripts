#
# Copyright 2019 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::which

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::which;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(perhaps_which maybe_which which);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';


use Chj::IO::Command;
use Chj::Chomp;


sub perhaps_which ($) {
    my ($progname)=@_;
    my $in= Chj::IO::Command->new_sender("which", $progname);
    my $cnt= $in->xcontent;
    my $res=$in->xfinish;
    if ($res==0) {
	Chomp ($cnt)
    } else {
	()
    }
}

sub maybe_which ($) {
    scalar perhaps_which $_[0]
}

sub which ($) {
    maybe_which $_[0] // die "which: command not found: '$_[0]'";
}


1
