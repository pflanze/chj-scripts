# Tue May  6 12:15:02 2003  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2003-2007 by Christian Jaeger
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

=head1 BY THE WAY

You can:

    $ calc -MChj::load
    calc> :l use vars '$halo'
    calc> :l load "/opt/chj-priv/etc/maillogfilter_knownadresses"
    calc> :l $halo
    gla

where the loaded file contains

    use strict;
    $halo="gla";

(note that no 'our' keyword is given). Interestingly, only 'use vars'
is "powerful" enough to yield this behaviour, saying 'our
$halo="initvalue";' outside will lead to the error

 Variable "$halo" is not imported at /opt/chj-priv/etc/maillogfilter_knownadresses.pm


=head1 SEE ALSO

http://pflanze.mine.nu/~chris/scripts/utilities/perl_path2namespace

=cut


package Chj::load;
@ISA="Exporter";
require Exporter;
@EXPORT= "load";

use strict;

our $loaded={}; # path => return value. Question: is it a good idea to cache the return value? (memory retention)

sub load {
    my $caller=caller;
    my @rv;
    for my $nameorig (@_) {
	my $name= $nameorig; # make a copy to be sure it is not an alias of a read-only value
	$name=~ s|::|/|sg;
	$name.=".pm";

	if (defined (my $v= $$loaded{$name})) {
	    push @rv, $v
	} else {
	    # always execute in scalar context (good? (or what?))
	    my $rv= eval 'package '.$caller.'; require $name'; die $@ if (ref $@ or $@);
	    $$loaded{$name}=$rv;
	    push @rv,$rv
	}
    }
    wantarray ? @rv : $rv[-1]
}

*Chj::load= \&load;

1;
