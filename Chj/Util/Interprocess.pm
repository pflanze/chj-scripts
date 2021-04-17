# Sat Feb  3 01:03:24 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Util::Interprocess

=head1 SYNOPSIS

=head1 DESCRIPTION

=over 4

=item In_subprocess( thunk )

runs thunk in a forked child, propagating return values and exceptions
through serialization back to the parent.

=back

=cut


package Chj::Util::Interprocess;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=
  (
   'In_subprocess'
  );

use strict;

use Chj::xpipe;
#use Data::Dumper;##t odo replace with something undangerous
use Storable qw(store_fd fd_retrieve);
use Carp;

our $handle_exit= sub {
    my($status)=@_;
    if ($status==0) {
	exit 0;
    } elsif ($status & 127) {
	carp "got signal ".($status & 127).($? & 128 ? " (dumped core)" : "");
	exit 2;##irgend n standard ?
    } else {
	exit ($status >> 8)
    }
};

sub In_subprocess ($ ) {
    my ($thunk)=@_;
    my $want_array= wantarray;
    my ($r,$w)=xpipe;
    my $pid=fork;
    defined $pid or croak "fork: $!";
    if ($pid) {
	$w->close;
	#my $msg= $r->xcontent;
	my $kind;
	$r->xsysread($kind,1)==1 or do {
	    #die "missing reply";##  NCOHmal ein ort , weg, hier in kreuzfeur
	    #  The subprocess has "probably" exited (or died through a signal). OR it might have exec'ed .  LEz try to handle this this way:
	    #  just probagate this up
	    waitpid $pid,0; ###ps  [todo]  was wenn n anderer teil descodes den schon geholt hat. ach kreuz und feuer. aberwohlegal od so
	    my $status=$?;
	    $handle_exit->($status)
	};
	$kind eq "E" or $kind eq "V" or die "got invalid msg from child: starting with '$kind'";
	my $obj= fd_retrieve($r); defined $obj or die "missing (or unretrievable) reply (2)";#solche sollten eben wirkklich wirklch by default exns schmeissen. in allen sprachen~ etwa[ ?.]
	$r->xclose;#okright?no exn danger gell?
	waitpid $pid,0;
	my $status=$?;
	#if (length $msg) {
	    #my $kind= substr $msg,0,1;
	    #$kind eq "E" or $kind eq "V" or die "got invalid msg from child: starting with '$kind'";
	    #my @values= eval substr $msg,1;
	    #if ($@) {
	    #	die "error reconstructing msg object: $@";
	    #}
	    # now revive the exn:
	    if ($kind eq "E") {
		die $$obj  # $values[0];
	    } else {
		#return it
		#$want_array ? @values : $values[0]
		#$want_array ? @$obj : $obj
		#use Data::Dumper; print "got obj: ".Dumper ($obj);
		$want_array ? @$obj : $$obj[0]
	    }
	#}
#status nun ganz unbenutzt"?"
# 	else {
# 	    if ($status==0) {
# 		# ok, return undefined return value.
# 		undef
# 	    } else {
# 		die "subprocess gave non-zero exit status $status but no exception object";
# 	    }
# 	}
    } else {
	$r->close;
	my @res= eval {
	    #todo make sure $w is not inherited over further forks or execs
	    $want_array ? &$thunk : scalar &$thunk
	};
	#ps andere arten von scope exits, return, callcc?,. dynamic wind kennt perl nicht für return schutz.nur warning.
	# AHHH und was ich  funny  vergass sind exits through exit.[resp signale].
	if (ref$@ or $@) {
	    my $e=$@;
	    #how to show exceptions really ? serialize them and pass through an fd ?
	    #'yeah.'
	    #$w->xprint ("E",Dumper $e);
	    $w->xprint ("E");#GRRRNICHTVERGESSEN
	    store_fd(\$e,$w) or die "error sending: $!";#nötig?ja.
	    $w->xclose;
	    exit 1;
	} else {
	    #$w->xprint ("V",@res); #heh vergass eh noch das dumper wow
	    $w->xprint ("V");#!!
	    #store_fd ($want_array ? \@res : $res[0],$w) or die "error sending: $!"; NEIN man muss ihm IMMMER eine referenz geben. was auch immer es sei.
	    store_fd (\@res,$w) or die "error sending: $!";
	    $w->xclose;
	    exit 0;
	}
    }
}


1
