#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Ghostable

=head1 SYNOPSIS

 use Chj::Ghostable;
 use Chj::Struct 'Some::Class'=> ["a", "b"], 'Chj::Ghostable';
 sub Some::Class::sum { my $s=shift; $$s{a} + $$s{b} }
 #my $ghost= new Some::Class (1,2)->ghost("somepath");
 # or,
 sub Some::Class::ghostpath { my $s=shift; "somepath $$s{a}-$$s{b}" }
 my $ghost= new Some::Class (1,2)->ghost;
 print $ghost->resurrect->sum,"\n";

 # to subclass the ghost class (for example to implement a
 # deserialization cache):
 sub Some::Class::Ghostable_ghost_class { "Some:Class_ghost" }
 # then in Some::Class_ghost, subclass Chj::Ghostable::Ghost
 # and override 'resurrect'

=head1 DESCRIPTION

Uses Storable.pm to move an object out of RAM. The 'ghost' and
'resurrect' methods are functional, i.e. they don't mutate/reshape the
objects they are being called on. This is so that ghosts linked from
some long-living structure don't end up retaining memory when revived.

=cut


use strict;

{
    package Chj::Ghostable::Ghost;
    use Chj::Struct ["path"];
    use Storable ();
    # unghost fetch get retrieve revive instantiate realize
    # reincarnate
    sub resurrect {
	my $s=shift;
	my $path= $$s{path};
	my $res= Storable::retrieve $path;
	ref $res or die "retrieve '$path': $!";
	$res
    }
    sub identify {
	my $s=shift;
	$$s{path}
	  # XX no knowledge of what parts of the path are necessary
	  # for identification
    }
    _END_
}


{
    package Chj::Ghostable;
    use Storable ();
    #use Chj::Ghostable::Ghost;
    sub ghost {
	my $s=shift;
	my ($maybe_path)=@_;
	my $path= $maybe_path || $s->ghostpath;
	my $ghostclass= do {
	    if (my $m= $s->can("Ghostable_ghost_class")) {
		&$m($s)
	    } else {
		"Chj::Ghostable::Ghost"
	    }
	};
	Storable::nstore $s, $path
	    or die "nstore '$path': $!";
	$ghostclass->new($path)
    }
    sub load {
	my $_class=shift;
	my ($path)=@_;
	my $res= Storable::retrieve $path;
	ref $res or die "retrieve '$path': $!";
	$res
    }
}

1
