# Thu May 13 00:06:19 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::DaemonRunfile

=head1 SYNOPSIS

 my $run= Chj::Unix::DaemonRunfile->new("Runpath",$Namegiver);
 # $Namegiver must support the user, hostname, ip, pid methods.
 $run->writefile;# throws exception if already in use. gets lock.
 $run->autoclean;# optional: make the runfile be deleted
                 # if perl gets the chance to run it's destructor
 # now do stuff needing the lock. Then exit or undef $run.

=head1 DESCRIPTION

Create a file indicating that a service is running, and containing all
data for finding out which process it is (and on which machine, which
would be important should the file be created on a networked
filesystem).

Unlike most pid file implementations which just look whether the file
exists (and hopefully check if it's stale, i.e. there's still some
process running with the recorded pid), this class also keeps an open
lock on it. This way, we can safely and easily determine if the daemon
has finished or not. It's also completely unnecessary to remove the
file, so the perl daemon can call exec without having to worry about
the program now knowing to do that (but maybe a better approach would
be to fork/exec instead and leave the perl parent running, as a kind
of signal proxy?).

The downsides of this approach are: 1) the daemon must take care to
never close the file, neither by destroying the runfile object too
soon (even if it exec's another program). 2) currently it probably
won't work over a networked filesystem since it is simply using
flock().  3) not sure if this is an upside or downside: if the daemon
process (potentially an exec'ed program) does fork/exit again, it can
still hold the lock open, but the recorded pid will not be valid
anymore.

=head1 METHODS

=over 4

=item new (path, namegiverobject)

=item writefile

=item readfile

returns user,hostname,ip,pid read from the file, or throws an exception.

=item autoclean([1])

switch on autoclean. be very careful, problem is if you fork and the
wrong process has a chance to remove the file, too. usually not needed.

=back

=head1 BUGS

Hm there's a small race problem: between a new daemon writing pid data
and a reader reading the data. There would have to be a second lock to
prevent this.

=head1 SEE ALSO

L<Chj::Unix::Daemonizer>

=cut

#'

package Chj::Unix::DaemonRunfile;

use strict;
use Carp;
use Fcntl ':flock';
use Chj::xsysopen; use Chj::xsysopen qw(xsysopen_readwrite);


use Class::Array -fields=> (
			    "Path",# file path e.g. ".../foo.run" (or maybe .lck)
			    # ^- eigentlich ein witz, nun wirds in Daemon gespeichert, hier, und dann in dem file object nochmals
			    "Namegiver", # must support the user, hostname, ip, pid methods.
			    "_Fh",
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    ($$self[Path],$$self[Namegiver])=@_;
    $self
}

sub writefile {
    my $s=shift;
    my ($maybe_namegiver, $maybe_alreadyrunningcb)=@_;# 'optional. naja?.'  jo und nun backwards needed.
    my $namegiver= $maybe_namegiver || $$s[Namegiver];
    {
	local $^F=60000;# do not close on exec. safe number?
	$$s[_Fh]= xsysopen_readwrite $$s[Path];
    }
    # 1.) get flock
    if (flock ($$s[_Fh], LOCK_EX|LOCK_NB)) {
	my ($user,$hostname,$ip,$pid)=($namegiver->user,
				       $namegiver->hostname,
				       $namegiver->ip,
				       $namegiver->pid);
	# 2.) get fcntl lock, too?
	#$runfh->xrewind; it's still 0 anyway
	$$s[_Fh]->xtruncate;
	$$s[_Fh]->xprint("$user\0$hostname\0$ip\0$pid\n");
	$$s[_Fh]->xflush;
	return;
    } else {
	my $cont= $$s[_Fh]->xcontent;
	undef $$s[_Fh];
	chomp $cont;
	my ($u,$hn,$ip,$p)= split /\0/,$cont;
	my $h="(unknown)";
	if ($hn or $ip){
	    $h= do {
		if ($hn) {
		    if ($ip) {
			"$hn\[$ip\]"
		    } else {
			"$hn"
		    }
		} else {
		    "[$ip]"
		}
	    };
	}
	if ($maybe_alreadyrunningcb) {
	    &$maybe_alreadyrunningcb
	} else {
	    croak __PACKAGE__.": writefile '$$s[Path]': there is already a daemon running ($u\@$h pid $p)";##(warum croak?)    warum  package?.  warum  exception?  warum sagen es gehe um daemon?  wenns doch unabhaenige funktionalitaet ist oder nid? nid ganz? krank.
	}
    }
}

sub readfile {
    my $s=shift;
    my $fh= xsysopen $$s[Path],O_RDWR;
    if (flock ($fh, LOCK_EX|LOCK_NB)) {
	croak "file '$$s[Path]' not currently locked";
    } else {
	my $cont= $fh->xcontent;
	chomp $cont;
	#my ($u,$hn,$ip,$p)=
	split /\0/,$cont;
    }
}


sub autoclean {
    my $s=shift;
    if (!@_ or $_[0]) {
	bless $$s[_Fh],"Chj::Unix::DaemonRunfile::File";
    } elsif (@_) {
	croak __PACKAGE__.": autoclean cannot really be undone";#well isch ne lüge da ich ja eh hardcoded hab
    }
}

{
    package Chj::Unix::DaemonRunfile::File;
    our @ISA=qw(Chj::IO::File);
    sub DESTROY {
	my $self=shift;
	local ($@,$!);
	unlink $self->path or warn "could not unlink ".$self->path.": $!";
	$self->SUPER::DESTROY;
    }
}

1;
