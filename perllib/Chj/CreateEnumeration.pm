# Sun Jun 27 19:17:55 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::CreateEnumeration

=head1 SYNOPSIS

 #  # Precondition:
 #  package Sometype;
 #  # should be a class returning the same object for each
 #  # invocation of new with the same argument(s)
 #  my %cache;
 #  sub new {
 #     my $class=shift;
 #     my ($val)=@_;
 #     $cache{$val}||=do{
 #        bless { val=>$val },$class
 #     }
 #  }
 #->nope, not really necessary, since we cache anyways.

 # Setting up the enumeration:
 package Sometypes;# or maybe: package SometypeEnum;
 #use Chj::CreateEnumeration 'Sometype', qw(a b c d);#<- names
 # hm, requires the list to exist, thus this is also possible:
 # hm of course THIS is possible:
 use Chj::CreateEnumeration ();
 import Chj::CreateEnumeration 'Sometype', @names;

 # Usage then in client code:
 use Sometypes "Some_"; # imports named constants holding a Sometype object each.
 my $a= Some_a;
 if ($a==Some_a) {
    print "$a is Sometype a";
 }

=head1 DESCRIPTION

The import routine of Chj::CreateEnumeration sets up the caller package
with todo:finishdocs

=head1 CAUTION

For each given name, a sub with the same name is created in the caller
package. Chj::CreateEnumeration croaks when it sees a conflict.

So make sure you don't create any sub with the same name there.
If you use the enumeration package *only* for the enumeration (as you should),
no conflict will happen.

=cut

#';}

package Chj::CreateEnumeration;
use strict;
use Carp;

sub import {
    my $class=shift;# probably 'Chj::CreateEnumeration'
    my $enumtype=shift;
    my @names=@_;
    unless(@names){
	carp __PACKAGE__." import: no names given (maybe this is compile-time and the argument list is not yet defined?)";
    }
    my $enumpackage=caller(0);

    # create constants.
    for my $name (@names) {
	my $instance= $enumtype->new($name);
	no strict 'refs';
	# well, if we didn't croak, perl would still give a warning "sub .. redefined"; but maybe better go sure. Comments welcome.
	*{"${enumpackage}::$name"}{CODE}
	  and croak __PACKAGE__
	    ." import: conflict with already existing sub with name '$name' in package '$enumpackage'";
	*{"${enumpackage}::$name"}= sub () { $instance };
    }

    # create exporter:
    no strict 'refs';
    *{"${enumpackage}::import"}=sub {
	my $class=shift;
	@_==1
	  or croak __PACKAGE__
	    ." import must be given one argument (the import prefix for the constants)";
	my ($prefix)=@_;
	my $enumuser=caller(0);
	#warn "enumuser=$enumuser, names=@names";
	no strict "refs";
	for my $name (@names) {
	    *{"${enumuser}::${prefix}$name"}= *{"${enumpackage}::$name"}{CODE};
	    #warn "created '${enumuser}::${prefix}$name' as alias to '${enumpackage}::$name'";
	}
    };
}


1;
