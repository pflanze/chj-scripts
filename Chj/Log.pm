# Sun Jul 15 11:04:22 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Log

=head1 SYNOPSIS

 use Chj::Log ':all';

 timedlogging_to "my/logfile.log", sub () { ... };

 # there are also the functions:
 #  logging_to
 #  logging_to_fh
 #  timedlogging_to_fh

=head1 DESCRIPTION

logging_to* just remap stdout and stderr to the given log file path or
fh. timedlogging_to* creates a pipe and forks off a detached child
which prepends timestamps before writing to the given log.

timedlogging_to* also append "\\\n" if the pipe is being closed and
the last record didn't end in a newline.

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
use POSIX 'setsid';

sub timedlogging_to_fh ($ $ ; $ ) {
    my ($fh,$thunk, $do_close)=@_; # note that the do_close is not so useful here: it's being closed by the logger child (and thus flushed/error-checked) *anyway*, closing it in the parent basically doesn't have any effect really.
    my $wantarray=wantarray; # it's, deadly?, just so uuuugly. persistive. durchnichtive.
    my ($r,$w)=xpipe;
    if (my $pid= xfork) {
	# parent
	my @rv= eval {
	    xclose $r;
	    xclose $fh if $do_close;
	    ( $wantarray ?
	      logging_to_fh($w, $thunk, 1)
	      : scalar logging_to_fh($w, $thunk, 1) )
	};
	my $e=$@;
	if (ref $e or $e) {
	    waitpid $pid, 0 or warn "timedlogging_to_fh note: waitpid $pid: $!";
	    die $e;
	} else {
	    xwaitpid $pid, 0;
	    $?==0 or die "timedlogging_to_fh: logger process got an error (exit code $?)";
	    $wantarray ? @rv : $rv[0]
	}
    } else {
	# logger process
	eval { # need this, or it will escape to another handler!! and not even exit!
	    xclose $w;

	    # prevent getting sigint's
	    setsid or die $!;

	    # detach from other stuff
	    close STDIN; close STDOUT; close STDERR;
	    chdir "/";

	    # autoflush on, and why not just use printf instead of print $fh sprintf:
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
	};
	exit (1);
    }
}

sub timedlogging_to ($ $ ) {
    my ($path,$thunk)=@_;
    timedlogging_to_fh( xopen_append ($path), $thunk, 1)
}

1
