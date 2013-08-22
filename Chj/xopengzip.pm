#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xopengzip

=head1 SYNOPSIS

 use Chj::xopengzip 'xopengzip_read';
 $Chj::IO::ReadGzip::seekcache_maxsize= 10; # num files, default: 4
 my $in= xopengzip_read("foo.gz", # or bz2; case insensitive.
                        #suffix=> "gz",
                        do_fallback=> 1);
 # do_fallback means to use file directly if suffix is unknown.
 # suffix overrides using the actual suffix.
 $in->xcontent; # or whatever Chj::IO::File methods you like
 $in->xseek(1000); # careful: this will decompress the whole file into
                   # a cache;
 $in->xread($buf,500);
 $in->xclose  # will die on decoding errors, but not on premature
              # close (sigpipe).

=head1 DESCRIPTION

NOTE: don't call chdir when using relative $path s.

=head1 BUGS

This is using md5 hashing on $path to identify files. Since md5 is not
safe, don't use this on paths under control of an adversary!

I think binmode is lost on reopen.

Don't localize $cmds, it's not kept in %meta. Thus xopengzip_read may
fail from xseek.

=cut


package Chj::xopengzip;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xopengzip_read);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::opencachefile qw(opencachefile if_open_else);

{
    package Chj::IO::ReadGzip;
    our @ISA= ('Chj::IO::Pipe');
    use Chj::IO::Pipe;
    use POSIX ();
    use Chj::xtmpdir ();
    use Digest::MD5 ();
    use Fcntl 'SEEK_SET';
    our %seekcache; # xseekpath => time last access
    our $seekcachebase = do {
	my $t= Chj::xtmpdir::xtmpdir();
	$t->push_on_destruction
	  (sub {
	       my ($seekcachebase)=@_;
	       unlink $_ for keys %seekcache;
	   });
	# removing dir itself won't work with forked processes; sigh.
	# XX should we really use a symlink again, so as to have one
	# dir per program, not per program run?
	$t->autoclean(0);
	$t
    };
    our $seekcache_maxsize= 4;
    sub _Cache_access {
	my ($xseekpath)=@_;
	# drop oldest
	our @entries=
	  (
	   sort {
	       $$a[1] <=> $$b[1]
	   }
	   map {
	       if (-f $_) {
		   [$_,$seekcache{$_}]
	       } else {
		   # a concurrent process removed it
		   delete $seekcache{$_};
		   ()
	       }
	   }
	   keys %seekcache
	  );
	while (@entries >= $seekcache_maxsize) {
	    my ($path,$t)= @{pop @entries};
	    unlink $path; # can fail with concurrency
	    delete $seekcache{$path}
	}
	$seekcache{$xseekpath}= time;
    }
    sub _Xseekpath {
	my ($path)=@_;
	$seekcachebase."/".Digest::MD5::md5_hex($path);
    }

    our %meta; # "fh" -> [pid,path,opt,cmd,(xseekpath)]

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
	    # we are opened from the cache already
	} else {
	    $xseekpath= _Xseekpath($path);
	    my $newfh= Chj::opencachefile::opencachefile
	      ($xseekpath,
	       sub {
		   my ($out)=@_;
		   my $in= do {
		       #if (position is at the start) {
		       #    $s
		       #} else {
		       $s->xclose;
		       Chj::xopengzip::xopengzip_read($path,%$opt);
		       # ^ XX: there's some chance that this is now
		       # actually a cache filehandle...
		       #}
		   };
		   bless $out, "Chj::IO::File"; # for xsendfile_to to work
		   $in->xsendfile_to($out);
		   $in->xclose;
	       });
	    _Cache_access($xseekpath);
	    $meta{$s}[4]= $xseekpath;
	    open $s, "<&".fileno($newfh)
	      or die "could not dup: $!";
	    # XXX lost binmode settings I guess?
	    close $newfh or die "close ($newfh): $!";
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

    my $in= xopen_read $path;
    # XX $in is not used in case the cache file is found; stupid? Or safety?
    my $lcsuffix= lc $path;
    ($lcsuffix=~ s/.*\.//s and length $lcsuffix and not $lcsuffix=~ m|/|)
      or do {
	  if (defined $opt{suffix}) {
	      $lcsuffix= lc $opt{suffix};
	  } else {
	      die "no optional suffix argument given "
		."and path has no suffix: '$path'";
	  }
      };
    if (my $cmd= $$cmds{$lcsuffix}) {
	my $xseekpath= Chj::IO::ReadGzip::_Xseekpath ($path);
	if_open_else
	  ($xseekpath,
	   sub {
	       my ($fh)=@_;
	       #warn "accessing xseekcache";
	       Chj::IO::ReadGzip->rebless ($fh,[undef,$path,\%opt,$cmd, $xseekpath])
	   },
	   sub {
	       my ($r,$w)=xpipe;
	       if (my $pid= xfork) {
		   $in->xclose;
		   $w->xclose;
		   Chj::IO::ReadGzip->rebless ($r,[$pid,$path,\%opt,$cmd]);
	       } else {
		   $in->xdup2(0);
		   $in->xclose;
		   $w->xdup2(1);
		   $w->xclose;
		   xexec @$cmd;
	       }
	   });
    } else {
	if ($opt{do_fallback}) {
	    $in
	} else {
	    die "unknown suffix '$lcsuffix' (path '$path')";
	}
    }
}

1
