package Chj::fileutils;

# Tue Feb 12 22:37:21 2002  Christian Jaeger, pflanze@gmx.ch
# 
# Copyright 2001 by ethlife renovation project people
# (christian jaeger, cesar keller, philipp suter, peter rohner)
# Published under the terms of the GNU General Public License
# Copyright 2003 by christian jaeger
# 
# $Id$

=head1 NAME

Chj::fileutils 

=head1 SYNOPSIS

 use Chj::fileutils (getlock releaselock fetchfile createfile 
               writebackfile getfilehandle removefile);

=head1 DESCRIPTION

This has formerly been known using the fileutils namespace, not Chj::fileutils.

All functions croak on errors. getlock keeps a filehandle to each lockfile open. 
All other functions never keep open filehandles.

=head1 FUNCTIONS

=over 4

=cut


require Exporter;
@ISA='Exporter';
@EXPORT_OK= qw(getlock releaselock fetchfile createfile writebackfile getfilehandle removefile);

use strict;
use Carp;
use Fcntl;
use Fcntl qw(LOCK_EX LOCK_NB);
use POSIX qw(EINTR EEXIST EINVAL);

use vars qw($tmpsuffix $bcksuffix $maxfilesize $symlinks $checkperms $strictperms $recreatesetid);
$maxfilesize= 1024*1024;
$tmpsuffix= '.new~%';
$bcksuffix= '.bck';
$symlinks= 'deny';
$checkperms= 1;
$strictperms= 1;
$recreatesetid= 0;

=item [$handle=] getlock ( lockfile_name [, perms ] )

Opens (creates if not exists, with 0600 permissions unless the perms argument is 
given - modified through the current umask) 
the given file (note: it must be writeable by the current user) and flock's it. 
Returns a "handle" that can be used to 'releaselock' it (no need to keep the handle otherwise).
Emits a warning if it has to wait for the lock. Croaks on errors.

=item releaselock ( $handle )

It is released anyway on program termination.

=cut

#'

my $genseq = 1;

sub getlock($;$) {
    my ($lockfile,$perms)=@_;
    no strict 'refs';
    $perms= 0600 unless defined $perms;
    my $lock = \*{"Chj::fileutils::_SYMBOL" . $genseq};
    sysopen $lock,$lockfile, O_RDWR|O_CREAT,$perms  or croak "Could not open or create lockfile '$lockfile': $!";
    # open it rw, since i read in qmail's docs that some systems don't allow to flock on readonly handles. I create the file 0600 so it can't be locked by anyone else.
    if (flock $lock, LOCK_EX|LOCK_NB) {
        # ok got lock
    } else {
        warn "$0 ($$): lock is already in use. Waiting...\n";
        WAITLOCK: {
            if (flock $lock, LOCK_EX) {
                warn "$0 ($$): ok, got lock.\n";
            } elsif ($! == EINTR) {
                redo WAITLOCK;
            } else {
                my $e=$!;
                close $lock;
                croak "Could not get lock: $e";
            }
        }
    }
    # ok:
    $genseq++
}

sub releaselock($) {
    my ($no)=@_;
    #croak "Missing argument" unless $no;
    no strict 'refs';
    my $lock = \*{"Chj::fileutils::_SYMBOL" . $no};
    close $lock or croak "Could not release lock, already released?";
    delete $Chj::fileutils::{"_SYMBOL".$no} or die "??";
}


=item $bufferref= fetchfile ( filepath )

Returns a reference to the contents of the file at the time of 
calling fetchfile. 
Doesn't read files bigger than 1MB (can be changed through $Chj::fileutils::maxfilesize).
Croaks on errors or if the file doesn't exist. 

=item $fh= getfilehandle ( filepath )

Opens the file for reading and returns an anonymous filehandle
you can use in <$in> constructs etc and afterwards just dispose of.
Croaks on errors opening the file.
(Of course you could also use IO::File, but this here is just 6 lines of code
and so will load faster :).

