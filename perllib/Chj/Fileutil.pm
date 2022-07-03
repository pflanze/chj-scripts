# Sun Feb 11 17:39:15 2007  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Fileutil

=head1 SYNOPSIS

=head1 DESCRIPTION

File handling functions. For easy file handling/editing. ("shell-like"?)

Note that all functions do turn basic error checking into
exceptions. The x* functions though do not signal (non-fundamental)
failure through a return value, but through exceptions as well.

E.g. Getlock will throw exceptions if the file does not exist or
there's no permission opening it rw. (Ok, should this be prepended
with x ? Do I ever know?)


=head1 FUNCTIONS

...

=item MsgfileRead

A way to read from such 'msgfiles' from bash is (assuming it has been
terminated with a newline when writing):

 while true; do
     read msg < foo
     ...
 done

(In my tests with small messages bash did read them in one read call.)

NOTE: MsgfileWrite and MsgfileRead now use flock. On SMP machines on
Linux they *only* safe this way. So if you read from bash instead, you
*should* be using flock locking, too. (The idea of "atomic writes"
doesn't work anymore on smp.)

=cut


package Chj::Fileutil;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      Warn
	      xRun
	      xxRun
	      xChdir
	      xUnlink
	      _Realpath
	      xWritefileln
	      xDirectWritefileln
	      MsgfileWrite
	      MsgfileRead
	      xCatfile
	      MaybeCatfile
	      xChompCatfile
	      MaybeChompCatfile
	      xEditfileln
	      xChecknolinks
	      xChecklink
	      xSymlink
	      Getlock
	      Existglob
	     );
%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;
use utf8;

use Chj::xperlfunc;
use Chj::singlequote qw(singlequote singlequote_many);
use Chj::xopen ':all';

our $verbose=1;

sub Warn {
    print STDERR @_,"\n" if $verbose;
}

sub xRun {
    Warn "running ".singlequote_many(@_);
    xsystem @_;
}
sub xxRun {
    Warn "running ".singlequote_many(@_);
    xxsystem @_;
}
sub xChdir ($ ) {
    my ($dir)=@_;
    Warn "cd to ".singlequote ($dir);
    xchdir $dir;
}
sub xUnlink {
    Warn "unlinking ".singlequote_many (@_);
    xunlink $_ for @_;
}

use Chj::Cwd::realpath;

sub _Realpath ($ ) {
    #do about the same as my "e" editor starter setup
    my ($path)=@_;
    realpath ($path) || do {
	if (-l $path) {
	    die "dangling symlink at '$path'";
	    # ^ ps chdir ist eben essentiell dass ausgegeben wird..
	} else {
	    $path
	}
    };
}

use Chj::xtmpfile;

sub xWritefileln ($ $ ) {
    my ($str,$path)=@_;#hatt ich zuerst reihenfolge umgekehrt
    my $realpath= _Realpath ($path);
    Warn "writing to '$realpath'";
    my $f= xtmpfile $realpath;
    $f->xprint ($str);
    $f->xprint ("\n") unless $str=~ /\n\z/s;
    $f->xclose;
    $f->xputback(0644);
}

sub xDirectWritefileln ($ $ ) {
    my ($str,$path)=@_;
    ##open feature: giving perms ?
    #my $realpath= _Realpath ($path); why?
    Warn "writing '$str' to '$path'";
    my $f= xopen_write($path);
    $f->xprint($str,"\n");
    $f->xclose;
}

use Fcntl ':DEFAULT';
use Encode '_utf8_off';

# overwrites existing file: with the guarantee so-I-hope that the
# resulting file always contains a valid $str message up to the given
# boundary even without locking.

our $maxmsgsize= 1000;
# including the delimiter; riel says "the writer locks the page". But
# does this guarantee anything about tail-merged etc. files on a file
# system ?

# use POSIX; ..  sysconf _SC_PAGESIZE  ; if it's of use at all.

use Fcntl ":flock";

sub MsgfileWrite ($ $ ; $ ) {
    my ($path,$msg,$maybe_endchar)=@_;
    # ^ NOTE that the order of the path/contents arguments is reversed
    # compared with xWritefileln!
    # expects the file to exist already
    _utf8_off($msg); # so we can reliably check the length. ok?
    $msg.= defined($maybe_endchar) ? $maybe_endchar : "\0";
    my $msglen= length ($msg);
    # be kind and already fail while writing, not only when reading:
    $msglen<= $maxmsgsize
      or die "message exceeds maxmsgsize ($msglen instead of $maxmsgsize)";
    my $out;
    sysopen $out, $path, O_WRONLY
      # |O_TRUNC is of no use. except to reclaim space, but would have
      # the drawback of the reader having to check for emptyness.
      or die "could not open file '$path' for writing: $!";
    flock($out,LOCK_EX)
      or die "could not get exclusive lock on '$path': $!";
    my $len= syswrite $out, $msg;
    defined $len or die "could not write to '$path': $!";
    $len == $msglen
      or die "could not write the whole message at once to '$path', "
	."only $len bytes of $msglen";
    close ($out) or die "error closing '$path': $!";
}

