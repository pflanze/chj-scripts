# Tue Apr 25 00:34:46 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::Promise

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Promise;

use strict;

use Class::Array -fields=>
  -publica=>
  #(actually a union hehe)
  'Evaluated', # 0= value is unevaluated thunk, 1= value is the result of the thunk.
  'Value', # initially the thunk, then the value.
  ;

sub new {
    my $class=shift;
    my $s= bless [],$class;
    ($$s[Value])=@_;
    $s
}

#just to write it down:
# sub set_thunk {
#     my $s=shift;
#     $$s[Evaluated]=0;
#     ($$s[Value])=@_;
# }


sub force {
    my $s=shift;
    $$s[Evaluated] ? $$s[Value]
      : do {
	  $$s[Value]= &{$$s[Value]}; #ps gets $s as argument hehe ehr no, the arguments of force. whatever.
	  $$s[Evaluated]=1;
	  $$s[Value]
      };
}



end Class::Array;