=item createfile ( filepath, [mode [, bufferref | buffer ]] )

Creates the file and optionally fills it with content. If mode is undef, 0666 is taken
instead (will be changed through umask).
Croaks on errors or if the file aready exists.

=item writebackfile ( filepath, bufferref | buffer [,backupfilepath | option=>value_pairs ] )

Recreates the file at filepath safely, using an intermediary file in the same
directory with $Chj::fileutils::tmpsuffix (defaults to ".new~%"
where % is replaced with a random number until a non-existant name is found)
appended to the filename, and
keeping a backup (if possible) of the old file either as 'backupfilepath' or else 
with appendix $Chj::fileutils::bcksuffix (which defaults to ".bck"). Without 'backupfilepath'
and with  $Chj::fileutils::bcksuffix set to undef, no backup will be made.
Croaks on errors or if the file doesn't exist.

Instead of the backupfilepath argument, option=>value pairs can be given to define
further parameters. In this case, the backupfilepath argument has to be given as
backupfilepath=> .. pair. All such options have their default stored in the
respective $Chj::fileutils:: variable.

 backupfilepath => path/to/file
 symlinks => deny | follow | nofollow
 checkperms => true | false
 strictperms => true | false
 recreatesetid => false | true

By default, writebackfile croaks if 'filepath' is a symlink (argument 'symlinks'
is 'deny'). 
Alternatively, a value of 'follow' (this means, for determining the path/name of the backup file 
the path/name of the file the symlink points to will be taken, not the path/name of the 
symlink), or a value of 'nofollow' (which means that the symlink will be replaced by the
file) can be given.

By default, the file is checked whether it can be written to. This check can be
switched off either by giving an optional parameter/value pair of checkperms=>0
or by setting $Chj::fileutils::checkperms to false.
By default, writebackfile will also croak if it can't set the newly created file's
owner or group to the original one. This behaviour can be switched via
strictperms or $Chj::fileutils::strictperms.

By default, setuid and setgid bits are not recreated on the new file. Change this
by setting 'recreatesetid' to true.

NOTE: file tests are done on the filename in several steps, -> might be there are (tons of)
race condition problems. No brain capacity left to think about that right now.


=item removefile( filepath )

