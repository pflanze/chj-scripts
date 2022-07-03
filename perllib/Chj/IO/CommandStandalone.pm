# Mon Jun 16 13:54:46 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::CommandStandalone

=head1 SYNOPSIS

 # unlike Chj::IO::Command, do not open a pipe to us, just tie a command
 # up to arbitrary filehandles:
 my $cmd= Chj::IO::Command->new_xlaunch3($inhandle,$outhandle,$errhandle,@cmd);
 # where any of {in,out,err}handle can be undef

=head1 DESCRIPTION


=cut


package Chj::IO::CommandStandalone;

use strict;

use base qw(Chj::IO::CommandCommon);

sub xclose {
    # noop
    # A bit ugly? Maybe should rather change CommandCommon to not call xclose?
    # but then maybe not.
}

sub new_xlaunch3 {
    my $class=shift;
    #my $self= $class->new;#hm senseless for it being a glob?!!!
    # ah it doesn't have a new method anyway.
    my $self= bless {}, $class;
    my ($infh,$outfh,$errfh,@cmd)=@_;
    $self->xlaunch3($infh,$outfh,$errfh,@cmd);
}


1
