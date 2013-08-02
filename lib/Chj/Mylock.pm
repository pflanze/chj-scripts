#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mylock

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mylock;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(new_mylock xmylock xmyunlock);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::xopen 'xopen_write';
use Chj::xtmpdir;

our $dir=xtmpdir;
our $cnt=0;

sub new_mylock {
    my $p="$dir/$$-".($cnt++);
    xopen_write ($p);
    $p
}

use Time::HiRes 'sleep';

sub xmylock {
    my ($p)=@_;
    while (1) {
	return if link $p, "$p.locked"; ## XESECURITY
	#sleep 0.0001;
    }
}

use Chj::xperlfunc;

sub xmyunlock {
    my ($p)=@_;
    xunlink "$p.locked";
}

1