If $Chj::fileutils::bcksuffix is set, tries to rename the given file to it's backup,
otherwise simply unlinks it. (croaks if it can't unlink)

=item xsyswriteall(filehandle/glob, buffer or ref, outfilename for errmsgs)

A helper function. Continually writes out the buffer until either everything
has been written, or an error has occured in which case it croaks.
(I don't know whether this is mandatory; simple tests on linux have shown that
even a bare syswrite finishes the whole write of some 40GB data while the process
is being hit by signals. But maybe it is still necessary on other systems or in
special situations.)

=cut

#'

sub fetchfile($) {
    my ($file)=@_;
    my $buffer;
    sysopen IN,$file, O_RDONLY or croak "Could not open $file for reading: $!";
    #open IN,"<$file"  or croak "Could not open $file for reading: $!";
    ##local $!;
    #local $/;
    #$buffer= <IN>; defined $buffer or die "Fehler buffer undef";
    #die $! if $!+0;
    #warn "Got buffer '$buffer'";   does not help, will just be empty string in case of "broken" read pipe.
    ##heh, do we have ANY way determining if infile pipe has been *prematurely* closed?
    ##WRITING to a closed pipe is an error of course. But reading: eof versus error?
    ##only way is return code from subprocess.
    ## but thus this is impossible to make safe: (shell)
    ## program1 | program2   where program1 returns an error code. program2 still continues without knowing that there has been an error.
    if (defined (my $cnt= sysread IN,$buffer,$maxfilesize+1  #####! this temporary allocates exactly $maxfilesize+1 bytes of memory regardless of the size of the file !!!  So should use local $/; $buffer=<IN>  regardless of problem of error checking ?  Or should I use mmap and copy from it? or stat to get the file size. Or loop with small buffer.   mmap does not work with pipes. but using sysopen it wouldn't anyways.
       )) {
        ##croak "Error reading from $file: $!" if $!+0; ## I'm testing $! here because I thought it could be there is an error in the middle of reading (i.e. nfs mount), and thus $cnt be set to some value. Wrong assumption?
        ##defined (sysread IN,$buffer,$maxfilesize+1) or die "JETZT fehler: $!"; nope still no error in case of "broken" inpipe.
        if (close IN) {
	    croak "File $file is too big" if $cnt > $maxfilesize;
	    \$buffer
        } else {
	    croak "Error closing $file: $!";
        }
    } else {
        croak "Error reading from $file: $!";
    }
}

sub getfilehandle($) {
    my ($file)=@_;
    no strict 'refs';
    my $in = \*{"Chj::fileutils::_SYMBOL" . $genseq};
    sysopen $in,$file, O_RDONLY or croak "Could not open $file for reading: $!";
    delete $Chj::fileutils::{"_SYMBOL".$genseq++} or die "??";
    $in
}

sub xsyswriteall(*$$) {
    my $rf= ref $_[1] ? $_[1] : \ $_[1];
    my $len= length $$rf;
    if ($len) {
	my $rest=$len;
	my $z= syswrite $_[0], $$rf;
	while(1) {
	    defined $z or croak "Error writing to $_[2]: $!";
	    $rest-= $z;
	    confess "??? rest=$rest" if $rest<0; ## just-in-case smile
	    last unless $rest;
	    warn "syswriteall: notice: didn't write everything in first attempt, $rest bytes or chars left"; ##
	    $z= syswrite $_[0], $$rf, $rest,$len-$rest;
	}
    }
}

sub createfile($;$$) {
    my ($file,$mode)=@_; # $bufferref is optional third arg
    $mode=0666 unless defined $mode;
    sysopen OUT, $file, O_EXCL|O_CREAT|O_WRONLY, $mode or croak "createfile: could not create $file: $!";
    eval {
        if (defined $_[2]) {
	    ## cj 28.7.03: rewritten to control actual amount of written size.
	    ## I think that on sockets syswrite will not guarantee to be all-or-nothing.
	    ## Dunno about files. perlfunc says "If LENGTH is not specified, writes whole SCALAR.",
	    ## but can we be sure about it? -> todo: check, and if necessary change rest of this file as well as maybe Chj::IO::* stuff, sigh.
	    xsyswriteall OUT,$_[2],$file;
        }
    };
    close OUT;
    die $@ if $@;
}


use constant MAXTRIES=> 10;

sub writebackfile($$;@) {
    my $file=shift;
    my $buffer= \(shift);
    my ($backupfilepath,$lcheckperms,$lstrictperms,$lsymlinks,$lrecreatesetid);
    if (@_ > 1) {
        croak "uneven number of optional arguments" if @_ % 2;
        local $_;
        for (my $i=0; $i<=$#_; $i+=2) {
            $_= $_[$i];
            if ($_ eq 'backupfilepath') { $backupfilepath=$_[$i+1] }
            elsif ($_ eq 'checkperms') { $lcheckperms=!!$_[$i+1] }
            elsif ($_ eq 'strictperms') { $lstrictperms=!!$_[$i+1] }
            elsif ($_ eq 'symlinks') { $lsymlinks= $_[$i+1] }
            elsif ($_ eq 'recreatesetid') { $lrecreatesetid= !!$_[$i+1] }
            else { croak "writebackfile: unknown argument $_" }
        }
    } else {
        $backupfilepath= shift;
    }
    # symlink
    my $slh= defined $lsymlinks? $lsymlinks : $symlinks;
    IF: {
        if ($slh) {
            if ($slh eq 'follow') {
                if (defined (my $orig= readlink $file)) {
                    if (substr($orig,0,1) eq "/") {
                        $file=$orig;
                    } else {
                        $file=~ /(.*?)[^\/]*$/s or die "???";
                        $file= $1.$orig;
                    }
                } elsif ($! == EINVAL) {
                    # no symlink
                } else {
                    croak "writebackfile: error following symlink: $!";
                }
                last IF;
            } elsif ($slh eq 'deny') {
                if (defined (my $isl=-l $file)) {
                    if ($isl) {
                        croak "writebackfile: '$file' is a symlink but settings deny them";
                    } 
                    last IF; 
                }
                croak "writebackfile: file '$file': $!";
            } elsif ($slh eq 'nofollow') {
                last IF;
            }
        }
        croak "writebackfile: unknown 'symlinks' setting";
    }
    # check perms
    if (defined $lcheckperms ? $lcheckperms : $checkperms) {
        sysopen TRY, $file, O_WRONLY or croak "writebackfile: can't write to file '$file': $! (note that permission checking is on)";
        close TRY;
    }
    # get perm info
    my ($oldmode,$uid,$gid)= (stat $file)[2,4,5] or croak "Could not stat $file: $!";
    # create new file
    my $tmpfile;
    croak "writebackfile: \$Chj::fileutils::tmpsuffix is undefined or empty" unless defined $tmpsuffix and length($tmpsuffix);
    if ($tmpsuffix=~ /\%/) {
        my $tries=0;
        TRY: {
            $tmpfile= $tmpsuffix;
            $tmpfile=~ s/\%/substr(rand(),2,5)/e;
            $tmpfile= $file.$tmpfile;
            if (sysopen OUT, $tmpfile, O_EXCL|O_CREAT|O_WRONLY, 0200) {
                last TRY;
            } elsif ($! == EEXIST or $! == EINTR) { # not sure whether the latter test is needed
                if (++$tries < MAXTRIES) {
                    redo TRY;
                } else {
                    croak "Too many attempts to create a tempfile for $file";
                }
            } else {
                croak "Could not open tempfile '$tmpfile' for writing: $!";
            }
        }
    } else {
        $tmpfile= $file.$tmpsuffix;
        sysopen OUT, $tmpfile, O_EXCL|O_CREAT|O_WRONLY, 0200 or croak "Could not open $tmpfile for writing (note that you should use a \% in the tmpsuffix): $!";
    }
    eval {
        #chmod 0, $tmpfile or die "??? $tmpfile: $!"; is pointless
        chown $uid,$gid,$tmpfile or do {
            if (defined $lstrictperms ? $lstrictperms : $strictperms) {
                unlink $tmpfile;
                croak "writebackfile: can't recreate permissions of '$file' and strictperms checking is on";
            }
        };
	xsyswriteall OUT,$$buffer,$tmpfile;
        chmod $oldmode & (
            (defined $lrecreatesetid ? $lrecreatesetid : $recreatesetid) ? 07777 : 01777 # allow sticky bit?
        ), $tmpfile or die "??? $tmpfile: $!";
	# do it *after* the syswrite or linux will delete the suid bit again
    };
    close OUT;
    die $@ if $@;
    if (defined $backupfilepath and length($backupfilepath)) {
        unlink $backupfilepath;
        link $file, $backupfilepath or carp "Could not keep '$file' as '$backupfilepath': $!";
    } elsif (defined $bcksuffix and length($bcksuffix)) {
        unlink $file.$bcksuffix;
        link $file, $file.$bcksuffix or carp "Could not keep '$file' as '$file$bcksuffix': $!";
    }
    rename $tmpfile, $file or croak "Could not overwrite old file $file: $!";
}

sub removefile {
    my $file=shift;
    if (defined $bcksuffix and length($bcksuffix)) {
        if (rename $file, $file.$bcksuffix) {
            return; # ok
        } else {
            carp "Could not keep '$file' as '$file$bcksuffix': $!";
        }
    }
    unlink $file or croak "Could not unlink '$file': $!";
}

=back

=cut

1;
