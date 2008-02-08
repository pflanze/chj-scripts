#!/usr/bin/perl -w

# Mon, 24 Jun 2002 00:50:07 +0200
# Sun,  2 Feb 2003 19:53:20 +0100: bugfixes. Hab ichs so lange ausgehalten.
# Tue, 08 Nov 2005 22:20:20 +0100: ulimit
# pflanze at gmx ch

use strict;
use Chj::Cwd::realpath ;

my $emacs= $ENV{EMACS_FLAVOUR} || "xemacs21";
my $gnuclient= "/usr/bin/gnuclient.$emacs";

# hmmm da gibts noch  emacsclient.emacs21  als Teil von emacs21 paket. aber wie verwenden?

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
    # cj 3.02.2003 as well, curing second bug:  for some damn reason TERM is set to xterm under gnome-terminal/whatever. Maybe the X startup sequence sets it. Logging in on a console gives linux. Which is what also works correctly with 8bit keycodes in gnome-terminal.
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
=pod
    my $pid=fork; defined $pid or die "$myname: could not fork: $!\n";
    if ($pid){
    # trap signals; interessant: das STOP kriegt nur der emacs? ah. Der "fangt" es ja auch ab?
    $SIG{TERM}=$SIG{INT}=sub{ warn "e: got a signal\n" };# damit wenn erstesmal C-Z, dann C-C, nicht weggeht.
#   $SIG{STOP}= sub{kill 19,$pid; kill 19,$$};
    #   $SIG{CONT}= sub{kill 18,$pid};
    $SIG{CHLD}= sub { #wait; warn "e: got rv $?\n";  # hmmm, how to get stopped child notifications in perl?    wie?   signal krieg ich ja.  welches?  vielleicht geht waitpid(-1,WNOHANG);?   AAAH: waitpid($thekid,WNOHANG|WUNTRACED)
        kill 19,$$
    }; # this makes C-Z in xemacs work (the parent is then stopped as well)
    symlink "$$",$linkfile or die "$myname: could not create symlink $linkfile: $!\n";
    wait;
    unlink $linkfile;# or warn "$myname: could not unlink '$linkfile': $!\n";
    exit;
    }
    # else go on
=cut
  # so it does not work that well from perl. Instead, do periodic cleanups.
  # well es würd schon gehn mit WUNTRACED aber iss ja nun egal.
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
    if ($ENV{DISPLAY} and !$nw) {
        #system $emacs.' -unmapped -f gnuserv-start &';   2.2.2003: will make xemacs21 crash and eat 100% cpu if the X connection is interrupted later on (and one *has* to interrupt it since just closing all frames does not close it). So:
        #my $dis=$ENV{DISPLAY}; delete $ENV{DISPLAY}; eh gar ned nötig
        0==system "screen","-d","-m",$emacs,"-nw","-f","gnuserv-start"
          or die "screen returned exit code $?";
        #$ENV{DISPLAY}=$dis;
    } else {
        # Use something to detach the emacs process as server:

        # rely on $HOME? should be ok for me, I always do 'su -' or 'sux -'. But NO. Yust do jt r8t.
        #my $dir= (getpwuid($>))[7];
        #$dir= "$dir/.e-macsstarter";
        #mkdir $dir,0700;
        #if ($!=~/exist/) {
        #   ((stat $dir)[2] & 07777) == 0700 or die "Directory '$dir' has wrong permissions.\n";
        #} elsif ($!) {
        #   die "Couldn't create dir '$dir': $!\n";
        #}
        #unlink "$dir/$$" and warn "Huh, there was a preexisting '$dir/$$' socket/file.\n";
        #system "detachtty", "$dir/$$", $emacs, @ARGV;
        # Note: attachtty doesn't seem to work on my system (ctrl chars don't make it
        # through it). So this is rather bullshit, and /dev/null would be as good if
        # xemacs wouldn't croak about it.
        #No, worse, on debian powerpc even detachtty is absolutely broken in several respects.

        # So just use proven 'screen' instead:
        0==system "screen","-d","-m",$emacs,"-nw","-f","gnuserv-start"
          or die "screen returned exit code $?";

    }
    my $z=0;
    do {
        sleep 1;
        $z++ > 20 and die "Timeout waiting for $emacs to start up. Maybe you can still attach to it with screen -r .. (screen -ls for the list of screens).\n";
    } until reachable;
    rungnuclientwithargs;
    ## so ein tubelprogramm, das gibt nicht mal einen fehlercode wenn es keine Bildschirmdarstellung machen kann weil permissions des /dev/pts/* nicht stimmen. Klar, zum xemacs connecten kann es schon aber es bricht gleich wieder ab, so what.
}

__END__
  Wie rausfinden ob schon einer läuft?
  lsof?
  Der gnuclient macht die device connections.
  zu langsam.
Wie pid kriegen? und ist immer selbige. Meine eigene skript pid, gnuclient bleibt wenn so, oder?
Ohne aufräumparent?  Problem, am schluss gibts fur jede pid ein file, dann muss ich wieder genauso präzis rausfinden ob da ein gnuclient prozess ist oder nicht.  Periodisch aufräumen?ist das next best.
