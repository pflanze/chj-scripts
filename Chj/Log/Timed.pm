# Tue Jul 20 17:48:47 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Log::Timed

=head1 SYNOPSIS

 #$stringtooutput=Chj::Log::Timed::write("str")
 Chj::Log::Timed::write(*out{IO},"str"[,$time])
 ($nextentry,$time)=Chj::Log::Timed::read(*in{IO}) #ps (denkwürdig:)ein stream der nicht io ist.

 # damit kann es aber nicht wissen wann es der erste output ist (andererheader!).
 # und beim parsen weiss es nicht die start time.
 # muss ich nun eben "halt" ausser halb a la C manier. warum i ds schlecht

=head1 DESCRIPTION


 read croaks on read errors  aber nimmt an dass der stream selber nicht kroakt resp dessen fehler in $! zu finden ist. *das* ist schlecht von perl

=cut


package Chj::Log::Timed;

use strict;

#use Class::Array -fields=> ();
#wenn schon obi's die ich hier drin BENUTZE

BEGIN {
    eval {
	require Time::HiRes;
	import Time::HiRes 'time';
    };
    if ($@) {
	warn "could not load Time::HiRes, not using fractional times";
    }
}

use Carp;

sub write {
    my ($out,$what,$time)=@_;
    $time||=time;
    my $len=length $what;
    my $timesec=int $time;
    my $timesubsec= int(($time-$timesec)*65536); if ($timesubsec==65536) {warn "this was not expected to ever happen, but so we are going to correct it"; $timesubsec=0; $timesec++ }
    #warn "write: time=$time, timesec=$timesec, timesubsec=$timesubsec\n";
    my $header= (pack "N",$len).(pack "N",$timesec).(pack "n",$timesubsec); #.(pack "  obs der erste ist  aber das mache ich nun eben nicht kein kontext  kontextfreie irgendwas
    print $out $header,$what;
}

sub read {
    my ($in)=@_;
    # read header:
    my $buf;
    my $rv=read $in,$buf,10;
    if (!defined $rv) {
	croak __PACKAGE__."::read (from $in): $!";
    }
    if (!$rv) {
	return
    }
    if (not $rv==10) {
	## reread?
	croak __PACKAGE__."::read (from $in) did not get a full 8 bytes header but $rv bytes instead, something's wrong?";
    }
    my $len=unpack "N",substr($buf,0,4);
    my $timesec=unpack "N",substr($buf,4,4);
    my $timesubsec=unpack "n",substr($buf,8,2);
    $rv=read $in,$buf,$len;
    if (!defined $rv) {
	croak __PACKAGE__."::read (from $in): $!";
    }
    if (!$rv) {
	croak __PACKAGE__."::did not get body (yet?)";
    }
    if ($rv!=$len){
	croak __PACKAGE__."::did not get full body, expected $len bytes, got $rv instead";##todo muss ich sammeln? ewigefrage
    }
    #warn "read a frame from ".($timesec+$timesubsec/65536)." (".localtime($timesec+$timesubsec/65536)."\n";
    #warn "read: timesec=$timesec, timesubsec=$timesubsec\n";
    ($buf,$timesec+$timesubsec/65536)
}

1;
