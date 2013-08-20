#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xopengzip

=head1 SYNOPSIS

 use Chj::xopengzip 'xopengzip_read';
 my $in= xopengzip_read("foo.gz", # or bz2; case insensitive.
                        #suffix=> "gz",
                        do_fallback=> 1);
 # do_fallback means to use file directly if suffix is unknown.
 # suffix overrides using the actual suffix.
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
    use Chj::xtmpdir ();
    use Digest::MD5 ();
    use Fcntl 'SEEK_SET';
    our %meta; # "fh" -> [pid,path,opt,cmd,(xseekpath)]
    our $seekcachebase;
    our %seekcache; # xseekpath => time last access
    our $seekcache_maxsize= 10;
    sub _Cache_created {
	my ($xseekpath)=@_;
	# drop oldest
	our @entries= sort {
	    $$a[1] <=> $$b[1]
	} map{[$_,$seekcache{$_}]} keys %seekcache;
	if (@entries >= $seekcache_maxsize) {
	    my ($path,$t)= @{$entries[-1]};
	    unlink $path or warn "BUG? could not unlink '$path': $!";
	    delete $seekcache{$path}
	}
	$seekcache{$xseekpath}= time;
    }
    sub _Cache_accessible { # check if exists, if so, update too.
	my ($xseekpath)=@_;
	$seekcache{$xseekpath} and $seekcache{$xseekpath}=time;
    }
    sub _Perhaps_xseekpath {
	my ($path)=@_;
	$seekcachebase and
	  $seekcachebase."/".Digest::MD5::md5_hex($path);
    }
    sub _Perhaps_cache_accessible {
	my ($path)=@_;
	if (my $xseekpath= _Perhaps_xseekpath ($path)) {
	    _Cache_accessible ($xseekpath)
	      and $xseekpath;
	} else {
	    undef
	}
    }
    sub rebless {
	my $class= shift;
	my ($s0,$pid_path_cmd)=@_;
	my $s= bless $s0, $class;
	$meta{$s}= $pid_path_cmd;
	$s
    }
    sub path {
	my $s=shift;
	my ($pid,$path,$opt,$cmd)= @{$meta{$s}} or die;
	$path
    }
    sub xseek {
	my $s=shift;
	@_==1 or die "only accepting 1 argument (pos) for now";
	my ($pos)=@_;
	my ($pid,$path,$opt,$cmd,$xseekpath)= @{$meta{$s}} or die;
	if (defined $xseekpath) {
	    # we are the opened xseekpath already
	} else {
	    $seekcachebase||= do {
		my $t= Chj::xtmpdir::xtmpdir();
		$t->push_on_destruction
		  (sub {
		       my ($seekcachebase)=@_;
		       unlink $_ for glob "$seekcachebase/*"
		   });
		$t
	    };
	    $xseekpath= _Perhaps_xseekpath($path);
	    if (not _Cache_accessible($xseekpath)) {
		my $out= Chj::xopen::xopen_write($xseekpath);
		my $in= do {
		    #if (position is at the start) {
		    #    $s
		    #} else {
		    $s->xclose;
		    Chj::xopengzip::xopengzip_read($path,%$opt)
			#}
		  };
		$in->xsendfile_to($out);
		$in->xclose;
		$out->xclose;
		_Cache_created($xseekpath);
	    }
	    $meta{$s}[4]= $xseekpath;
	    open $s, "<", $xseekpath
	      or die "could not open '$xseekpath': $!";
	    # XXX lost binmode settings I guess?
	}
	seek $s, $pos, SEEK_SET
	  or die "seek($s,$pos,SEEK_SET): $!";
    }
    sub xclose {
	my $s=shift;
	$s->SUPER::xclose;
	my ($pid,$path,$opt,$cmd,$xseekpath)= @{$meta{$s}} or die;
	unless ($xseekpath) {
	    Chj::xperlfunc::xwaitpid($pid,0);
	    ($? == 0 or $? == POSIX::SIGPIPE)
	      or die "reading '$path', @$cmd exited with status $?";
	}
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


sub xopengzip_read {
    @_>= 1 or die;
    my $path=shift;
    my %opt= @_;
    if (my $xseekpath= Chj::IO::ReadGzip::_Perhaps_cache_accessible $path) {
	#warn "accessing xseekcache";
	xopen_read $xseekpath
    } else {
	my $in= xopen_read $path;
	my $lcsuffix= lc $path;
	$lcsuffix=~ s/.*\.//s or do {
	    if (defined $opt{suffix}) {
		$lcsuffix= lc $opt{suffix};
	    } else {
		die "no optional suffix argument given and path has not suffix: '$path'";
	    }
	};
	if (my $cmd= $$cmds{$lcsuffix}) {
	    my ($r,$w)=xpipe;
	    if (my $pid= xfork) {
		$in->xclose;
		$w->xclose;
		Chj::IO::ReadGzip->rebless ($r,[$pid,$path,\%opt,$cmd])
	    } else {
		$in->xdup2(0);
		$in->xclose;
		$w->xdup2(1);
		$w->xclose;
		xexec @$cmd;
	    }
	} else {
	    if ($opt{do_fallback}) {
		$in
	    } else {
		die "unknown suffix '$lcsuffix' (path '$path')";
	    }
	}
    }
}

# BUGS or possible ones:
# - $cmds might be localized. But it's not kept in %meta. Thus xopengzip_read may fail from xseek.
# - is binmode lost on reopen, right? Yes, I had to use POSIX dup2 before.

1
