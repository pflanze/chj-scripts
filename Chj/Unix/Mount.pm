# Tue Jun 17 11:33:57 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Unix::Mount

=head1 SYNOPSIS

 use Chj::Unix::Mount 'mount_if_not_already';
 mount_if_not_already qw(-t tmpfs tmpfs /tmp);

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item mount [options,]source,dest

=item umount source or dest  (or any arguments the mount command can cope with)

=item mounted dest

Returns true if something is mounted on dest, false otherwise.

=item mount_if_not_already  [options,] source, dest

Do nothing if something is mounted on dest, otherwise run mount command.
'dest' must be the last argument.

=back

=head1 EXCEPTIONS

All of those functions die on error, you don't need to check return values
(except for those of 'real' functions delibaretly returning values).

=cut


package Chj::Unix::Mount;
@EXPORT_OK=qw(mount mounted umount mount_if_not_already xmount xumount);
@ISA="Exporter";
require Exporter;

use strict;
use Carp;
use Chj::xperlfunc;
use Chj::xopen;
use Chj::Cwd::realpath;
use POSIX qw(ENOENT);

our $mount= "/bin/mount";
our $umount= "/bin/umount";
our $DEBUG=0;

# string utility:
sub starts_with {
    my ($str,$with)=@_;
    substr($str,0,length($with)) eq $with
}

sub mount {
    xsystem $mount,@_
}
sub xmount {
    xxsystem $mount,@_
}

sub umount {
    xsystem $umount,@_
}
sub xumount {
    xxsystem $umount,@_
}

sub mounted {
    my ($dir)=@_;
    #$dir=~ s/\/{2,}/\//sg;
    #$dir=~ s/\/\z//s;
    eval {
	$dir= xrealpath $dir;
    };
    if ($@) {
	if ($! == ENOENT) {
	    return 0;
	}
	die
    }
    warn "mounted: checking for '$dir'.." if $DEBUG;
    my $f=xopen "/proc/mounts";
#     while(defined(my$line=$f->xreadline)){
# 	if ($line=~ /^\S+\s+\Q$dir\E\s+/) {
# 	    warn "mounted: returning true" if $DEBUG;
# 	    return 1
# 	}
#     }
    # old mechanism didn't check if a mount point is "overmounted" again later on. Thus we have to do:
    my $res=0;
    while(defined(my$line=$f->xreadline)){
	$line=~ /^\S+\s+(.*?) \S+\s+\S+\s+\S+\s+\S+\s*$/o
	  or do{ chomp $line; die "invalid format of /proc/mounts line: '$line'"; };
	my $cur=$1;
	if ($cur eq $dir) {
	    warn "mounted: found it mounted" if $DEBUG;
	    $res=1;
        } else {
	    if ($res==1) {
		# check for later "overmounts"
		if (starts_with $dir,$cur) {
		    warn "mounted: found it masked with '$cur'" if $DEBUG;
		    $res=0;
		}
	    }
	}
    }
    warn "/mounted: returning $res" if $DEBUG;
    $res
}

sub mount_if_not_already {
    # extract source and dest:
    # my ($source,$dest);
    # for(@_){
    #   next if /^-/;
    #   #	defined $source ? defined $dest ? croak "too many non-option arguments"
    #   #	  : $dest=$_
    #   #	    : $source=$_;
    #   # was ist oben falsch?
    #   if (defined $source) {
    #       if (defined $dest) {
    #   	croak "mount_if_not_already: too many non-option arguments"
    #       } else {
    #   	$dest=$_;
    #       }
    #   } else {
    #       $source=$_;
    #   }
    # }
    my $dest= $_[$#_];
    mounted( $dest) ? return : mount @_   ## klammmern mandatory....!!
}

die "currently only works on linux" unless $^O =~ /linux/;
#die "only works if /proc is mounted" unless mounted "/proc"; hehe
die "only works if /proc is mounted" unless -e "/proc/mounts";

1;
