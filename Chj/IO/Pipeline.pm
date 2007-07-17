# Sun Aug  1 15:11:23 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::Pipeline

=head1 SYNOPSIS

=head1 DESCRIPTION

 rather unfinished! only xxfinish method supported yet.

=head1 TODO

 - override xclose, and xfinish, too.  interfere with xxfinish?.
 -etc.

 -improve error mesages: "xxfinish on pipe: subcommand gave error 1 at /usr/local/lib/perl/5.6.1/Chj/xpipeline.pm line 65"
 - evtl kill other pipe partners if one fails.?  wird nun frage wie, weil wo grenzen

=cut


package Chj::IO::Pipeline;
use strict;

use Chj::xpipe;
use base "Chj::IO::Command";#  #vgl. notizen in ~/perldevelopment/pipeline/Chj/xpipeline.pm

my %metadata; # numified => nextio
sub set_nextio {
    my $self=shift;
    ($metadata{pack"I",$self})=@_
}
sub nextio {
    my $self=shift;
    $metadata{pack"I",$self}
}

sub xxfinish {
    my $s=shift;
    $s->SUPER::xxfinish;
    my $nextio=$s->nextio;
    $nextio->xxfinish if $nextio and $nextio->isa("Chj::IO::Command");#mache mirs mal so. weil: mehrere receiverpipelines pipelinen isch ja scho ne luschtige idee sowieso. also auch dann finishen wenn die nägscht ned vo "uns" kreiert wurde.
}

sub xreceiverpipeline_with_out_to {
    my $class=shift;
    my $out_to=shift;#!
    my $frame=pop;
    my ($r,$self)=xpipe;
    bless $self,$class;
    $self->xlaunch3($r,$out_to,undef,@$frame);
    $self->set_nextio($out_to);# hey sollte das nich evtl die Command classe already speichern? ##todo
    if (@_) {
	$class->xreceiverpipeline_with_out_to($self,@_);
    } else {
	$self
    }
}

#sub xxpipeline {
    # a pipeline that reads from stdin and outputs to stdout. i.e. do not create pipes for the ends.
#->see Chj::xpipeline.pm

sub DESTROY {
    my $self=shift;
    local ($@,$!);
    #$self->xxfinish unles   TODO ç
    delete $metadata{pack"I",$self};
    $self->SUPER::DESTROY;
}

1;
