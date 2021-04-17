# Mon Oct 22 00:17:06 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Location::SSH

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse the ssh/scp/rsync-'typical' user@domain:location uris.
(Who specifies them?)

=cut


package Chj::Parse::Location::SSH;

use strict;

use Chj::Parse::Location -extend=>
  -publica=>
  ;


sub maybe_new {
    my $class=shift;
    my ($string)=@_;
    my $s= $class->SUPER::new;
    (@$s[User,Host,Path])=
      $string=~ mé^(?:([^\@:]*)\@)?([^\@:/]+)\:(.*)\zés
	or return;
    # no way to give port, right ?
    $s
}

sub path_is_shellcode {
    # yes, SSH Locations (at least as with scp!!!) are shell code and meant to be interpreted by a shell. (With all the obvious safety implications of course!)
    # it means, "yes use it unsafely, *trust it*", with which comes great responsibility for the user.
    1
}

end Class::Array;
