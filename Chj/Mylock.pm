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

xmylock $l;
# do stuff
xmyunlock $l;

=head1 DESCRIPTION

Someone had told me in the early 2000's that flock wasn't
reliable. Then in 2013(?) I had a reproducible case where flock wasn't
reliable (on Linux). So I gave up and in and went with lock files (like
everybody else?). Hey, at least it only links a pre-existing file,
somewhat less overhead?

=cut


package Chj::Mylock;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(new_mylock xmylock xmyunlock mylock_free);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';
use Chj::xopen 'xopen_write';
use Chj::xtmpdir;
use POSIX qw(ENOENT);

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

use Time::HiRes 'sleep';

sub xmylock {
    my ($p)=@_;
    my $sleeptime= 200/2e9;
    while (1) {
	return if link $p, "$p.locked";
        if ($! == ENOENT) {
            die "xmylock('$p'): $!"
        }
	$sleeptime*= 1.05;
	sleep $sleeptime;
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

1
