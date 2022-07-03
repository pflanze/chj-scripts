# Wed Dec  1 16:22:23 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::State::Data

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::State::Data;

use strict;
use Chj::FileStore::PIndex;
use Chj::xperlfunc();
use Chj::FileStore::Stamp;
#use warnings all=>"FATAL"; doesn't help for throwing on undef

use Class::Array -fields=>
  'Base', # path
  'Accessor', # PIndex obj
  -publica=>
  ;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Base])=@_;
    $s->init;
    $s
}

sub markerfile { shift->[Base]."/.level2edge" }
sub database { shift->[Base]."/data" }

sub init {
    my $s=shift;
    $$s[Accessor]= Chj::FileStore::PIndex->new($s->database);
    my $stamp= Chj::FileStore::Stamp->new($s->markerfile);
    return if $stamp->exists;
    # mkdir $$s[Base] ?  or is this symlink attack endangoured? so don't do it here
    $stamp->xtouch;
    Chj::xperlfunc::xmkdir $s->database;
}


# sub alarm {
#     my $s=shift;
#     my ($id)=@_;
#     (split /,/, $$s[Accessor]->get($id))[0]
# }

# sub state {
#     my $s=shift;
#     my ($id)=@_;
#     (split /,/, $$s[Accessor]->get($id))[1]
# }

# sub n {
#     my $s=shift;
#     my ($id)=@_;
#     (split /,/, $$s[Accessor]->get($id))[2]
# }

# #^- hum.
# # oder  get($id,$what) ?  idx?  multival?  set aber dann auch?.

sub get {
    my $s=shift;
    my ($id)=@_;
    if (defined (my $v=$$s[Accessor]->get($id))) {
	split /,/, $v, -1  # -1 prevents from turning false (empty str) into undef.
    } else {
	()
    }
}

sub set {
    my $s=shift;
    my $id=shift;
    @_==3 or die;
    $$s[Accessor]->set($id,join ",",@_);
}

end Chj::State::Data;
