# Sun May 25 12:53:15 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::xsysopen

=head1 SYNOPSIS

 use Chj::xsysopen;
 my $f= xsysopen "hello",O_CREAT|O_EXCL|O_WRONLY;
 $f->xprint("World");
 # etc., see L<Chj::xopen>.

=head1 DESCRIPTION

Same as Chj::xopen but uses perl's sysopen call.

Now also loads and exports the Fcntl constants (note that seemingly this does not interfer with you already having imported Fcntl yourself).

=head1 MORE FUNCTIONS

These have useful sets of opening modes hard coded.
Those that are capable of creating a file take the permissions as optional second
argument.

=over 4

=item xsysopen_readwrite

Opens a file readwrite, creating it if it doesn't already exist.

=item xsysopen_update

Open a preexisting file readwrite.

=item xsysopen_append

Open a file in append mode, creating it if necessary (same as
xopen_append, but supports an umask as second argument).

=item xsysopen_uappend

Update a file in append mode, meaning it must exist already.

=back

=head1 SEE ALSO

L<Chj::IO::File>, L<Chj::xopen>, L<Chj::xopendir>

=cut

# changelog:
# Wed, 21 Jul 2004 00:30:13 +0200
#  *warum* habe ich mit xsysopen_excl so lange gewartet? nurweilichtmpfilehabe? egal.

#';

package Chj::xsysopen;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xsysopen
	    O_APPEND O_ASYNC O_CREAT O_DEFER O_EXCL O_NDELAY O_NONBLOCK
	    O_SYNC O_TRUNC
	    O_RDONLY O_WRONLY O_RDWR
	   );
#  LOCK_SH LOCK_EX LOCK_NB LOCK_UN
#	    SEEK_SET SEEK_CUR SEEK_END

@EXPORT_OK= qw(xsysopen_read
	       xsysopen_write
	       xsysopen_readwrite
	       xsysopen_update
	       xsysopen_append
	       xsysopen_uappend
	       xsysopen_excl
	      );
%EXPORT_TAGS= (all=> [@EXPORT, @EXPORT_OK]);


use strict;

use Chj::IO::File;
use Fcntl qw(:DEFAULT :flock :seek :mode);

sub xsysopen { ## should i prototype arguments?
    unshift @_,'Chj::IO::File';
    goto &Chj::IO::File::xsysopen;
}

sub xsysopen_read {
    my ($path)=@_;
    xsysopen $path,O_RDONLY;
}
sub xsysopen_write {
    my ($path,$perms)=@_;
    if (defined $perms) { # sigh, needed because of the way xsysopen/CORE::sysopen works
	xsysopen $path,O_WRONLY|O_CREAT,$perms;
    } else {
	xsysopen $path,O_WRONLY|O_CREAT;
    }
}
sub xsysopen_readwrite {
    my ($path,$perms)=@_;
    if (defined $perms) {
	xsysopen $path,O_RDWR|O_CREAT,$perms;
    } else {
	xsysopen $path,O_RDWR|O_CREAT;
    }
}
sub xsysopen_update {
    my ($path)=@_;
    xsysopen $path,O_RDWR;
}
sub xsysopen_append {
    my ($path,$perms)=@_;
    if (defined $perms) {
	xsysopen $path,O_WRONLY|O_APPEND|O_CREAT,$perms;
    } else {
	xsysopen $path,O_WRONLY|O_APPEND|O_CREAT
    }
}
sub xsysopen_uappend {
    my ($path)=@_;
    xsysopen $path,O_WRONLY|O_APPEND;
}
sub xsysopen_excl {
    my ($path,$perms)=@_;
    if (defined $perms) {
	xsysopen $path,O_EXCL|O_WRONLY|O_CREAT,$perms;
    } else {
	xsysopen $path,O_EXCL|O_WRONLY|O_CREAT
    }
}

1;
