#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Git::Patchid

=head1 SYNOPSIS

 use Chj::Git::Patchid;
 our $patchid= new Chj::Git::Patchid (); # or give git_dir, or also cache_base
 $patchid->of_commitid($commitid)
 $patchid->maybe_commitid_of_patchid($patchid)

=head1 DESCRIPTION

The cache file remembers patchid<->commitid mappings. It is unsorted,
but read once per object [or after calling ->forget].

=cut


package Chj::Git::Patchid;

use strict;

use Class::Array -fields=>
  -publica=>
  'git_dir',
  'cache_base',
  'cache', # hash
  ;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Git_dir, Cache_base])=@_;
    $s
}

use Chj::Xbacktick;
use Chj::Chomp;

sub git_dir {
    my $s=shift;
    $$s[Git_dir]||= do {
	Chomp (scalar Xbacktick(qw(git rev-parse --git-dir)));
    }
}

sub cache_base {
    my $s=shift;
    $$s[Cache_base]||= do {
	$s->git_dir . "/chj_git_patchid."
    }
}

sub cache_file {
    my $s=shift;
    $s->cache_base . "cache"
}
# why did I not leave cache_base field as cache_file if I only use one
# file anyway? anyway.

sub forget {
    my $s=shift;
    undef $$s[Cache]
}

use Chj::xopen qw(xopen_read xopen_append);

our $sha1= qr([a-f0-9]{40});

sub assert_commitid {
    my($commitid)=@_;
    $commitid=~ /^$sha1\z/
      or die "not a commitid: '$commitid'";
}

sub cache {
    my $s=shift;
    $$s[Cache]||= do {
	my $p2c={};
	my $c2p={};
	my $file= $s->cache_file;
	if (-e $file) {
	    my $f= xopen_read $file;
	    while (<$f>) {
		chomp;
		my ($patchid,$commitid)= /^((?:$sha1)|) ($sha1)\z/s
		  or die "invalid entry in '$file': '$_'";
		$$p2c{$patchid}= $commitid;
		$$c2p{$commitid}= $patchid;
	    }
	    $f->xclose;
	}
	[$p2c, $c2p]
    }
}

sub cache_patchid {
    my $s=shift;
    $s->cache->[0]
}

sub cache_commitid {
    my $s=shift;
    $s->cache->[1]
}

use Chj::IO::Command;
use Chj::xtmpfile;

sub Patchid_line {
    my ($commitid)=@_;
    assert_commitid($commitid);
    #warn "recalculating Patchid for $commitid";#
    my $in= Chj::IO::Command->new_sender(qw(git diff-tree -p -M50 -C60),
					 $commitid);
    my $end= xtmpfile;
    my $out= Chj::IO::Command->new_receiver_with_stdout_to_fh
      ($end, qw(git patch-id));
    $in->xsendfile_to($out);
    $in->xxfinish;
    $out->xxfinish;
    $end->xrewind;
    my $res= Chomp(scalar $end->xcontent);
    $end->xclose;
    $res
}

sub of_commitid {
    my $s=shift;
    my ($commitid)=@_;
    assert_commitid($commitid);
    #$s->cache_commitid->{$commitid} || do {
    my $p_id= $s->cache_commitid->{$commitid};
    if (defined $p_id) {
	$p_id
    } else {
	my $line= Patchid_line($commitid);
	my ($patchid,$_commitid)= split /\s+/, $line;
	if (defined $_commitid) {
	    $_commitid eq $commitid or die "bug, '$_commitid' != '$commitid'";
	} else {
	    #$patchid eq "" or die "bug, '$patchid'";
	    defined $patchid and die "bug, '$patchid'";
	    $patchid=""
	}
	my $file= $s->cache_file;
	my $f= xopen_append $file;
	$f->xprint("$patchid $commitid\n");
	$f->xclose;
	# and into mem, too.. (or just 'forget' ?)
	$s->cache_commitid->{$commitid}= $patchid;
	$s->cache_patchid->{$patchid}= $commitid;
	#$s->forget;
	#$s->of($commitid)
	$patchid
    }
}

sub maybe_commitid_of_patchid {
    my $s=shift;
    my ($patchid)=@_;
    assert_commitid($patchid);
    $s->cache_patchid->{$patchid}
}

end Class::Array;
