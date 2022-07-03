# Wed May 12 23:26:46 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Daemon

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::Daemon;
use strict;
use Chj::xperlfunc "xfileno";

use Class::Array -fields=> (
			    "Runpath",# file path e.g. ".../foo.run" (or maybe .lck)
			    "Pid",
			    "In",
			    "Out",
			    "Err",
			    "_Factory",
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    @_==2 or croak "new: expecting factory,runpath";
    ($$self[_Factory],$$self[Runpath])=@_;
    $self
}

sub set_in {
    my $self=shift;
    ($$self[In])=@_;
}
sub set_out {
    my $self=shift;
    ($$self[Out])=@_;
}
sub set_err {
    my $self=shift;
    ($$self[Err])=@_;
}
sub set_outputs {
    my $self=shift;
    ($$self[Err])=@_;
    $$self[Out]=$$self[Err];
}


1;
