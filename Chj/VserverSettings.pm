# Sat Mar 31 14:39:23 2007  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::VserverSettings

=head1 SYNOPSIS

=head1 DESCRIPTION

Some basic values for accessing Vserver data.

=cut


package Chj::VserverSettings;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      $etcbase
	      $installdir
	      $chroot_sh
	      chroot_sh_cat
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

our $etcbase= "/etc/vservers";

# use Chj::xperlfunc;
# sub chroot_sh {
#     xsystem   hm nein, weil will sie ev ja auch  mit io pipes usw aufrufen.
#       hm. das was im child ausgeführt werden muss hier so.  mal irgendwannnachdenken
# }

our $use_opt= do {
    my $p= `which vserver`;
    if ($p =~ m{^/usr/sbin/}) {
	0
    } elsif ($p=~ m{^/opt/vserver}) {
	1
    } else {
	die "are vserver utils installed correctly?: which vserver gives: '$p'";
    }
};

our $installdir= $use_opt ? "/opt/vserver" : "/usr";
our $chroot_sh= "$installdir/lib/util-vserver/chroot-sh";

# should these be here?:
use Chj::IO::Command;
use Chj::xperlfunc qw(xchdir xexec);
sub chroot_sh_cat {
    @_ >= 1 or die "chroot_sh_cat: not enough arguments";
    my $chrootdir= shift;
    Chj::IO::Command->new_sender
	(sub {
	     xchdir $chrootdir; # is then being used by $chroot_sh as chroot dir
	     xexec $chroot_sh, "cat", @_ #that's this sub's arguments, not directly the @_ from above (although the same values (passed through))
	 },@_);
}
#(chroot_sh does (currently) not support any 'exists' or 'readlink' commands)

1