sub MsgfileRead ($ ; $ ) {
    my ($path, $maybe_delim)=@_;
    my $f;
    sysopen $f, $path, O_RDONLY
      or die "could not open '$path' for reading: $!";
    flock($f,LOCK_SH)
      or die "could not get shared lock on '$path': $!";
    # ^ and yes, this is absolutely required on smp systems; flock in
    # the writers alone doesn't guarantee messages being read back in
    # whole pieces.
    my $msg;
    defined (sysread( $f,$msg, $maxmsgsize))
      or die "could not read from '$path': $!";
    my $delim= defined ($maybe_delim) ? $maybe_delim : "\0";
    $msg=~ s/${delim}.*//s or die "missing delimiter in '$path'";
    $msg
}

sub xCatfile ( $ ) {
    my ($path)=@_;
    xopen_read($path)->xcontent
}

##todo move to a util lib!
sub Maybeed ( $ ) {
    my ($proc)=@_;
    sub {
	my ($path)=@_;
	#[EVER same issue. with list context. ah no, I didn't overload it
	# anyway, xcontent is not working for list context right.]
	# hm but for the general case it will be an issue as ever.
	#  [could that liststuff part be a util in itself?..]
	my $res= eval {
	    &$proc ($path)
	};
	my $e=$@; my $errno= $!+0;
	if (ref $e or $e) {
	    #if ($e =~ /no such file/i) { ##todo EWIG HACK of how should i do it. ah and parametrize it anyway for the general case!
	    #and no it doesn't work anyway with different locales. no no no, larry w.
	    if ($errno and $errno==2) { ## hardcode, fine fine.todo.
		undef
	    } else {
		die $e
	    }
	} else {
	    $res
	}
    }
}

##todo move to a util lib!
sub Chomped ( $ ) {
    my ($proc)=@_;
    sub {
	if(defined (my $res= &$proc (@_))) {
	    #chomp $res; ps. NO NO NO, this is not like the shell backticks.
	    $res=~ s/\s+\z//s;
	    $res
	} else {
	    undef
	}
    }
}

*MaybeCatfile= Maybeed (\&xCatfile);
*xChompCatfile= Chomped (\&xCatfile);
*MaybeChompCatfile= Chomped (\&MaybeCatfile);

sub xEditfileln ($ $ ) {
    my ($fn,$path)=@_;
    my $realpath= _Realpath ($path);
    # ^ ps da wo ich xEditfile benütze wird eh zuerst auf symlinks
    # geprüft.. also eigentlich unsinig 'aber egal'.
    Warn "editing '$realpath'";
    my $newcontent= $fn->( xCatfile ($realpath) );
    my $f= xtmpfile $realpath;
    $f->xprint ($newcontent);
    $f->xprint ("\n") unless $newcontent=~ /\n\z/s;
    $f->xclose;
    $f->xputback(0644);
}

sub xChecknolinks($ ) {
    my ($path)=@_;
    my @parts= split /\/+/, $path;
    @parts or die "xChecknolinks: empty path argument given";
    my $tmp= do {
	if ($parts[0] eq "") {
	    shift @parts;
	    "/"
	} else {
	    ""
	}
    };
    for (@parts) {
	$tmp.= $_;
	if (-l $tmp) {
	    die "xChecknolinks ('$path'): '$tmp' is a symlink";
	}
	if (-e $tmp) {
	    #ok
	} else {
	    die "xChecknolinks ('$path'): there's no '$tmp'";
	}
	$tmp.= "/";#strange reihenfolg
    }
}

sub xChecklink($ $ ) {
    my ($path,$value)=@_;
    my $v= readlink ($path);
    defined $v or die "expecting '$path' to be a symlink, but it's not";
    $v eq $value
      or die "expecting '$path' to be a symlink to '$value', but it's to '$v'";
}

sub xSymlink($ $ ) {
    my ($value,$path)=@_;
    Warn "ln -s '$value' '$path'";
    xsymlink $value,$path;
}

use Fcntl ':DEFAULT',':flock'; # DEFAULT already imported, though

sub Getlock ($ ; $ ; $ ; $ ) {
    my ($path,$maybe_waitingmsg, $maybe_create_mode, $flag_excl)=@_;
    # ^ create_mode is actually umask exposed ("is subject to the
    # current umask")
    my $lck;
    do {
	if (defined ($maybe_create_mode)) {
	    sysopen($lck,
		    $path,
		    O_RDWR|O_CREAT|($flag_excl ? O_EXCL : 0),
		    $maybe_create_mode);
	} else {
	    sysopen $lck, $path, O_RDWR;
	}
    } or die "opening lock '$path' for reading/writing: $!";
    if (flock($lck, LOCK_EX| LOCK_NB)) {
	$lck
    } else {
	if (defined $maybe_waitingmsg) {
	    if ($maybe_waitingmsg) {
		print STDERR $maybe_waitingmsg
	    }
	    #else be silent
	} else {
	    print STDERR "waiting for lock '$path'..";
	}
	flock ($lck, LOCK_EX);
	if ($maybe_waitingmsg or !defined ($maybe_waitingmsg)) {
	    print STDERR "ok.\n";
	}
	$lck
    }
}

sub Existglob ( $ ) {
    my ($gl)=@_;
    grep {
	-e $_
    } glob $gl
}

1
