#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Recordip

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::App::Recordip;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(datadir);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Carp;

our $myname= "recordip"; # fix that.
our $default_user= $myname; # the user the 'recordip' cronjob runs at, usually.

{
    package Chj::App::Recordip::Datadir;
    use Class::Array -fields=>
      -publica=>
	(
	 'path',
	);
    ##grr forgotten grr:
    sub new {
	my $class=shift;
	my $s=$class->SUPER::new;
	($$s[Path])=@_;
	$s
    }
    ##/grr
    sub subdir {
	my $s=shift;
	my ($subdir)=@_;
	ref($s)->new("$$s[Path]/$subdir");
    }
    sub make {
	my $s=shift;
	my ($perms)=@_;
	mkdir $$s[Path],$perms
    }
    sub subdir_make {
	my $s=shift;
	my ($subdir)=@_;
	my $sub= $s->subdir ($subdir);
	mkdir $sub->path;
	$sub
    }
    use Chj::FileStore::MIndex;
    use Chj::FileStore::PIndex;
    sub ip_and_attr_stores {
	my $datadir=shift;
	my $ips= Chj::FileStore::MIndex->new
	  ($datadir->subdir_make("ip_store")->path);
	my $attrs= Chj::FileStore::PIndex->new
	  ($datadir->subdir_make("attr_store")->path);
	($ips,$attrs)
    }
    end Class::Array;
}

sub datadir ( $ ) {
    my ($use_default_user)=@_;
    my $opt_home= do {
	if ($use_default_user) {
	    my ($name,$passwd,$uid,$gid,
		$quota,$comment,$gcos,$dir,$shell,$expire)
	      = getpwnam $default_user
		or die "could not look up user '$default_user'";
	    $dir
	} else {
	    undef
	}
    };
    Chj::App::Recordip::Datadir->new
	(do{$opt_home || $ENV{HOME}|| croak "missing HOME env var"}."/.$myname");
}



1
