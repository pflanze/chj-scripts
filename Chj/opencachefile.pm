#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::opencachefile

=head1 SYNOPSIS

 use Chj::opencachefile;
 my $fh= opencachefile $path, $createproc

 # opportunistic use of a cachefile without creation:
 use Chj::opencachefile qw(opencachefile if_open_else);
 if_open_else
   ($path,
    sub { my ($fh)=@_; ..},
    sub { # don't have it
    });

=head1 DESCRIPTION

If $path exists, return immediately. Otherwise, create $path.".tmp",
and (if $path still doesn't exist) run $createproc with the outgoing
filehandle to the .tmp file as an argument. Createproc should *not*
close the given filehandle. Afterwards, renames the file to $path. If
$path.".tmp" existed, wait for it to be renamed to $path.

Meaning, when the assumption that the contents at $path are a pure
function of $path holds, this is multiprocessing safe and creates
$path only ever once.

=cut


package Chj::opencachefile;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(opencachefile);
@EXPORT_OK=qw(if_open_else);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use POSIX qw(O_CREAT O_EXCL O_RDONLY O_WRONLY ENOENT EEXIST);
use Chj::xperlfunc;
use Time::HiRes 'sleep';

sub if_open_else ($$$) {
    my ($path, $use, $create)=@_;
    if (sysopen my $in, $path, O_RDONLY) {
	@_=($in); goto $use;
    } else {
	if ($! == ENOENT) {
	    @_=(); goto $create;
	} else {
	    die "open '$path' for reading: $!";
	}
    }
}

sub opencachefile ($$) {
    my ($path,$createproc)=@_;
    my $identity= sub {
	my ($fh)=@_;
	$fh
    };
    if_open_else
      ($path,
       $identity,
       sub {
	   my $tmppath= $path.".tmp";
	   if (sysopen my $tmp, $tmppath, O_CREAT|O_EXCL|O_WRONLY) {
	       my $cleanup= sub {
		   close $tmp;
		   unlink $tmppath;
	       };
	       # check for $path again to catch race condition of a
	       # creating process renaming inbetween the open calls.
	       if_open_else
		 ($path,
		  sub {
		      my ($fh)=@_;
		      &$cleanup;
		      $fh
		  },
		  sub {
		      if (eval {
			  &$createproc($tmp);
			  1
		      }) {
			  close $tmp or die "closing '$tmppath': $!";
			  xrename $tmppath,$path;
			  opencachefile($path,$createproc);
		      } else {
			  my $e= $@;
			  &$cleanup;
			  die $e;
		      }
		  });
	   } else {
	       if ($! == EEXIST) {
		   # another process/thread is supposedly creating it
		   my $checkwait; $checkwait= sub {
		       my ($sleeptime)=@_;
		       sleep $sleeptime;
		       @_= ($path,
			    sub {
				undef $checkwait;
				goto $identity
			    },
			    sub {
				# check whether tmp file is still
				# there, to catch race condition of
				# file having been renamed *and*
				# removed in the mean time
				if (-f $tmppath) {
				    @_=($sleeptime*1.05);
				    goto $checkwait;
				} else {
				    opencachefile($path,$createproc);
				}
			    });
		       goto \&if_open_else;
		   };
		   @_= (2000/2e9);
		   goto $checkwait;
	       } else {
		   die "open '$tmppath' for writing: $!";
	       }
	   }
       });
}

1
