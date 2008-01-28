# Mon Nov  5 23:54:01 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Find

=head1 SYNOPSIS

 use Chj::Unix::Find;
 my $find= Chj::Unix::Find->new(".","-name","foo*");
 while (<$find>) {
     ...
 }
 # or call $find->next and check for undef

=head1 DESCRIPTION

=head1 CAVEATS

We rely (and append!) -print0. Be careful.. well probably currently it's buggy grr.

=cut


package Chj::Unix::Find;

use strict;

use Class::Array -fields=>
  -publica=>
  'params',
  'fh',
  ;

use Chj::IO::Command;
use overload
  '<>' => "next", # wanted to use "iterate", but forget about it.
  fallback=>1, # the fallback 'true' value is essential so as to display the object in the repl for example
  ;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Params])=[@_];
    $$s[Fh]= Chj::IO::Command->new_sender ("find", @{$$s[Params]}, "-print0");
    $s
}

sub next {
    my $s=shift;
    local $/= "\0";
    my $line= $$s[Fh]->xreadline;
    if (defined $line) {
	chop($line) eq "\0" or die "line did not end in eol char: '$line'";
	$line
    } else {
	$$s[Fh]->xxfinish;
	()
    }
}

# # hm since next is always in list context, also provide this:
# sub iterate {
#     my $s=shift;
#     if (wantarray) {
# 	warn "note: wants array";
# 	my @res;
# 	while (defined(my $item= $s->next)) {
# 	    push @res,$item
# 	}
# 	@res
#     } else {
# 	warn "note: wants scalar";
# 	$s->next
#     }
# }
# nope. forget about it: it's mentioned as a bug in the overload podpage.
# I can confirm that :l <$foo> gives 'wants scalar'

end Class::Array;
