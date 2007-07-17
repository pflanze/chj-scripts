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

L<Chj::UnityMap>

=cut

# todo: make it so that we do not need a copy of almost all code!!

package Chj::WeakUnityMap;

use strict;
use Carp ();
use WeakRef ();

use Class::Array -fields=>
  'calchash', # undef or coderef; (must not be publica)
  -publica=>
  'class',
  'hash',
  'creationcount',
  ;

our $CLEANUP_EVERY_N= 100;
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


sub cleanup {
    my $s=shift;
    for (keys %{$$s[Hash]}) {
	if (!defined $$s[Hash]{$_}) {
	    delete $$s[Hash]{$_};
	    print STDERR "$s: cleaned up key '$_'\n" if $DEBUG;
	}
    }
}

sub instance {
    my $s=shift;
    my $key= $$s[Calchash] ? &{$$s[Calchash]} : join "\0",map{ref $_ ? pack("I",$_) : "$_" } @_; # must copy here, and copy get code as well, if I don't want to calculate key multiple times.
    if (defined(my $v= $$s[Hash]{$key})) {
	$v
    } else {
	if ($$s[Creationcount]++ > $CLEANUP_EVERY_N) {
	    $$s[Creationcount]=0;
	    $s->cleanup
	}
	#$DB::single=1;
	my $new= $$s[Hash]{$key}= $$s[Class]->new(@_);
	WeakRef::weaken $$s[Hash]{$key};
	$new;# had to store it here or it would (sometimes) disappear before we return.
    }
}

sub values {
    my $s=shift;
    #grep { defined } values %{$$s[Hash]}   # defined is needed since we don't always cleanup
    $s->cleanup;
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

end Chj::WeakUnityMap;
