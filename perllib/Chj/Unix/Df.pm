# Sun Nov 28 15:37:29 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Df

=head1 SYNOPSIS

 use Chj::Unix::Df;
 my $df= new Chj::Unix::Df;
 for my $disk ($df->disks) {
     print "Disk: '$disk'\n";
     for my $method (qw(mount device total used avail_root avail_user)) {
         print "$method: ",$disk->$method,"\n";
     }
     print "\n";
 }

=head1 DESCRIPTION

Wrapper around Filesys::DiskFree to encapsulate it better:

- temporarily changes locale before calling Filesys::DiskFree's df method

- uses two classes: Chj::Unix::Df only carries the "super cluster object",
 disks returns Chj::Unix::Df::Disk objects. Which in turn offer the real
 methods for querying a disk.

=head1 SEE ALSO

L<Chj::Unix::Df::Disk>

=cut


package Chj::Unix::Df;

use strict;
use Filesys::DiskFree;
use Chj::Unix::Df::Disk;

use Class::Array -fields=>
  'df',
  -publica=>
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    $s->df;
    $s
}

sub df {
    my $s=shift;
    ($$s[Df])= Filesys::DiskFree->new;
    local $ENV{LANG}="C";# !
    $$s[Df]->df;
}

sub disks { # NOT just a proxy to Filesys::DiskFree's disks method! But return objects that know all data. (Rewrap back this inversed thing.)
    my $s=shift;
    map {
	Chj::Unix::Df::Disk->new($$s[Df],$_)
    } $$s[Df]->disks
}

end Chj::Unix::Df;
