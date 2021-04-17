package Chj::backtick;

# Sun Jan 27 05:06:26 2002  Christian Jaeger, pflanze@gmx.ch
# / Fri,  8 Feb 2002 19:45:57 +0100
#
# Copyright 2001/2002 by ethlife renovation project people
# (christian jaeger, cesar keller, philipp suter, peter rohner)
# Published under the terms of the GNU General Public License
#
# $Id: backtick.pm,v 1.9 2002/05/08 01:01:55 chris Exp $

# Mon, 22 Sep 2003 15:18:20 +0200: renamed from backtick to Chj::backtick namespace.


=head1 NAME

Chj::backtick - utility functions for dealing with subprocesses

=head1 SYNOPSIS

 use Chj::backtick qw( xfork xsystem xexec xbacktick xputget );
 if (xfork) {
 } else {
    xexec @cmd;
 }
 xsystem @cmd
    or die "Subprocess returned $?";
 for (xbacktick("ls","-l")) {  }
 my ($stdout,$stderr)=("","");
 xputget( [$newpw."\n",$newpw."\n"], ["passwd",$user], $stdout,$stderr, 4,0,0,1)
    or die "Subprocess returned $?";

=head1 DESCRIPTION

Some standard perl functions like the backticks are prone to risks because they 
always interpret the argument instead of allowing a command & argument list.

If you want to pass data over stdout to the subprocess and don't want to
write the routine youself, and don't want to load the heavy Expect.pm (takes about 0.5 seconds to load on my 
laptop), use '[x]putget'. No more worries about blocking, signals (almost), timeouts.

Additionally, if you find it tiresome to always check the return value of functions like
system or fork for the undefined value and instead would like to just get an exception,
xfork, xsystem, xexec as well as xbacktick and xputget are for you.

=head1 FUNCTIONS

=over 4

=item xfork

Returns either 0 or the pid of the child. Never returns undef, croaks if it can't fork.

=item xsystem $cmd[, @args]

Same as system, but croaks if it can't execute the command.

=item xexec $cmd[, @args]

Same as exec, but croaks if it didn't exec.

=item backtick $cmd[, @args]

Same as ` `, but allows to give an array of arguments.

=item xbacktick $cmd[, @args]

Same as backtick, but croaks if it couldn't execute the command.

=cut

require Exporter;
@EXPORT_OK= qw(
    xfork xsystem xexec
    backtick xbacktick
    putget xputget
);
@ISA=qw(Exporter);

use strict;
use utf8;
use Carp; # load time?
use Fcntl; # 30ms
use POSIX qw(WNOHANG EINTR EPERM); #":sys_wait_h"; # not *that* costly, ~50ms, versus 150ms of vectolist;

sub MAGICANTICODE() { 232 };
sub DEBUG() {0};

sub xfork {
    my $pid=fork;
    defined $pid or croak "xfork: Could not fork: $!";
    $pid;
}

sub xsystem {
   local $^W; # so that no warning is printed before we print the correct location of the code
   my $rv= system @_;
   $rv==-1 and croak "xsystem: Could not execute '$_[0]': $!";
   $rv
}

sub xexec {
    eval {
        exec @_;
    };  # hrm, the eval kludge is just so it doesn't warn me with 'Statement unlikely to be reached' :S
    croak "xexec: could not execute '$_[0]': $!";
}

sub xbacktick {
    local $^F=1000;
    pipe OUTR,OUTW;
    if (xfork) {
        close OUTW;
        if (wantarray) {
            my @buf= <OUTR>;
            wait;
            close OUTR;
            croak "Could not exec '$_[0]'" if $? >> 8 == MAGICANTICODE;
            @buf;
        } else {
            local $/;
            my $buf= <OUTR>;
            wait;
            close OUTR;
            croak "Could not exec '$_[0]'" if $? >> 8 == MAGICANTICODE;
            $buf;
        }
    } else {
        close OUTR;
        open STDOUT,">&".fileno(OUTW) or die "Could not dup: $!";
        eval {
            xexec @_;
        }; 
        carp $@;
        exit(MAGICANTICODE);
    }
}

sub backtick {
    return eval {
        xbacktick(@_)
    };
    # no need to print $@ since this has been done anyway
}


