# Thu Mar  8 14:30:06 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Object::User

=head1 SYNOPSIS

 use Chj::Unix::Object::User;
 if (my $u= Chj::Unix::Object::User->get_by_nam ("foo")) {
    $u->uid, $u->dump_publica,...
 } else {
    "no such user"
 }

=head1 METHODS

=item get_by_nam ($name)

=item get_by_uid ($uid)


=head1 DESCRIPTION

Representing getpwnam [and the like] output as objects (in
Chj::xperlfunc xstat tradition).

Chj::Unix::User was already taken by myself (how short-sighted), thus
evading into Object:: subnamespace.

=cut


package Chj::Unix::Object::User;

use strict;

use Class::Array -fields=>
  -publica=>
  # from perlfunc getpwnam:
  qw(
     name
     passwd
     uid
     gid
     quota
     comment
     gcos
     dir
     shell
     expire
    );


my $Mk= sub {
    my ($get)=@_;
    sub {
	my $class=shift;
	@_==1 or die "expecting 1 argument";
	my ($val)=@_;
	if (my @u= $get->($val)) {
	    bless \@u, $class
	} else {
	    return
	}
    }
};

*get_by_nam= $Mk->(sub { getpwnam $_[0] });
*get_by_uid= $Mk->(sub { getpwuid $_[0] });



end Class::Array;
