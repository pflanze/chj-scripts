#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Scripting::tar_unpack::Unpacked

=head1 SYNOPSIS

=head1 DESCRIPTION

object to autoclean away unpacked tar files, unless switched off.

overloaded to 'path' method.

=cut


package Chj::Scripting::tar_unpack::Unpacked;

use strict;

use Class::Array -fields=>
  -publica=>
  'tmpdir', # tmpdir *path* (not object because that would break during global destruction. yes.)
  'item',# item name inside tmpdir
  'autoclean',# bool
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Tmpdir,Item,Autoclean])=@_;
    $s
}

sub path {
    my $s=shift;
    join "/", @$s[Tmpdir,Item]
}

# for consistency with Chj::IO::*, accept it as setter without set_ prefix:
sub autoclean {
    my $s=shift;
    if (@_) {
	$s->set_autoclean(@_)
    } else {
	$$s[Autoclean]
    }
}

use overload '""'=> "path";

use Chj::xperlfunc ();

our $verbose=1;

sub DESTROY {
    my $s=shift;
    local ($@,$!,$?);
    if ($$s[Autoclean]) {
	my $path= $s->path;
	if ($path=~ m|^/|) {
	    Chj::xperlfunc::xsystem( "rm","-rf","--",$s->path);
	    rmdir( "$$s[Tmpdir]") or do {
		warn "could not rmdir '$$s[Tmpdir]' during destruction: $!"
		  if $verbose
	      }
	} else {
	    warn "won't attempt to remove trees in non-absolute paths (ok this is unix specific): '$path'"
	}
    }
    $s->SUPER::DESTROY;
}

end Class::Array;
