# Thu Dec 18 16:07:02 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# -Thu, 18 Dec 2003 17:04:10 +0100
# hum ob das in cplpl langsamer wäre oder in lisp schneller.
#
# $Id$

=head1 NAME

Chj::Util::Level2edge

=head1 SYNOPSIS

 use Chj::Util::Level2edge;
 my $lvlbase= "/home/$ENV{USER}/.surveyorservice/lvl";
 # Chj::Util::Level2edge->create_base($lvlbase);  well no, rather do that itself.
 my $lvl= new Chj::Util::Level2edge $lvlbase;
 my $alarmhash= $lvl->levels(@currently_amissed_serviceids);
 for my $serviceid (keys %$alarmhash)
    # $$alarmhash{$serviceid} is either 1 (new alarm) or 2 (alarm again because of timeout) or 0 (service is back)
 }
 $lvl->save; # writes state to files.

=head1 DESCRIPTION

For system state checker alarm scripts.

=cut

 #"'};';}"}';

package Chj::Util::Level2edge;

use strict;
use utf8;
use Chj::xopendir;
use Chj::xopen "xopen_append";
use Chj::xperlfunc;#xstat
use Carp;
use POSIX 'ENOENT';

use Class::Array -fields=> (
			    'Base', # must be a directory with only level2edge files, and .level2edge marker file, in it.
			    'Retime', # re-alarm time (timeout time)  in seconds. defaults to our $retime
			    'Ret',
			   );

our $retime= 60*60*24; #sec

sub new {
    my $class=shift;
    my $self= $class->SUPER::new(@_);
    @$self[Base,Retime]=@_;
    $$self[Retime]= $retime unless defined $$self[Retime];
    $self
}

sub _escape {
    my $str=shift;
    $str=~ s{\%}{\%25}sg;
    $str=~ s{/}{\%2f}sg;
    $str;
}
sub _unescape {
    my $str=shift;
    $str=~ s{\%2f}{/}sgi;
    $str=~ s{\%25}{\%}sg;
    $str;
}

sub levels {
    my $self=shift;

    my %ret;
    my $now=time;

    # old ones
    my %oldamiss;
    {
	my $d;
	eval {
	    $d= xopendir $$self[Base];
	};
	if ($@) {
	    #if ($!==ENOENT) { grr, geht wieder mal nicht.
	    if ($@=~ /no such/i or $@=~ /nicht gef/i) {###uuugly
		xmkdir $$self[Base];
		xopen_append "$$self[Base]/.level2edge";
		$d= xopendir $$self[Base];
	    } else {
		#warn "hei '$!'";
		die
	    }
	}
	my $seen;
	while(defined(my$item=$d->xnread)){
	    if ($item eq ".level2edge"){
		$seen=1;
	    } elsif (substr($item,0,1) eq '.') {
		# ignore
	    } else {
		$oldamiss{_unescape($item)} = undef;
	    }
	}
	$seen or croak "missing .level2edge file in '$$self[Base]'";
    }

    # new ones
    for my $id (@_) {
	if (exists $oldamiss{$id} ) {
	    # was already amiss
	    # long enoug to warrant a new alarm?
	    my $time= xstat( $self->path_id($id))->mtime;
            if ( ($now-$time)>$retime ) {
                $ret{$id}=2;
	    }
	    delete $oldamiss{$id};
	} else {
	    # new alarm.
	    $ret{$id}=1;
	}
    }

    # deliver unalarms for the remaining old
    for my $id (keys %oldamiss) {
	$ret{$id}=0;
    }

    $$self[Ret]= \%ret;
}

sub path_id {
    my $self=shift;
    my $id=shift;
    $$self[Base]."/"._escape($id);
}

sub save {
    my $self=shift;
    croak "must call levels() first" unless $$self[Ret];
    for my $id (keys %{$$self[Ret]}) {
	my $val= $$self[Ret]{$id};
	if ($val) {
	    (xopen_append $self->path_id($id))->xprint("+");
	} else {
	    xunlink $self->path_id($id);
	}
    }
    undef $$self[Ret]
}

sub nosave {
    my $self=shift;
    undef $$self[Ret]
}

sub DESTROY {
    my $self=shift;
    local ($@,$!,$?);
    if ($$self[Ret]) {
	warn "DESTROY: $self had unwritten level states: ".join(", ",map{ "$_ ($$self[Ret]{$_})" } keys %{$$self[Ret]})
    }
}


1;
