#
# Copyright 2013-2020 by Christian Jaeger, christian at jaeger mine nu
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
    my $pre_jessie= [
        # '14 20 0:13 / /sys rw,nosuid,nodev,noexec,relatime - sysfs sysfs rw'
        qw(dunno1 dunno2 dev_major_minor from mountpoint options
        dunno3 type1 type2 moreoptions)
        # 10
        ];
    my $jessie= [
        qw(dunno1 dunno2 dev_major_minor from mountpoint options
        dunno3 dunno4 type1 type2 moreoptions)
        # 11
        ];
    my $stretch= [
        # '35 14 0:6 / /sys/kernel/debug rw,relatime shared:21 - debugfs debugfs rw'
        qw(dunno1 dunno2 dev_major_minor from mountpoint options
        dunno5 type1 type2 moreoptions)
        # 10, ??? when line above has 11
        ];
    my $release_name_to_fields= +{
        jessie=> $jessie,
        stretch=> $stretch,
        buster=> $stretch, # just assuming
        bullseye=> $stretch, # just assuming
    };
    our @fields= do {
	my $v= `cat /etc/debian_version`;
        # XX why am I checking debian_version when it's just the
        # *kernel*?
	my ($maybe_version)= $v =~ /^(\d+)\./;
	if ($maybe_version) {
	    if ($maybe_version < 8) {
                @$pre_jessie
	    } else {
		@$jessie
	    }
	} else {
	    if (my ($release_name)= $v=~ m|^([a-z]{3,})/|) {
		if (my $fields= $$release_name_to_fields{$release_name}) {
		    @$fields
		} else {
		    die "don't know how to handle release '$release_name'";
		}
	    } else {
		die "no match for release name in: '$v'";
	    }
	}
    };
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
    local $_;
    while (<$f>) {
	my @f= split " ";
	@f == @CHJ::Mountinfo::fields
	  or die "line in $path with different number of fields, ".@f." instead of ".@CHJ::Mountinfo::fields.": '$_'";
	push @m, bless \@f, "CHJ::Mountinfo";
    }
    $f->xclose;
    @m
}

1