=item putget ($send, \@cmd, $stdout, $stderr, [ $timeout, $waitforout, $waitforerr, $waitforoutput, $sleepbetweensends])

Executes cmd and arguments in a subproces, feeds it $send through stdin
and fetches it's output in the $stdout and $stderr variables (they can be the same
variable). Optional arguments:

 timeout     if defined, requests the subprocess to be terminated
             after $timeout (floatingpoint value) seconds
 waitforout  if 1, lets putget wait for anything to appear on
             stdout before sending out the send buffer.
             #if it's a compiled regex (qr//), waits until the output
             #meets the regex. -> not yet implemented.
 waitforerr  same thing for stderr
 wairforoutput  same thing, but send out the buffer upon receipt of
             output on any of stderr or stdout.
 #sleepbetweensends  (floating) seconds to wait between sending of 
             #the individual array elements in case $send is an 
             #array ref.  -> not yet implemented.

Caveats:

 - Does not yet support array refs for stdout and stderr.

=item xputget ...

Same as putget but croaks if it can't execute the command or times out.

=cut

# NOTE to myself: test i.e. with  substr($r,0,1)eq"(" for a qr compiled regexp.


my $initialized;

sub _nonblock {
    my $fh= shift;
    my $flags= fcntl($fh, F_GETFL,0) or die "Can't get flags: $!";
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK) or die "Can't set flags: $!";
}

