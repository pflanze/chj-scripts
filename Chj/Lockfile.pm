# Mon Aug 13 14:15:56 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Lockfile

=head1 SYNOPSIS

=head1 DESCRIPTION

 use Chj::Lockfile;
 {
    my $lock= Chj::Lockfile->get("path/to/foo" [, 0600 ] ); # permissions. optional. umask masked.
    ...critical section...
 }

=head1 METHODS

=over 4

=item new(path, [perms])

constructor

=item get(path, [perms])

constructor which calls lock_ex right away

=item try_get(path, [perms])

constructor which calls try_lock_ex right away, and if returning false, retruns false.

=item lock (flags)

locks with the given flags

=item lock_ex ()

lock with LOCK_EX, block until granted.

=item try_lock_ex ()

lock with LOCK_EX|LOCK_NB, return 0 or 1 depending on whether the lock
was granted or not.

=back

=cut


package Chj::Lockfile;

use strict;

use Chj::xsysopen ();
use Fcntl ':flock';
use Carp ();

use Class::Array -fields=>
  -publica=>
  #'maybe_mode', hm really?
  'fh',
  'verbose';
  ;

our $verbose=0;

sub new {
    my $class=shift;
    my ($path,$maybe_mode)=@_;
    my $s= $class->SUPER::new;
    $$s[Fh]= Chj::xsysopen::xsysopen_append($path,$maybe_mode);#ok?
    $s
}

sub get {
    my $class=shift;
    Carp::croak ("get is a constructor method but was called on an object: ", $class)
	if ref $class;
    # well perl would just die anway, with 'Attempt to bless into a reference at ... Class/Array.pm line 560' hm well. so that's why I do it here explicitely. chaos everywhere.
    my $s= $class->new(@_);
    $s->lock_ex;
    $s
}

sub try_get {
    my $class=shift;
    Carp::croak ("get is a constructor method but was called on an object: ", $class)
	if ref $class;
    my $s= $class->new(@_);
    $s->try_lock_ex and $s
}


sub lock {
    my $s=shift;
    @_==1 or Carp::croak "expecting 1 argument";
    my ($flags)=@_;
    my $res;
    my $is_nb= $flags & LOCK_NB;
    my $action= sub {
	my $res= flock ($$s[Fh], $flags);
	if ($is_nb) {
	    $res
	} else {
	    $res or die "can't get lock on ".$$s[Fh]->path.": $!";
	}
    };
    if ($s->verbose) {
	my $msg= $is_nb ? "trying to get" : "getting";
	print STDERR "$msg lock $s (".$$s[Fh]->path.")..";
	my $res= &$action;
	if ($res) {
	    print STDERR "got it.\n";
	} else {
	    # must be $is_nb because otherwise we'd have died already
	    print STDERR "can't get it right now.\n";
	}
	$res
    } else {
	&$action
    }
}

# could add lock_sh and unlock operations if wanted.
# atm it's unlocked when released (because of closing).

sub Mk {
    my ($flags)=@_;
    sub {
	my $s=shift;
	$s->lock ($flags)
    }
}

*lock_ex= Mk (LOCK_EX);
*try_lock_ex= Mk (LOCK_EX | LOCK_NB);


sub verbose {
    my $s=shift;
    if (defined $$s[Verbose]) {
	$$s[Verbose]
    } else {
	$verbose
    }
}

sub DESTROY {
    my $s=shift;
    if ($s->verbose) {
	print STDERR "releasing lock $s (".$$s[Fh]->path.")\n"
    }
}

end Class::Array;

__END__

HMM todo find out what's the problem with this:

calc> :l { my $l= new Chj::Lockfile "Hallo"; $l->lock_ex ; 0 }
0
calc> :l { my $l= get Chj::Lockfile "Hallo"; 0 }
0
these are ok, release the lock at the end of the scope

calc> :l $l= new Chj::Lockfile "Hallo"
Chj::Lockfile=ARRAY(0x84c2298)
calc> :l $l->lock_ex
Chj::Lockfile=ARRAY(0x84c2298)
calc> :l undef $l

this does not release it. even after subsequent
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1

where could it be hanging on ?

{Tue Nov  4 20:08:03 2008}
  ps. funny:
  calc> :l $lock= Chj::Lockfile->try_get("kuaewfewadsfsadfdsre")
  Chj::Lockfile=ARRAY(0x825c918)
  calc> :l $lock= Chj::Lockfile->try_get("kuaewfewadsfsadfdsre")
  0

  i.e. nonblocking lock returns 0 if we have it already.

  but

  calc> :l $lock= Chj::Lockfile->new("kuaewfewadsfsadfdsre")
  Chj::Lockfile=ARRAY(0x825c510)
  calc> :l $lock->try_lock_ex
  1
  calc> :l $lock->try_lock_ex
  1

  i.e. will always return 1.

  (no brain spare cycles right now to think about whether that's inconsistent.
  this is on 2.6.22.18, perl v5.8.7, anyway)
