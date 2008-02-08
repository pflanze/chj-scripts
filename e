#!/usr/bin/perl -w

# pflanze at gmx ch

use strict;
use Chj::Cwd::realpath ;
#use Chj::Lockfile;
use Chj::xsysopen 'xsysopen_append'; use Fcntl ':flock';
use Chj::Unix::exitcode;
use Chj::oerr;

$|++;

my $emacs= $ENV{EMACS_FLAVOUR} || "xemacs21";
my $gnuclient= "/usr/bin/gnuclient.$emacs";
# (There's also emacsclient.emacs21, part of emacs21 package; but that
# doesn't work on terminals afaik, or at least not in mixed X and
# terminal situations.)

my $TIMEOUT=40;
our $TIME_TO_GIVE_XEMACS= oerr($ENV{TIME_TO_GIVE_XEMACS},5); # seconds before we let any other 'e' call send anything to our beloved and hell of buggy xemacs 21.4 (patch 6)
our $verbose= $ENV{VERBOSE} ? 1 : 0;

$0=~ /([^\/]+)$/s or die "?";
my $myname=$1;
sub usage {
    print "$myname [ options ] [ files ]
  This is a wrapper around $emacs, gnuclient and screen, that starts
  one $emacs process with gnuserv if not already running and then
  uses gnuclient to attach to it.
  It allows to use just this one command to use $emacs comfortably.

  options: see options in the gnuclient manpage.

  For verbosity, set the VERBOSE environment variable to true.
  For changing the time to let xemacs alone from $TIME_TO_GIVE_XEMACS
  to something else, set the TIME_TO_GIVE_XEMACS env var accordingly.

 (This might work for all emacsen (but probably not). You may set the
 \$EMACS_FLAVOUR env var to something like 'emacs' or 'emacs-21.1';
 the default is 'xemacs21'.
  The current values are:
    emacs: '$emacs'
    gnuclient: '$gnuclient'
 ->well, actually it only works for xemacs afaik)
";
exit @_;
}

my $lockfilebase= "$ENV{HOME}/.xemacs/.e-lck.d";
my $startuplock_path= $lockfilebase."/.startuplock";
my $startuplockfh= do {
    local $^F=0;
    xsysopen_append ($startuplock_path, 0600);
};
use Carp;
sub startup_lock {
    carp "$$: trying to get lock" if $verbose;
    flock $startuplockfh,LOCK_EX
      or die "locking: $!";
    carp "$$: got lock" if $verbose;
}
sub startup_unlock {
    carp "$$: releasing lock" if $verbose;
    flock $startuplockfh,LOCK_UN or die "??unlock: $!";
}
#und fun warum backtrace von carp?. heut geht wieder mal nichts deterministisch.

my $nw;
for (my $i=0; $i<=$#ARGV; $i++) {
    local $_=$ARGV[$i];
    if (/^--?h(elp)?$/) {
        usage
    } elsif (/^-nw$/) {
        $nw=1;
    }
}


sub reachable {
    warn "$$ checking reachability.." if $verbose;
    my $p=fork;
    defined $p or die "Could not fork: $!";
    my $res= do {
	if ($p){
	    wait;
	    $? == 0;
	} else {
	    unless ($verbose) {
		open STDOUT,">/dev/null";
		open STDERR,">/dev/null";
	    }
	    alarm 3; # does this hold over to after the exec? yes.
	    exec $gnuclient, qw(-batch -eval t);
	    exit 2;
	}
    };
    warn "$$ reachability check gave ".($res ? "true":"false") if $verbose;
    $res
}

sub rungnuclientwithargs {
    alarm 0; # switch off previously set up alarms. #hacky?
    my @args;
    for (@ARGV) {
	push @args, do {
	    if (/^-/) {
		$_;
	    } else {
		realpath($_) or $_
	    }
	};
    }
    my $p=fork;
    defined $p or die "Could not fork: $!";
    if ($p) {
	# now either we return soon enough to justify holding on to
	# the lock, or just unlock after that certain time:
	$SIG{ALRM}= sub {
	    alarm 0;
	    startup_unlock;
	};
	alarm $TIME_TO_GIVE_XEMACS;
	wait;
	# does the alarm make us continue w/o having really waited? (I think perl does reenter, right?)
	warn "$$ returned from wait for gnuclient" if $verbose;
	# propagate errors --- OLD missing stuff...
	if ($? == 0) {
	    exit 0
	} else {
	    warn "$myname: gnuclient exited with ".exitcode($?)."\n";
	    exit 1;
	}
    } else {
	exec $gnuclient, @args;
    }
}

my $tty;
if (!$ENV{DISPLAY} or $nw) {
    $ENV{TERM}="linux"; #if $ENV{TERM} eq "xterm";
    # check/create display lock file: (this is independent from startup lock!)
    unless (-d $lockfilebase) {
	mkdir $lockfilebase,0700
	  or die "$myname: could not create base dir for lock files '$lockfilebase': $!\n";
    }
    $tty=`/usr/bin/tty`; chomp $tty;
    $tty=~ s/\//-/sg;
    my $linkfile= "$lockfilebase/$tty";
    if (my $pid=readlink $linkfile){
	if (kill 0,$pid){
	    die "$myname: you have already an emacs frame running on this terminal.\n";
	} else {
	    unlink $linkfile
	      or die "$myname: could not unlink stale '$linkfile': $!\n";
	}
    }
    if (! -f "$lockfilebase/.lastcleanup" or  -M _ > 1/100) { # 100 per day
	opendir DIR,$lockfilebase  or die "opendir: $!";
	while (defined ($_=readdir DIR)){
	    next if $_=~/^\./;
	    my $l= "$lockfilebase/$_";
	    if (my $pid=readlink $l){
		if (kill 0,$pid){
		    # leave it there
		} else {
		    unlink $l
		      or warn "$myname: could not unlink stale '$l': $!\n";
		}
	    }
	}
	closedir DIR;
	open OUT,">$lockfilebase/.lastcleanup" or die $!; print OUT "~";close OUT;
    }
    symlink "$$",$linkfile or die "$myname: could not create symlink $linkfile: $!\n";
}

$SIG{ALRM}= sub {
    die "ALRM\n";
};
alarm $TIMEOUT;
eval {
    startup_lock; #this and the above 5 lines and the catching should of course be abstracted away.
    if (reachable) { #btw we're (still) getting a second chance, starting it on our own here.. (we're using two approaches for 'waiting' for the emacs server process hehe)
	#alarm 0;#!!
	rungnuclientwithargs;
    } else {
	require Chj::ulimit;
	Chj::ulimit::ulimit("-S","-v",200000);
	0==system "screen","-d","-m",$emacs,"-nw","-f","gnuserv-start"
	  or die "screen returned exit code $?";
	my $z=0;
	do {
	    sleep 1;
	    $z++ > ($TIMEOUT - 5)
	      and die "Timeout waiting for $emacs to start up. Maybe you can still attach to it with screen -r .. (screen -ls for the list of screens).\n";
	} until reachable;
	#alarm 0;#!!
	rungnuclientwithargs;
    }
};
if (ref $@ or $@) {
    if ($@ eq "ALRM\n") {
	die "$myname ($$): timed out waiting for lock (another process supposedly starting up xemacs)\n";
    } else {
	die $@
    }
}
