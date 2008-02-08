#!/usr/bin/perl -w

# pflanze at gmx ch

use strict;
use Chj::Cwd::realpath ;

my $emacs= $ENV{EMACS_FLAVOUR} || "xemacs21";
my $gnuclient= "/usr/bin/gnuclient.$emacs";
# (There's also emacsclient.emacs21, part of emacs21 package; but that
# doesn't work on terminals afaik, or at least not in mixed X and
# terminal situations.)

$0=~ /([^\/]+)$/s or die "?";
my $myname=$1;
sub usage {
    print "$myname [ options ] [ files ]
  This is a wrapper around $emacs, gnuclient and screen, that starts
  one $emacs process with gnuserv if not already running and then
  uses gnuclient to attach to it.
  It allows to use just this one command to use $emacs comfortably.

  options: see options in the gnuclient manpage.

 (This should work for all emacsen. You may set the \$EMACS_FLAVOUR
  env var to something like 'emacs' or 'emacs-21.1'; the
  default is 'xemacs21'.
  The current values are:
    emacs: '$emacs'
    gnuclient: '$gnuclient'
 ->well, actually it only works for xemacs afaik)
";
exit @_;
}

my $lockfilebase= "$ENV{HOME}/.xemacs/.e-lck.d";
my $startuplock= $lockfilebase."/.startuplock";

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
    my $p=fork;
    defined $p or die "Could not fork: $!";
    if ($p){
        wait;
    } else {
        open STDOUT,">/dev/null";
        open STDERR,">/dev/null";
        exec $gnuclient, qw(-batch -eval t);
        exit 2;
    }
    $? == 0;
}

sub rungnuclientwithargs {
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
    exec $gnuclient, @args;
}

my $tty;
if (!$ENV{DISPLAY} or $nw) {
    $ENV{TERM}="linux"; #if $ENV{TERM} eq "xterm";
    # check/create lock file:
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
	    unlink $linkfile or die "$myname: could not unlink stale '$linkfile': $!\n";
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
		    unlink $l or warn "$myname: could not unlink stale '$l': $!\n";
		}
	    }
	}
	closedir DIR;
	open OUT,">$lockfilebase/.lastcleanup" or die $!; print OUT "~";close OUT;
    }
    symlink "$$",$linkfile or die "$myname: could not create symlink $linkfile: $!\n";
}

if (reachable) {
    rungnuclientwithargs;
} else {
    require Chj::ulimit;
    Chj::ulimit::ulimit("-S","-v",200000);
    0==system "screen","-d","-m",$emacs,"-nw","-f","gnuserv-start"
      or die "screen returned exit code $?";
    my $z=0;
    do {
        sleep 1;
        $z++ > 40 and die "Timeout waiting for $emacs to start up. Maybe you can still attach to it with screen -r .. (screen -ls for the list of screens).\n";
    } until reachable;
    rungnuclientwithargs;
}
