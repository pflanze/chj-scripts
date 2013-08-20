#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Mylock

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mylock;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(new_mylock xmylock xmyunlock mylock_free);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::xopen 'xopen_write';
use Chj::xtmpdir;

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
