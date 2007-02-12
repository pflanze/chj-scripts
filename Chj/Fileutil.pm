# Sun Feb 11 17:39:15 2007  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
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
	      xEditfileln
	      xChecknolinks
	      xChecklink
	      xSymlink
	     );
%EXPORT_TAGS= (all=> \@EXPORT_OK);

use strict;

use Chj::xperlfunc;
use Chj::singlequote qw(singlequote singlequote_many);

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
	    die "dangling symlink at '$path'"; #ps chdir ist eben essentiell dass ausgegeben wird..
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

use Chj::xopen 'xopen_read';

sub xEditfileln ($ $ ) {
    my ($fn,$path)=@_;
    my $realpath= _Realpath ($path); #ps da wo ich xEditfile benütze wird eh zuerst auf symlinks geprüft.. also eigentlich unsinig 'aber egal'.
    Warn "editing '$realpath'";
    my $newcontent= $fn->( xopen_read($realpath)->xcontent );
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
    $v eq $value or die "expecting '$path' to be a symlink to '$value', but it's to '$v'";
}

sub xSymlink($ $ ) {
    my ($value,$path)=@_;
    Warn "ln -s '$value' '$path'";
    xsymlink $value,$path;
}


1
