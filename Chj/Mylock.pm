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
    #xmylock $l, 10, 1;
    # xmylock returns 0 when getting the lock normally, 1 when claimed
    # after a timeout.
    # A warning is printed when claiming the lock, to disable:
    # local $Chj::Mylock::warn_claims= 0;  

    # do stuff

    xmyunlock $l;
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
use POSIX qw(EEXIST);

our $dir=xtmpdir;
$dir->autoclean(2);
# don't warn; since used in children, too.  XXX But is it ok to remove
# there?

our $cnt=0;

sub new_mylock {
    my $p="$dir/$$-".($cnt++);
    xopen_write ($p);
    $p
}


our $warn_claims= 1;

sub xmylock {
    my ($p, $maybe_timeout, $do_claim_after_timeout)=@_;
    my $sleeptime= 200/2e9;
    my $t0;
    while (1) {
	return 0 if link $p, "$p.locked";
        if ($! == EEXIST) {
            if (defined $maybe_timeout) {
                if (! defined $t0) {
                    $t0= time;
                }
                my $t= time;
                if (($t-$t0) > $maybe_timeout) {
                    if ($do_claim_after_timeout) {
                        if ($warn_claims) {
                            require Carp;
                            Carp::carp("xmylock('$p'): claimed lock after $maybe_timeout seconds");
                        }
                        return 1;
                    }
                    die "xmylock('$p', $maybe_timeout): timed out waiting for lock to be freed";
                }
            }
            
            $sleeptime*= 1.05;
            #$|=1; print ".";
            sleep $sleeptime;
        } else {
            die "xmylock('$p'): $!"
        }
    }
}

use Chj::xperlfunc;

sub xmyunlock {
    my ($p)=@_;
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
    local $was_claimed= xmylock $l, $timeout, $do_claim_after_timeout;
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
    xmyunlock $l;
    die $e
        if ! $is_OK;
    $wantarray ? @res : $res[0]
}




1
