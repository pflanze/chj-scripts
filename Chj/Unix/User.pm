# Mon Jun 16 02:34:21 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::Unix::User

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item su ( username )

Does set the secondary groups, real and effective gid and uid of the
process, so that a subsequent fork (which is needed to give up root at
least on unix, since perl does not offer direct access to the saved
uid/gid) will release root and become completely that user. Also
changes the HOME and USER environment variables.

Only works when called as root. Throws exceptions when user not found
(and maybe others). But does *not* yet throw an exception when $< or
$> are not being changed.

NOTE: there might be further dangerous things like open files.

=item su_chroot ( username, chroot_dir [, chdir_dir ] )

Same as su, but does a chroot call and chdir's to chdir_dir or "/"
before dropping root privs.

=item su_chroot_tty ( username, chroot_dir [, chdir_dir ] )

Same as su_chroot, but does a chown $user `tty` so that programs like
screen will work when running as the target user. (BTW, this problems
happens in fact with the standard 'su' utility on Debian. I don't know why
I have never seen the need for that using linuxppc.)

=back

=head1 DANGEROUS

Be careful with the following issues:

=over 4

=item su_chroot_tty may be dangerous

Stdin may have been redirected for setuid programs.
When using su_chroot_tty in such a program, it will change the /dev/pts/* device
of the stdin fd. Well it shouldn't be dangerous since non-root users cannot open
any /dev/pts/* for input unless they already own it. But still.. maybe you're giving
it to another user which may then also read data input which you enter in another
user context on the same pts device (i.e. put su_chroot_tty'ing program into background
and continue to work as root on the same device?!).

=item 

=back

=head1 NOTES

Not yet much tested.

- maybe it should exec right away as well, like the shell su, so it cannot be used dangerously?.

- note that terminating a parent using ctl-c kills the child as well (it does not create a new process group (btw is this a danger in and it itself too already?)); it's not a daemon gerating thing. and not like su foo & in the shell, either, right? or how does sh handle it?

- CAREFUL: you can't even use it (without exec) for checking file system acesses. Like this
 perl -w -MChj::Unix::User=su -ne 'BEGIN{ su "fuu" } chomp; if (stat $_) { print "accessible: $_\n";} else { print "$! $_\n" }'
run as the root user will say a path is accessible if the parent directory is owned by root (but not if owned by another user); seemingly the saved(?) uid which is still 0 does not have super power in this case but still does owner matching and then 'spoils' the 'access check'.

=cut


package Chj::Unix::User;
@EXPORT_OK=qw(su su_chroot su_chroot_tty);
@ISA="Exporter";
require Exporter;

use strict;
use Carp;
use Chj::Unix::Groups 'secondarygroups';
use Chj::xperlfunc; # xreadlink

sub su {
    die "wrong number of arguments" unless @_==1;
    my ($username)=@_;

    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$homedir,$shell,$expire)
      = getpwnam($username)
	or die "unknown user '$username'";

    my @supplgroups= secondarygroups $username;

    #print "User $uid has main group $gid and supp groups @supplgroups\n";

    $(= $gid; $)= "$gid @supplgroups"; #QUESTION: groups with spaces in their name ? TODO is it ever safe? probably not?........
    $<= $uid; $>= $uid;

    (($< == $uid) and ($> == $uid)) or die "could not change uid";#oder ist das auch falsch? ah nein scheint zu gehen ok so.   eben, aufgepasst, obwohl die saved uid nochimmer root ist. solang kein exec gemacht wird.

    $ENV{HOME}=$homedir;
    $ENV{USER}=$username;
    #$ENV{LOGNAME}
    #$ENV{MAIL}
    #$ENV{PATH}
}

sub tty {
    # will only work on linux!
    $^O eq 'linux' or croak "tty: currently only implemented for linux";
    my $tty= xreadlink "/proc/self/fd/0";
    #$tty=~ /(.*)/s; # trust it, for -T    oh, dangerous!: may be any file!!!!!!!
    $tty=~ m{(^/dev/pts/\d+\z)}s # well, may still be very dangerous! do not use if fd 0 can be set by other user!
      or croak "tty: fd 0 is not a pts tty";
    $1
}

sub su_chroot {
    my ($username,$chroot,$dir,$do_chowntty)=@_;

    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$homedir,$shell,$expire)
      = getpwnam($username)
	or die "unknown user '$username'";

    if ($do_chowntty){
	#my $tty= `/usr/bin/tty`; chomp $tty;
	my $tty= tty;
	eval {
	    my $ttygid= (xstat $tty)->gid;
	    xchown $uid,$ttygid,$tty;
	};
	if ($@) {
	    warn "su_chroot: warning: $@";
	}
    }

    my @supplgroups= secondarygroups $username;

    #print "User $uid has main group $gid and supp groups @supplgroups\n";

    $(= $gid; $)= "$gid @supplgroups";

    $dir= "/" unless defined $dir;
    #chdir $chroot or croak "su_chroot: chdir '$chroot': $!";
    chroot $chroot or croak "su_chroot: chroot '$chroot': $!";
    chdir $dir or croak "su_chroot: chdir '$dir': $!";

    $<= $uid; $>= $uid;

    $ENV{HOME}=$homedir;
    $ENV{USER}=$username;
    #$ENV{LOGNAME}
    #$ENV{MAIL}
    #$ENV{PATH}
}

sub su_chroot_tty {
    su_chroot $_[0],$_[1],$_[2],1
}

1;
