# Tue May  6 12:15:02 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::load

=head1 SYNOPSIS

 use Chj::load;

 load "Foo::Bar","Foo::Baz";
 # same as require "Foo/Bar.pm"; require "Foo/Baz.pm";

 # -- or --

 use Chj::load ();# () prevents from importing the 'load' subroutine,
 Chj::load my $Bar= "Foo::Bar"; # which is nicer to use in class files
                                # since it doesn't create a method

 my $foo= new $Bar;

=head1 DESCRIPTION

Sometimes you want to load classes at runtime or by string.

=head1 SEE ALSO

http://pflanze.mine.nu/~chris/scripts/utilities/perl_path2namespace

=cut


package Chj::load;
@ISA="Exporter";
require Exporter;
@EXPORT= "load";

use strict;

sub load {
    for $_ (@_) {
	my $name=$_;
	$name=~ s|::|/|sg;
	$name.=".pm";
	require $name;
    }
}

*Chj::load= \&load;

1;
