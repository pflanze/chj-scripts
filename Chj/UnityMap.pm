# Mon Nov 29 11:36:30 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::UnityMap

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 SEE ALSO

L<Chj::WeakUnityMap>

=cut

# todo: make it so that we do not need a copy of almost all code!!

package Chj::UnityMap;

use strict;
use Carp ();

use Class::Array -fields=>
  'calchash', # undef or coderef; (must not be publica)
  -publica=>
  'class',
  'hash',
  'creationcount',
  ;

our $DEBUG=0;

sub new {
    my $class=shift;
    Carp::croak "don't call new method on ".ref($class)." objects" if ref $class;
    my $s= $class->SUPER::new;
    ($$s[Class])=@_;
    $$s[Hash]={};
    $$s[Calchash]= $s->can("calchash");
    $$s[Creationcount]=0;
    $s
}

#sub calchash {  # subclasses may define such a method, it is then copied in the new method.
#    my $s=shift;
#    join "\0",@_
#}

sub get {
    my $s=shift;
    my $key= $$s[Calchash] ? &{$$s[Calchash]} : join "\0",map{ref $_ ? pack("I",$_) : "$_" } @_;
    $$s[Hash]{$key}   # btw exists $$s[Hash]{$key} is not workable with weak refs (right?)!
}
sub exists {
    my $s=shift;
    defined $s->get(@_)
}

sub instance {
    my $s=shift;
    my $key= $$s[Calchash] ? &{$$s[Calchash]} : join "\0",map{ref $_ ? pack("I",$_) : "$_" } @_; # must copy here, and copy get code as well, if I don't want to calculate key multiple times.
    if (defined(my $v= $$s[Hash]{$key})) {
	$v
    } else {
	$$s[Hash]{$key}= $$s[Class]->new(@_);
    }
}

sub values {
    my $s=shift;
    values %{$$s[Hash]}
}

sub closure {
    my $s=shift;
    sub {
	if (@_) {
	    #my $key= $$s[Calchash] ? &{$$s[Calchash]} : join "\0",@_;
	    #$$s[Hash]{$key} ||= do {
	    #$$s[Class]->new(@_);
	    #}
	    $s->instance(@_)
	} else {
	    # return the unitymap object for convenience.
	    $s
	}
    }
}

sub clos { # also usable if no parameters are required to get the object. Kind of a singleton class usage in that case.
    my $s=shift;
    sub {
	$s->instance(@_)
    }
}

end Chj::UnityMap;
