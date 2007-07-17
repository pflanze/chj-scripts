# Tue Apr  8 16:47:21 2003  Copyright 2003 by Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Class::Hierarchy

=head1 SYNOPSIS

 use Class::Hierarchy;
 package Foo;
 @ISA=("Bar","Baz");
 Class::Hierarchy::dump(__PACKAGE__);

=head1 DESCRIPTION


=cut


package Class::Hierarchy;
#require "Exporter";
#@EXPORT_OK
use strict;


sub dump {
    my ($class,$followrf,$indlevel)=@_;
    #warn "dump($class)";
    if (! $followrf) {
	$followrf={};
	$indlevel||=0;
	print "$class:\n"
    }
    $followrf->{$class}=undef;
    no strict 'refs';
    #    if (my $ref= *{"${class}::"}{ARRAY}) {
    #if (my $ref= \@{"${class}::ISA"}) {
    if (my $ref= *{"${class}::ISA"}{ARRAY}) {
	for (@$ref) {
	    #print "..werd dump($_) aufrufen..\n";
	    #my $str=$_;
	    #dump($str); -> makes core dump, non-surprisingly...och.
	    #__PACKAGE__::dump($_); Undefined subroutine ??
	    print " "x(3*$indlevel)."-> $_";
	    if (exists $followrf->{$_}) {
		print " (already examined)\n";
	    } else {
		print ":\n";
		Class::Hierarchy::dump($_,$followrf,$indlevel+1);
	    }
	}
    }
}

1;
