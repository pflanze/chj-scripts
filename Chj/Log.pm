# Sun Jul 15 11:04:22 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Log

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Log;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      logging_to
	      logging_to_fh
	      timedlogging_to
	      timedlogging_to_fh
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::xopen 'xopen_append';

sub logging_to_fh ( $ $ ; $ ) {
    my ($fh,$thunk,$do_close)=@_;
    my $maybe_closeit= sub{
    	if ($do_close) {
	    eval { $fh->xclose };
	    warn "logging_to_fh: while closing fh: $@" if (ref $@ or $@);
	}
    };
    local *STDOUT= $fh;
    local *STDERR= $fh;
    my $oldfh= select;
    select $fh; ##good idea? (or necessary?) additionally to redirecting STDOUT?
    $|++;
    my $wantarray= wantarray;
    my @rv = eval {
	$wantarray ? &$thunk : scalar &$thunk
    };
    my $e=$@;
    select $oldfh;
    if (ref $e or $e) {
	&$maybe_closeit;
	die  $e
    } else {
	&$maybe_closeit;
    }
    $wantarray ? @rv : $rv[0]
}

sub logging_to ( $ $ ) {
    my ($path,$thunk)=@_;
    logging_to_fh( xopen_append ($path), $thunk, 1)
}

# use Chj::Util::Interprocess ?

# ah one (better?) idea is: to fork off a *child to take care* of timestamping.
# and stay in the parent for the task. ok?

use Chj::xperlfunc;
use Chj::xpipe;
use Time::HiRes;

sub timedlogging_to_fh ($ $ ; $ ) {
    my ($fh,$thunk, $do_close)=@_; # note that the do_close is not so useful here: it's being closed by the logger child (and thus flushed/error-checked) *anyway*, closing it in the parent basically doesn't have any effect really.
    my ($r,$w)=xpipe;
    if (my $pid= xfork) {
	# parent
	xclose $r;
	my $wantarray=wantarray; # it's, deadly?, just so uuuugly. persistive. durchnichtive.
	my @rv= $wantarray ? logging_to_fh($w, $thunk, $do_close) : scalar logging_to_fh($w, $thunk, $do_close);
	xwaitpid $pid, 0;
	$wantarray ? @rv : $rv[0]
    } else {
	xclose $w;
	# logger process
	select $fh;
	$|++;
	while (<$r>) {
	    $_.="\\\n" unless /\n\z/; # for the last line of log.
	    # copy from bin/log-timestamp:
	    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
	    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($seconds);
	    printf '%4d-%02d-%02d %02d:%02d:%02d.%06d %s',
	      $year+1900, $mon, $mday, $hour,$min,$sec, $microseconds, $_
		or die "timedlogging_to_fh child: printing to fh: $!";
	    # /copy
	    ##btw why not mention time zone?!? bad format.
	}
	xclose $fh;
	xclose $r;
	exit (0);
    }
}

sub timedlogging_to ($ $ ) {
    my ($path,$thunk)=@_;
    timedlogging_to_fh( xopen_append ($path), $thunk, 1)
}

1
