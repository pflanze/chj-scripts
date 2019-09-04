#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Mylock

=head1 SYNOPSIS

# when needing a private lock:
#my $l= new_mylock;
# Whereas when needing a shared lock, shared by path:
#my $l= $the_shared_path;

{
    xmylock $l; # waits indefinitely to get the lock

    # Stop and throw an exception after 10 seconds of waiting; will not
    # release the lock:
    #xmylock $l, 10;

    # After 10 seconds of waiting, claim the lock; don't use if there is a
    # possibility for suspended processes, or if the program can't cope with
    # half-done work by an interrupted program!
    #my $was_claimed= xmylock $l, 10, 1;
    # xmylock returns undef when getting the lock immediately, 0 when
    # getting the lock after some waiting, and an array reference of
    # lock paths when claimed after a timeout.
    # A warning is printed when claiming the lock, to disable:
    # local $Chj::Mylock::warn_claims= 0;  

    # do stuff

    xmyunlock $l;
    # If you used the version of xmylock that can claim a lock, you
    # *must* pass its return value to xmyunlock:
    #xmyunlock $l, $was_claimed;
}


# If you can afford automatic unlocking on exceptions (no risk of
# leaving behind corrupted state):

with_mylock {
    # do stuff;
    # $Chj::Mylock::was_claimed represents the return value of
    # xmylock, i.e. whether the lock was claimed.
} $l, $timeout, $do_claim_after_timeout;


# When not needing $l anymore (unlinks the file at $l):
#mylock_free $l


=head1 DESCRIPTION

Someone had told me in the early 2000's that flock wasn't
reliable. Then in 2013(?) I had a reproducible case where flock wasn't
reliable (on Linux). So I gave up and in and went with lock files (like
everybody else?). Hey, at least it only links a pre-existing file,
somewhat less overhead?

=cut


package Chj::Mylock;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(new_mylock xmylock xmyunlock mylock_free with_mylock);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Chj::xopen 'xopen_write';
use Chj::xtmpdir;
use Time::HiRes qw(sleep time);
use POSIX qw(EEXIST ENOENT);


our $verbose= 0;
sub LOG {
    print STDERR "$$: ", join(" ", map {
        if (ref $_) {
            "[".join(", ", @$_)."]"
        } else {
            $_ // "undef"
        }
    } @_), "\n"
      if $verbose;
}

our $dir=xtmpdir;
$dir->autoclean(2);
# don't warn; since used in children, too.  XXX But is it ok to remove
# there?

our $cnt=0;

sub new_mylock {
    my $p="$dir/$$-".($cnt++);
    xopen_write ($p);
    LOG("new_mylock", $p);
    $p
}


our $warn_claims= 1;

sub xmylock {
    my ($p, $maybe_timeout, $do_claim_after_timeout,
        $maybe_value_if_not_exists)=@_;
    # $maybe_value_if_not_exists is the value to be returned in case
    # $p does not exist, instead of throwing an exception.
    my $sleeptime= 200/2e9;
    my $t0;
    my $returnval= undef;
    while (1) {
        if (link $p, "$p.locked") {
            LOG("xmylock", $p, "returning:", $returnval // "undef");
            return $returnval;
        }
        $returnval= 0;
        if ($! == EEXIST) {
            if (defined $maybe_timeout) {
                if (! defined $t0) {
                    $t0= time;
                }
                my $t= time;
                if (($t-$t0) > $maybe_timeout) {
                    if ($do_claim_after_timeout) {
                        # Need to get a lock to claim it, since there
                        # can be multiple waiters all trying to claim
                        # it at the same time.

                        # And then claiming this lock can time out,
                        # too, hence, recursion. Once we've finally
                        # got a lock, we can do our work and then
                        # unlock the whole chain. Which is why xmylock
                        # returns an array of those paths, which needs
                        # to be passed to xmyunlock.

                        my $claim_lock= "$p.locked";
                        # use the same timeout, OK?
                        my $res= xmylock($claim_lock, $maybe_timeout, 1, 2);
                        if (! defined $res) {
                            # we claimed it ("Most likely" fresh
                            # allocation; XX still room for races?)
                            if ($warn_claims) {
                                require Carp;
                                Carp::carp("$$: xmylock('$p'): claiming lock after $maybe_timeout seconds");
                            }
                            LOG("xmylock", $p, "claimed it; returning:", [$claim_lock]);
                            return [$claim_lock];
                        } elsif (ref $res) {
                            # $claim_lock was stale and had to be
                            # claimed itself as well. We consider
                            # ourselves to have claimed $p now.
                            push @$res, $claim_lock;
                            LOG("xmylock", $p, "claim_lock was stale; returning:", $res);
                            return $res
                        } elsif (0 == $res) {
                            # someone else had it first and then
                            # released it, hence, *presumably* managed
                            # to claim $p themselves hence it's not us
                            # claiming it; simply retry getting $p
                            # normally now. Except still give info
                            # back that there was activity, i.e. 0
                            # again. This way, if $p is itself a
                            # claim_lock, the caller will know about
                            # the activity (pass this info on), i.e
                            # come here, too, and bubble up to do the
                            # normal call, too (no accidental
                            # claiming).
                            xmyunlock($claim_lock);
                            # ^ could optim to not even getting it?
                            # Fall through to "Retry getting $p normally".
                            LOG("xmylock", $p, "someone else claimed it (case 0)");
                        } elsif (2 == $res) {
                            #warn "claim_lock '$claim_lock' does not exist anymore";
                            # When it tries to get the parent lock
                            # normally, but doesn't exist anymore,
                            # right?
                            # Also fall through to "Retry getting $p normally".
                            LOG("xmylock", $p, "someone else claimed it (case 2)");
                        } else {
                            die "BUG";
                        }
                        # Retry getting $p normally:
                        {
                            my $res= xmylock
                                ($p, $maybe_timeout, $do_claim_after_timeout,
                                 $maybe_value_if_not_exists);
                            if (ref $p) {
                                die "xmylock('$p'): there was activity but now again stale lock -- is timeout too short?";
                            } elsif (! defined $res) {
                                return 0;
                            } elsif (0 == $res) {
                                return 0;
                            } elsif (2 == $res) {
                                return 2;
                            } else {
                                die "BUG2"
                            }
                        }
                    }
                    die "xmylock('$p', $maybe_timeout): timed out waiting for lock to be freed";
                }
            }

            $sleeptime*= 1.05;
            #$|=1; print ".";
            sleep $sleeptime;
        } elsif (defined($maybe_value_if_not_exists) and $! == ENOENT) {
            return $maybe_value_if_not_exists
        } else {
            die "xmylock('$p'): $!"
        }
    }
}

use Chj::xperlfunc;

sub xmyunlock {
    my ($p, $maybe_claim_locks)=@_;
    # XX is this order really correct?
    for (reverse @{$maybe_claim_locks || []}) {
        xunlink "$_.locked"
    }
    xunlink "$p.locked";
}

sub mylock_free  {
    my ($p)=@_;
    unlink $p
}


our $was_claimed;

sub with_mylock (&$;$$) {
    my ($thunk, $l, $timeout, $do_claim_after_timeout)= @_;
    my $wantarray= wantarray;
    my $claimed= xmylock $l, $timeout, $do_claim_after_timeout;
    local $was_claimed= $claimed;
    my @res;
    my $is_OK= eval {
        if ($wantarray) {
            @res= &$thunk();
        } else {
            @res= scalar &$thunk();
        }
        1
    };
    my $e= $@;
    xmyunlock $l, $claimed;
    die $e
        if ! $is_OK;
    $wantarray ? @res : $res[0]
}




1
