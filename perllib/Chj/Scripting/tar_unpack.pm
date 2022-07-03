#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Scripting::tar_unpack

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Scripting::tar_unpack;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(tar_unpack);
@EXPORT_OK=qw(maybe_compression_from_path);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::Scripting::tar_unpack::Unpacked;
use Chj::xtmpdir;
use Chj::xopendir;
use Chj::xopen 'xopen_read';
use Chj::xperlfunc;
use Carp;

sub maybe_compression_from_path ( $ ) {
    my ($path)=@_;
    $path=~ m|\.(\w+)\z| or return;
    my $suffix=lc $1;
    if ($suffix eq "tgz"
	or
	$suffix eq "gz"
       ) {
	"z"
    } elsif ($suffix eq "tbz"
	     or
	     $suffix eq "bz2"
	    ) {
	"j"
    } elsif ($suffix eq "tar") {
	""
    } else {
	undef # for now; might be lzop or others
    }
}

sub tar_unpack ($ ; $ $ ) {
    my ($path,$opt_tmpdirbase,$opt_mask)=@_;
    defined(my $compression=maybe_compression_from_path ($path))
      or croak "path does not end in a recognizable compression: '$path'";
    my $dir= xtmpdir $opt_tmpdirbase,$opt_mask; #dank perl undef geht das passing so gut das is eben 'aber' einfach gut.
    my $fh= xopen_read $path;
    if (xfork) {
	xxwait;
    } else {
	#xchdir $dir;  wow: chdir() on unopened filehandle GEN4
	xchdir "$dir"; #so much to overloading hehe...  .really.
	$fh->xdup2(0);
	xexec "tar" , "xf$compression", "-"
    }
    $dir->autoclean(0);
    # return the path of the unpacked thing.
    my $d= xopendir $dir;
    #my @items= <$d>; #ehr?
    #ah aber immerhin hab ich in xnread list context er kennen   heh "".
    my @items= $d->xnread;
    @items==1 or die "expecting 1 item, got @items"; ##wel. every tar can do this.
    Chj::Scripting::tar_unpack::Unpacked->new("$dir",$items[0],1)
}

1
