=head1 NAME

Chj::ulimit

=head1 SYNOPSIS

use Chj::ulimit;

ulimit qw(-S -v 100000);  # set the soft limit for virtual memory to 100 MB
ulimit qw(-f 100);

=head1 DESCRIPTION

Provides almost exact the same semantics like the bash ulimit function, with the
following exceptions:

 - you can specify undef or the string "unlimited" for unlimited
 - you can only set limits, not query them
 - -p is not implemented (since it seems BSD::Resource doesn't implement them?)
 - when setting hard limits, the soft limit is set as well. That seems
   necessary since if only the hard limit is set (soft limit unlimited),
   the hard limit doesn't seem to take effect (under linux), and the
   shell does do the same as well, though not consistently (?)

The function dies if it can't set the limit (as well if improper arguments
are given).

From bash documentation:

 ulimit: ulimit [-SHacdflmnpstuv] [limit]
     Ulimit provides control over the resources available to processes
     started by the shell, on systems that allow such control.  If an
     option is given, it is interpreted as follows:

         -S use the `soft' resource limit
         -H use the `hard' resource limit
         -a all current limits are reported
         -c the maximum size of core files created
         -d the maximum size of a process's data segment
         -f the maximum size of files created by the shell
            [that's kbytes, too, in spite of ulimit -a saying it's blocks]
         -l the maximum size a process may lock into memory
         -m the maximum resident set size
         -n the maximum number of open file descriptors
         -p the pipe buffer size [not implemented, note from the author]
         -s the maximum stack size
         -t the maximum amount of cpu time in seconds
         -u the maximum number of user processes
         -v the size of virtual memory

     If LIMIT is given, it is the new value of the specified resource.
     Otherwise, the current value of the specified resource is printed.
     If no option is given, then -f is assumed.  Values are in 1024-byte
     increments, except for -t, which is in seconds, -p, which is in
     increments of 512 bytes, and -u [and -n, note from the author], 
     which is an unscaled number of processes.

(BTW note that the following all deal with virtual memory: 

 -m= RLIMIT_RSS   resident mem
 -v= RLIMIT_VMEM  virtual mem
 RLIMIT_AS  virtual adress space, not supported here

)

=head1 BUGS

Not all options are tested yet. May be a bit linux centric.

=head1 AUTHOR

Christian Jaeger <pflanze@gmx.ch>

=head1 LICENSE

freeware

=cut

#'"`

package Chj::ulimit;

require Exporter;
@ISA= qw(Exporter);
@EXPORT= qw(ulimit);

use strict;

use BSD::Resource;
use Carp;


my %resourcemap= (
    '-c'=> [RLIMIT_CORE, 1024],
    '-d'=> [RLIMIT_DATA, 1024],
    '-f'=> [RLIMIT_FSIZE, 1024],
    '-l'=> [RLIMIT_MEMLOCK, 1024],
    '-m'=> [RLIMIT_RSS, 1024],
    '-n'=> [RLIMIT_NOFILE, 1],
    #'-p'=> [RLIMIT_, 512], # ?
    '-s'=> [RLIMIT_STACK, 1024],
    '-t'=> [RLIMIT_CPU, 1],
    '-u'=> [RLIMIT_NPROC, 1],
    '-v'=> [RLIMIT_VMEM, 1024],
);

sub ulimit {
    my ($soft, $action, $data);
    for (@_) {
	if (! defined $_ or $_ eq "unlimited") {
	    if (! defined $data) {
                #$data=undef hehe
            } else {
                croak "No more data arguments expected (got undef)";
            }
	} elsif ($_ eq '-S') {
            if (defined $soft) {
                croak "Only one -S or -H option allowed";
            } else {
                $soft=1
            }
        } elsif ($_ eq '-H') {
            if (defined $soft) {
                croak "Only one -S or -H option allowed";
            } else {
                $soft=0
            }
        } elsif (/^-/) {
            if (! defined $action) {
                if ($action= $resourcemap{$_}) {
                    # OK
                } else {
                    croak "Unknown option '$_'";
                }
            } else {
                croak "No more option arguments allowed (got '$_')";
            }
        } else {
            if (! defined $data) {
                $data=$_;
            } else {
                croak "No more arguments expected (got '$_')";
            }
        }
    }

    my ($softlimit,$hardlimit)= getrlimit($action->[0]) or die "Could not get resource limit: $!";

    if (defined $data) {
        $data *= $action->[1];
        if ($soft) {
            $softlimit=$data
        } else {
            $hardlimit=$data;
            # strangely it's necessary to set the soft limit == or below the hard limit as
            # well, or the hard limit will not have effect !!! (That's under linux 2.4.12-ac3)
            #if (! $softlimit or $softlimit==RLIM_INFINITY or $softlimit > $hardlimit) {
            #   $softlimit=$hardlimit;
            #}
            $softlimit=$data; # ?
        }
    } else {
        $data= RLIM_INFINITY;
	#warn "INFINITY";#
        if ($soft) {
            $softlimit=$data;
        } else {
            $hardlimit=$data;
            $softlimit=$data; # ?
        }
    }

    setrlimit ($action->[0], $softlimit,$hardlimit) or die "Could not set resource limit: $!";
}

__END__

# Test:

ulimit qw(-S -v 10000);
ulimit qw(-f 100);

exec "/bin/bash";

