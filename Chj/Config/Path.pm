# Sun Oct 24 20:17:18 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Config::Path

=head1 SYNOPSIS

=head1 DESCRIPTION

Some functions for determining system dependent values.

=head1 FUNCTIONS

=over 4

=cut


package Chj::Config::Path;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(max_filename_length
	      max_path_length
	      trunc_max_filename_length
	     );
use strict;
use Carp;

# currently only implemented on unix
use POSIX;

=item max_filename_length ( filepath )

=cut

{ # This exists only to hide this ugly firsttime-warning 'Argument "somepath" isn't numeric in subroutine entry at /usr/lib/perl/5.6.1/POSIX.pm line 38.' on debian woody (sarge is ok anyway)
    my $inited;
    sub __initPOSIX {
	return if $inited;
	local $^W;
	POSIX::pathconf("somepath", &POSIX::_PC_NAME_MAX);
	$inited++;
    }
}

sub _may_any_length( $ ) {
    my ($fnname, $constant, $path, $maybe_originalpath)=@_;
    #warn "_may_any_length $fnname $constant $path";
    __initPOSIX;
    if (defined (my $rv= POSIX::pathconf($path, $constant))) {
	$rv
    } else {
	my $errno= $!+0;
	my $errstr= "$!";
	if (!$maybe_originalpath and $errno == ENOENT) {
	    # try with parent dir:
	    my $p=$path;
	    # 3 cases:  foo/  /   /foo   and, which we don't consider?, foo/.. and similar.hm.(todo make a real fix?)
	    if ($p=~ s|[^/]+/*\z||s) {
		$p="." unless length $p;
		@_= ($fnname, $constant, $p, $path);
		goto \&_may_any_length;
	    }
	    # else it's "/" right?
	}
	croak "$fnname (".($maybe_originalpath||$path).") : POSIX::pathconf('$path', $constant): $errstr"
    }
}

sub max_filename_length( $ ) {
    my ($path)=@_;
    @_= ("max_filename_length", &POSIX::_PC_NAME_MAX, $path);
    goto \&_may_any_length;
}

=item max_path_length ( filepath )

=cut

sub max_path_length( $ ) {
    my ($path)=@_;
    @_= ("max_path_length", &POSIX::_PC_PATH_MAX, $path);
    goto \&_may_any_length;
}


=back

=head1 SEE ALSO

L<Chj::Path::Truncator::MD5> (and maybe others)

=cut

1;
