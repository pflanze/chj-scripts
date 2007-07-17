# Fri Jun 25 23:08:49 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Interface - checking implementations against interface definitions

=head1 SYNOPSIS

 {
     package FooInterface;
     use Chj::Interface; # require suffices too
     declare Chj::Interface qw(alpha beta);
         # (as a side effect, sets our @ISA to Chj::Interface)
 }
 {
     package Bar;
     implements FooInterface;
         # for convenience, pushes FooInterface onto our @ISA;
         # it wouldn't if Bar->isa("FooInterface") would already be true.
     sub alpha { }
     sub beta { }
 }
 {
     package Baz;
     implements FooInterface;
         #-> dies with "Chj::Interface: 'Baz' is missing definition of method 'beta'"
     sub alpha { }
 }

=head1 DESCRIPTION

Interface modules call "declare" on Chj::Interface to define a set of
required methods.

Implementation modules call "implements" on the namespace of the interface
to make their own set of subroutines be checked against it's interface definition.

Unlike the two modules listed under 'see also', this does not do a second
load of the implementation module, but instead simply lets the user
call the "implements" method at module initialization time. I think this
makes it both cleaner and more flexible.

=head1 OPEN QUESTIONS

Should it be possible to declare interfaces in steps? Like say,
"FooInterfaceMinimal" declare "alpha", and "FooInterfaceFull"
additionally declares "beta".

Similarly, should it be possible for an implementation module
to implement an interface not completely by itself (like, Bar only
implements "alpha", and Baz only implements "beta" but also inherits
from Baz). I guess so.

So this remains to be done. (Do I have to write an own "can" function?)


=head1 NOTES

Maybe now that this is not put into the interface's @ISA anymore,
this should better be named Chj::CreateInterface.
Then the usual

 use Chj::CreateInterface @methods;

interface is consistently named, and if you want runtime definition,

 use Chj::CreateInterface();
 import Chj::CreateInterface @methods;

does what you want.
(It's how Chj::CreateEnumeration works now.)

=head1 AUTHOR

Christian.Jaeger at ethlife.ethz.ch

=head1 SEE ALSO

=over 4

=item Interface-Polymorphism

(L<ex::interface> and L<ex::implements>)
http://search.cpan.org/src/PDCAWLEY/Interface-Polymorphism-0.2/README

I'm not sure why this is using AUTOLOAD.

=item L<interface>

http://search.cpan.org/~swalters/interface-0.02/interface.pm

Does not allow to explicitely define the set of required methods,
requires the methods to exist in the interface (which should, probably,
better be left as a decision of the user).

=back

=cut


package Chj::Interface;
use strict;
use Carp;

sub declare {
    my $class=shift; # should be __PACKAGE__ so largely irrelevant.
    # how are we given the list of method names?
    my $methods;
    if (@_==1) {
	if (my $r= ref($_[0])) {
	    if ($r eq 'ARRAY') {
		($methods)=@_;
	    } else {
		croak __PACKAGE__.": unknown input type '$_[0]'";
	    }
	} else {
	    $methods=[@_];
	}
    } else {
	$methods=[@_];
    }

    # export methods into interface:
    # (alternatively we could make interface inherit from us, and store
    #  the context data into the interface package instead of using closures)
    my $caller=caller(0);
    no strict 'refs';
    # well, if we didn't croak, perl would still give a warning "sub .. redefined"; but maybe better go sure. Comments welcome.
    *{"$caller\::implements"}{CODE}
      and croak __PACKAGE__." declare: there's already a sub 'implements' in package '$caller'";
    *{"$caller\::implements"}=sub {
	my $class=shift; # what is implemented; we still need this since it could be that a ~'sub-interface' is put between client and us.
	my $caller=caller(0); # who implements it
	for (@$methods) {
	    #$caller->can($_)
	    #  or croak __PACKAGE__.": '$caller' is missing definition of method '$_'";
	    # ^- this check doesn't work if the interface implements a method for
	    #    reasons of SUPER:: usage.
	    no strict 'refs';
	    *{"$caller\::$_"}{CODE}
	      or croak __PACKAGE__.": '$caller' is missing definition of method '$_'";
	}
	unless ($caller->isa($class)) {
	    #warn "adding $class to $caller" if $^W;
	    no strict 'refs';
	    push @{"$caller\::ISA"},$class; # make it the last dependency.
	}
    };
}

1;
