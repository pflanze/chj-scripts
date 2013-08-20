#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xopengzip

=head1 SYNOPSIS

 use Chj::xopengzip 'xopengzip_read';
 my $in= xopengzip_read($path,undef,1);
 # ^ 1 for fall back to normal file if suffix is unknown;
 #   suffix instead of undef to force a known suffix.
 $in->xcontent # or whatever Chj::IO::File methods you like
 $in->xclose  # will die on decoding errors, but not on premature
              # close (sigpipe).

=head1 DESCRIPTION


=cut


package Chj::xopengzip;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xopengzip_read);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

{
    package Chj::IO::ReadGzip;
    our @ISA= ('Chj::IO::Pipe');
    use Chj::IO::Pipe;
    use POSIX ();
    our %pids; # "fh" -> [pid,path,cmd]
    sub rebless {
	my $class= shift;
	my ($s0,$pid_path_cmd)=@_;
	my $s= bless $s0, $class;
	$pids{$s}= $pid_path_cmd;
	$s
    }
    sub xclose {
	my $s=shift;
	$s->SUPER::xclose;
	my ($pid,$path,$cmd)= @{$pids{$s}} or die;
	Chj::xperlfunc::xwaitpid($pid,0);
	($? == 0 or $? == POSIX::SIGPIPE)
	  or die "reading '$path', @$cmd exited with status $?";
    }
}

use Chj::xopen 'xopen_read';
use Chj::xpipe;
use Chj::xperlfunc;

our $cmds=
  {
   gz=> ["gunzip"],
   bz2=> ["bunzip2"],
   # runzip would need a temp file.
  };


sub xopengzip_read ($;$) {
    my ($path,$maybe_suffix,$do_fallback)=@_;
    my $in= xopen_read $path;
    my $lcsuffix= lc $path;
    $lcsuffix=~ s/.*\.//s or do {
	if ($maybe_suffix) {
	    $lcsuffix= lc $maybe_suffix;
	} else {
	    die "no optional suffix argument given and path has not suffix: '$path'";
	}
    };
    if (my $cmd= $$cmds{$lcsuffix}) {
	my ($r,$w)=xpipe;
	if (my $pid= xfork) {
	    $in->xclose;
	    $w->xclose;
	    Chj::IO::ReadGzip->rebless ($r,[$pid,$path,$cmd])
	} else {
	    $in->xdup2(0);
	    $in->xclose;
	    $w->xdup2(1);
	    $w->xclose;
	    xexec @$cmd;
	}
    } else {
	if ($do_fallback) {
	    $in
	} else {
	    die "unknown suffix '$lcsuffix' (path '$path')";
	}
    }
}
