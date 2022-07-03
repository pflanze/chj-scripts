# Thu Dec 23 00:45:34 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Util::Repl::corefuncs

=head1 SYNOPSIS

=head1 DESCRIPTION

Returns a list of all perl CORE functions

=cut

#'

package Chj::Util::Repl::corefuncs;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(corefuncs);

use strict;
use utf8;

{
    # for some reason I can't seem to find out how to get at that otherwise.
    my $txt=<<'END';
    
       Functions for SCALARs or strings
           "chomp", "chop", "chr", "crypt", "hex", "index", "lc", "lcfirst", "length",
           "oct", "ord", "pack", "q/STRING/", "qq/STRING/", "reverse", "rindex",
           "sprintf", "substr", "tr///", "uc", "ucfirst", "y///"

       Regular expressions and pattern matching
           "m//", "pos", "quotemeta", "s///", "split", "study", "qr//"

       Numeric functions
           "abs", "atan2", "cos", "exp", "hex", "int", "log", "oct", "rand", "sin",
           "sqrt", "srand"

       Functions for real @ARRAYs
           "pop", "push", "shift", "splice", "unshift"

       Functions for list data
           "grep", "join", "map", "qw/STRING/", "reverse", "sort", "unpack"

       Functions for real %HASHes
           "delete", "each", "exists", "keys", "values"

       Input and output functions
           "binmode", "close", "closedir", "dbmclose", "dbmopen", "die", "eof", "fileno",
           "flock", "format", "getc", "print", "printf", "read", "readdir", "rewinddir",
           "seek", "seekdir", "select", "syscall", "sysread", "sysseek", "syswrite",
           "tell", "telldir", "truncate", "warn", "write"

       Functions for fixed length data or records
           "pack", "read", "syscall", "sysread", "syswrite", "unpack", "vec"

       Functions for filehandles, files, or directories
           "-X", "chdir", "chmod", "chown", "chroot", "fcntl", "glob", "ioctl", "link",
           "lstat", "mkdir", "open", "opendir", "readlink", "rename", "rmdir", "stat",
           "symlink", "umask", "unlink", "utime"

       Keywords related to the control flow of your perl program
           "caller", "continue", "die", "do", "dump", "eval", "exit", "goto", "last",
           "next", "redo", "return", "sub", "wantarray"

       Keywords related to scoping
           "caller", "import", "local", "my", "our", "package", "use"

       Miscellaneous functions
           "defined", "dump", "eval", "formline", "local", "my", "our", "reset", "scalar",
           "undef", "wantarray"

       Functions for processes and process groups
           "alarm", "exec", "fork", "getpgrp", "getppid", "getpriority", "kill", "pipe",
           "qx/STRING/", "setpgrp", "setpriority", "sleep", "system", "times", "wait",
           "waitpid"

       Keywords related to perl modules
           "do", "import", "no", "package", "require", "use"

       Keywords related to classes and object-orientedness
           "bless", "dbmclose", "dbmopen", "package", "ref", "tie", "tied", "untie", "use"

       Low-level socket functions
           "accept", "bind", "connect", "getpeername", "getsockname", "getsockopt", "lis­
           ten", "recv", "send", "setsockopt", "shutdown", "socket", "socketpair"

       System V interprocess communication functions
           "msgctl", "msgget", "msgrcv", "msgsnd", "semctl", "semget", "semop", "shmctl",
           "shmget", "shmread", "shmwrite"

       Fetching user and group info
           "endgrent", "endhostent", "endnetent", "endpwent", "getgrent", "getgrgid",
           "getgrnam", "getlogin", "getpwent", "getpwnam", "getpwuid", "setgrent", "setp­
           went"

       Fetching network info
           "endprotoent", "endservent", "gethostbyaddr", "gethostbyname", "gethostent",
           "getnetbyaddr", "getnetbyname", "getnetent", "getprotobyname", "getprotobynum­
           ber", "getprotoent", "getservbyname", "getservbyport", "getservent", "sethos­
           tent", "setnetent", "setprotoent", "setservent"

       Time-related functions
           "gmtime", "localtime", "time", "times"

       Functions new in perl5
           "abs", "bless", "chomp", "chr", "exists", "formline", "glob", "import", "lc",
           "lcfirst", "map", "my", "no", "our", "prototype", "qx", "qw", "readline",
           "readpipe", "ref", "sub*", "sysopen", "tie", "tied", "uc", "ucfirst", "untie",
           "use"
END
  ;
    $txt=~ s/(\w)[-­]\s*(\w)/$1$2/sg;# careful: the -­ are two different chars.
    #print $txt;
    my @corefuncs= grep {
	length($_)>=3
    }
      $txt=~ /"(\w+)"/g;
    no warnings 'redefine';
    *corefuncs= sub {
	@corefuncs
    };
}

*Chj::Util::Repl::corefuncs= \&corefuncs;

1