sub xputget {
    my ($sendref,$cmdref,$stdoutref,$stderrref,
        $timeout,$waitforout,$waitforerr,$waitforoutput,
        $sleepbetweensends) =   ## sleepbetweensends noch nich implementert
        (\$_[0], $_[1], \$_[2], \$_[3], 
        $_[4], $_[5], $_[6], $_[7],
        $_[8] );

    #local $SIG{__DIE__}; # really needed?.. (antihack)(hmm should put this everywhere?..)
    local $^F=10000; # yes it is needed; hope there's no system that croaks on this number.
    pipe PUTR,PUTW; # should be in our namespace so no problem.
    pipe GETR,GETW;
    pipe ERRR,ERRW;
    if (my $pid=xfork) {
        # keep PUTW, GETR, ERRR
        close PUTR;close GETW;close ERRW;
        eval{
            _nonblock(*PUTW{IO});
            _nonblock(*GETR{IO});
            _nonblock(*ERRR{IO});
            my ($rmask,$wmask,$emask)= ("","","");
            vec($rmask,fileno(GETR),1)=1;
            vec($rmask,fileno(ERRR),1)=1;
            vec($emask,fileno(GETR),1)=1;
            vec($emask,fileno(ERRR),1)=1;
            my $flag_wneedsswitchon;
            my $PUTWfileno= fileno(PUTW); # just to be sure we can remove the handle from the bitmask in any case (should it be that a filehandle can disappear)
            if ($waitforout||$waitforerr||$waitforoutput) {
                $flag_wneedsswitchon=1;
            } else {
                vec($wmask,fileno(PUTW),1)=1;
                vec($emask,fileno(PUTW),1)=1;
            }
            my $gotsigpipe;
            my $oldsigpipe= ref $SIG{PIPE} ? $SIG{PIPE} : undef;
            my $newsigpipe;
            $newsigpipe=  # might be needed on some systems
            local $SIG{PIPE}= sub { $gotsigpipe=1;
                &$oldsigpipe(@_) if $oldsigpipe;
                $SIG{PIPE}= $newsigpipe; # might be needed on some systems
            }; # is there any way to switch off sigpipe creation on the pipes?
            #my $gotsigchld;
            #local $SIG{CHLD}= sub { $gotsigchld=1;
            #};  currently we are using waitpid instead, which allows us to leave the signal handler from users untouched. Alternatively: set up sig handler that checks whether it's our child, if not, calls the previous handler code.
            my ($rmaskout,$wmaskout,$emaskout);
            my $res;
            my $buf;
            # Output mechanism decisions:
            my $sendi; # if defined, an ARRAY has been given.
            my ($outputref,$outputlen); # outputref is ref to current output buffer
            my $outputpos=0;
            if (ref $$sendref) {
                if (ref ($$sendref) eq 'ARRAY') {
                    $sendi=0;
                    $outputref= \(${$sendref}->[0]);
                } elsif (ref ($$sendref) eq 'SCALAR') {
                    $outputref= $$sendref;
                }
            } else {
                $outputref= $sendref;
            }
            $outputlen= length($$outputref);
            my ($starttime,$resttime);
            if ($timeout) {
                $starttime= time();
                $resttime= $timeout;
            }
            LOOP: {
                $res= select($rmaskout=$rmask, $wmaskout=$wmask, $emaskout=$emask, $resttime);
                warn "DEBUG back from select" if DEBUG;
                if ($res==0) {# timeout
                    warn "DEBUG Timeout" if DEBUG;
                } elsif ($res>0) {

                    # check errors
                    if (vec($emaskout,fileno(GETR),1)) {
                        warn "Got error on GETR";
                    }
                    if (vec($emaskout,fileno(ERRR),1)) {
                        warn "Got error on ERRR";
                    }
                    if (vec($emaskout,$PUTWfileno,1)) {
                        warn "Got error on PUTW";
                    }

                    # check receive
                    if (vec($rmaskout,fileno(GETR),1)) {
                        sysread GETR,$buf,100000;
                        if ($flag_wneedsswitchon and ($waitforoutput or 
                                ($waitforout and not($waitforerr) || length($$stderrref) )  )) {
                            warn "DEBUG: switch PUTW on because we got stdout '$buf'" if DEBUG;
                            vec($wmask,fileno(PUTW),1)=1;
                            vec($emask,fileno(PUTW),1)=1;
                            $flag_wneedsswitchon=0;
                        }
                        $$stdoutref.=$buf; # needs to be *after* the length check above, since $stderr could be $stdout
                    }
                    if (vec($rmaskout,fileno(ERRR),1)) {
                        sysread ERRR,$buf,100000;
                        if ($flag_wneedsswitchon and ($waitforoutput or 
                                ($waitforerr and not($waitforout) || length($$stdoutref) )  )) {
                            warn "DEBUG: switch PUTW on because we got stderr '$buf'" if DEBUG;
                            vec($wmask,fileno(PUTW),1)=1;
                            vec($emask,fileno(PUTW),1)=1;
                            $flag_wneedsswitchon=0;
                        }
                        $$stderrref.=$buf; # see above
                    }

                    # check send
                    if (vec($wmaskout,$PUTWfileno,1)) {
                        my $cnt= syswrite PUTW, substr($$outputref,$outputpos);;
                        if (defined $cnt) { 
                            warn "DEBUG wrote $cnt bytes" if DEBUG;
                            $outputpos+= $cnt;
                            if ($outputpos >= $outputlen) {
                                FINISH: {
                                    if (defined $sendi) {
                                        if (++$sendi <= $#${$sendref}) {
                                            warn "DEBUG go to next element in ARRAY" if DEBUG;
                                            $outputref= \(${$sendref}->[$sendi]);
                                            $outputpos=0;
                                            $outputlen= length($$outputref);
                                            last FINISH;
                                        }
                                    }
                                    # finished.
                                    warn "DEBUG finished writing." if DEBUG;
                                    $wmask= "";
                                    vec($emask,$PUTWfileno,1)=0;
                                    close PUTW;
                                }
                            }
                        } else {
                            if ($gotsigpipe) {
                                # pretty sure the error is "broken pipe"
                            } else {
                                warn "I/O error trying to write to child: $!";
                            }
                            $wmask= "";
                            vec($emask,$PUTWfileno,1)=0;
                            close PUTW;
                        }
                    }

                } elsif ($!==EINTR) {
                    redo LOOP;
                } else {
                    die "Error on select: $!";
                }

                my $terminatedpid= waitpid ($pid, WNOHANG);
                if ($terminatedpid == 0) { ## "on *some* systems" :((... (perldoc -f waitpid)
                    # none finished
                    unless ($timeout) {
                        warn "DEBUG näxte Runde.." if DEBUG; 
                        redo LOOP;
                    }
                    $resttime= $timeout + $starttime - time();
                    if ($resttime > 0) {
                        warn "DEBUG näxte Runde.." if DEBUG; 
                        redo LOOP;
                    } else {
                        #carp "Timeout";
                        my $oldsigchld= $SIG{CHLD};
                        eval {
                            local $SIG{CHLD}= sub { die "CHLD\n" }; 

                            # fetch the rest from the filehandles and close them. This helps for 'passwd'.
                            # -> have moved this now to *before* the signals, since flow is easier this way :)  (should really try to kill, if fails, close fh's, then if child there, kill again (if fails -> die), wait, KILL. But then maybe it's better to just close them first anyway.
                            warn "DEBUG going to close filehandles" if DEBUG;
                            close PUTW;
                            sysread GETR,$buf,10000000 and $$stdoutref.=$buf;
                            sysread ERRR,$buf,10000000 and $$stderrref.=$buf;
                            close GETR; close ERRR; # this is the only place to close them redundantly before the end of the LOOP. hrm.
                            select (undef,undef,undef,1);

                            warn "DEBUG going to TERM/HUP/ABRT/QUIT child $pid" if DEBUG;
                            kill 'TERM',$pid or do { # why, is child not there?
                                if ($! == EPERM) {
                                    croak "Timeout, and can't kill the child because of $!";
                                } else {
                                    # child not there anymore anyway.
                                    return # from eval
                                }
                            };
                            kill 'HUP',$pid;
                            kill 'QUIT',$pid;
                            #kill 'ABRT',$pid; # the only one that terminates 'passwd'. But this seems to be usually used to dump cores.

                            select (undef,undef,undef,5);
                            warn "DEBUG going to KILL child $pid" if DEBUG;
                            kill 'KILL',$pid;
                        };#/eval
                        if ($@) {
                            if (!ref($@) and $@ eq "CHLD\n") { # !ref is needed for some overloaded exception objects. And yes it can happen if one uses such things in ALRM's
                                warn "DEBUG trapped sigchld" if DEBUG;
                                # reap it
                                waitpid($pid,WNOHANG) > 0 or warn "putget: Could not reap subprocess $pid";
                                &{$oldsigchld}('CHLD') if $oldsigchld;# :( the only way to be polite to users of our library is to re-signal *anyway*, since there could have been multiple children deaths at the same time.
                            } else {
                                die $@;
                            }
                        }
                        #last LOOP;
                        croak "Timeout";
                    }
                } else {
                    # our child has finished.
                    warn "DEBUG: child $terminatedpid has exited" if DEBUG;
                    last LOOP;
                }
            } # /LOOP
            warn "DEBUG: habe LOOP verlassen" if DEBUG;
            # read the rest from the filehandles. This needs to be done after the waitpid (?).
            sysread GETR,$buf,10000000 and $$stdoutref.=$buf; # filehandles might already be closed here (see Timeout).
            sysread ERRR,$buf,10000000 and $$stderrref.=$buf;
        };# /eval
        close PUTW; # just to be sure.
        close GETR; close ERRR;
        die $@ if $@;
        croak "Could not exec '$cmdref->[0]'" if $? >> 8 == MAGICANTICODE;
        return $?; # (do it like system)
    } else {
        # keep PUTR, GETW, ERRW
        close PUTW;close GETR;close ERRR;
        open STDIN, "<&".fileno(PUTR)  or die "Can't dup PUTR for STDIN";
        open STDOUT, ">&".fileno(GETW)  or die "Can't dup GETW for STDOUT";
        open STDERR, ">&".fileno(ERRW)  or die "Can't dup ERRW for STDERR";
        eval {
            xexec @$cmdref;
        }; 
        carp $@;
        exit(MAGICANTICODE);
    }
}

sub putget {
    my $rv;
    eval {
        $rv=xputget(@_)
    };
    warn $@ if $@;
    $rv
}

1;


=back

=head1 NOTES

This does not close open filehandles that have not been marked for close-on-exec.
Be sure to correctly set $^W before opening files in suid processes
or in servers to prevent security risks.

Some exit code (232) is mis-used for "can't exec" exception handling -> this might conflict with 
another useage of the same exit code.

=head1 TODO/BUGS

Child (sigchld) handling is still not really correct. If the child forks another child
and exits before it's own child, we will probably get confused.

=head1 AUTHOR

Christian Jaeger, pflanze@gmx.ch

=cut


