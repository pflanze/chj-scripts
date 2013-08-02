#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Transmittable

=head1 SYNOPSIS

 use Chj::Transmittable;

 xtransmit ($fd,$val);
 # or if multiple writers onto fd
 xlocktransmit ($fd,$val);

 xreceive ($fd);
 # or if multiple readers from fd
 xlockreceive ($fd);

=head1 DESCRIPTION

Layer atop Storable to make multiple-actor-per-queue message queuing
and receiving possible (i.e. adding [another, since Storable already
has one, but doesn't buffer precisely] length header).

xreceive and xlockreceive return undef on EOF.

=cut


package Chj::Transmittable;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xtransmit xreceive xlocktransmit xlockreceive);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Fcntl 'LOCK_EX','LOCK_UN';
use Storable qw(thaw nfreeze);

our $MAGIC= "TrN7";

sub _xlocktransmit {
    my ($dolock)=@_;
    sub {
	my ($val,$fd)=@_;
	my ($e,$goterr);
	eval {
	    my $str= nfreeze($val);
	    my $len= length $str;
	    $len < 4294967296 or die "too long";
	    (flock $fd, LOCK_EX
	     or die "could not flock($fd,LOCK_EX): $!")
	      if $dolock;
	    my $buf= $MAGIC . pack ('N', $len) . $str;
	    $fd->xsyswrite($buf) == length($buf)
	      or die "could not write everything (EINTR or so?)";
	    $fd->xflush;
	    1
	} || do {
	    $e= $@;
	    $goterr=1;
	};
	(flock $fd, LOCK_UN
	 or $e ||= "could not flock($fd,LOCK_UN): $!")
	  if $dolock;
	die $e if $goterr;
    }
}

my $hexdigits= "0123456789ABCDEF";
sub str2hex {
    join " ",
      map {
	  my $x= ord($_);
	  (substr ($hexdigits, $x >> 4, 1)
	   .
	   substr ($hexdigits, $x & 15, 1))
      } split //, $_[0];
}
sub char2xxd {
    my ($c)=@_;
    my $n= ord $c;
    if ($n >= 32 and $n < 255) {
	$c
    } else {
	"."
    }
}

sub xxd {
    my ($str)=@_;
    str2hex ($str). " " . join("",map {char2xxd $_} split //, $str)
}


sub _xlockreceive {
    my ($dolock)=@_;
    sub {
	my ($fd)=@_;
	my $buf;
	my ($e,$goterr);
	my $res;
	eval {
	    (flock $fd, LOCK_EX
	     or die "could not flock($fd,LOCK_EX): $!")
	      if $dolock;
	    my $didread= $fd->xsysread($buf,8);
	    if ($didread) {
		$didread == 8 or die "got partial head, $didread bytes only";
		substr ($buf, 0, 4) eq $MAGIC
		  or die "invalid magic in header (".xxd($buf).")";
		my $len= unpack ('N', substr $buf,4,4);
		$fd->xsysread($buf,$len) == $len
		  or die "could not read complete message";
		$res= thaw $buf;
	    }
	    1
	} || do {
	    $e= $@;
	    $goterr=1;
	};
	(flock $fd, LOCK_UN
	 or $e ||= "could not flock($fd,LOCK_UN): $!")
	  if $dolock;
	die $e if $goterr;
	$res
    }
}

*xlocktransmit= _xlocktransmit(1);
*xlockreceive= _xlockreceive(1);
*xtransmit= _xlocktransmit(0);
*xreceive= _xlockreceive(0);

1
