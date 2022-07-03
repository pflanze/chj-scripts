# Fri Oct 22 20:04:10 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::Stamp

=head1 SYNOPSIS

=head1 DESCRIPTION

 my $s= Chj::FileStore::Stamp->new("/some/where");
 $s->mtime; # return current mtime, undef if not exists. dies on error (perms etc).
 $s->xtouch; # touch item to current time, die if not possible.

=cut


package Chj::FileStore::Stamp;

use strict;
use Errno 'ENOENT';
use Carp;

use Class::Array -fields=> (
			    'Path',
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    ($$self[Path])=@_;
    $self
}

sub mtime {
    my $s=shift;
    if (defined(my $mtime=(stat $$s[Path])[9])) {
	$mtime
    } else {
	if ($! == ENOENT) {
	    undef
	} else {
	    croak "mtime: stat('$$s[Path]'): $!";
	}
    }
}

sub exists {
    my $s=shift;
    defined $s->mtime
}

use Fcntl;

sub xtouch {
    my $s=shift;
    my ($maybe_perms)=@_;
    # be safe for manipulations by root at least in the 'dead' case
    # (stopped vserver clients), by being careful handling symlinks
    # (checking for symlinks in dirname(Path) is the responsibility of
    # the user, though)
    if (-l $$s[Path]) {
	die "path exists as a symlink already: '$$s[Path]'";
    }
    elsif (-f _) {
	my $t=time;
	utime $t,$t, $$s[Path]
	  or croak "xtouch: utime('$$s[Path]'): $!";
    }
    else {
	sysopen O,$$s[Path], O_WRONLY|O_EXCL|O_CREAT,
	  (defined $maybe_perms ? $maybe_perms : 0)
	    or croak "xtouch: open('$$s[Path]'): $!";
	close O or croak "xtouch: close of '$$s[Path]': $!";
    }
}


1;
