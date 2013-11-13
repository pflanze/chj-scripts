#
# Copyright 2013 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Linux::Mountinfo

=head1 SYNOPSIS

 use Chj::Linux::Mountinfo ":all";
 map {
     $_->dev
     # or: mountpoint, type, options, fsck, fsck_order
 } mounts
 map {
     $_->mountpoint
     # etc., see @fields for list of methods
 } mountinfos

=head1 DESCRIPTION

mountinfo is useful even within chroots. mounts is not.

=cut


package Chj::Linux::Mountinfo;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(mounts mountinfos);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# I still wonder why /proc/mounts, which is meant to be used as
# symlink target for /etc/mtab, doesn't work usefully for chroots,
# while /proc/self/mountinfo does have the correct information but not
# the right format.

use Chj::xopen 'xopen_read';

{
    package CHJ::Mount;
    sub dev { my $s=shift; $$s[0] }
    sub mountpoint { my $s=shift; $$s[1] }
    sub type { my $s=shift; $$s[2] }
    sub options { my $s=shift; $$s[3] }
    sub fsck { my $s=shift; $$s[4] }
    sub fsck_order { my $s=shift; $$s[5] }
}

sub mounts {
    my $f= xopen_read "/proc/mounts";
    my @m;
    while (<$f>) {
	my @f= split " ";
	@f == 6 or die "line in /proc/mounts with different number of fields";
	# ^ XXX does linux provide some form of escaping?
	push @m, bless \@f, "CHJ::Mount";
    }
    $f->xclose;
    @m
}

{
    package CHJ::Mountinfo;
    our @fields=qw(dunno1 dunno2 dev_major_minor from mountpoint options
		   dunno3 type1 type2 moreoptions);
    my $i=0;
    for (@fields) {
	no strict 'refs';
	my $idx= $i;
	*$_= sub { my $s=shift; $$s[$idx] };
	$i++
    }
    sub dev {
	my $s=shift;
	my @d= split ":", $s->dev_major_minor;
	$d[0]*256 + $d[1]
    }
}

sub mountinfos {
    my $path= "/proc/self/mountinfo";
    my $f= xopen_read $path;
    my @m;
    while (<$f>) {
	my @f= split " ";
	@f == @CHJ::Mountinfo::fields
	  or die "line in $path with different number of fields: '$_'";
	push @m, bless \@f, "CHJ::Mountinfo";
    }
    $f->xclose;
    @m
}

1
