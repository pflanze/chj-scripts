# Wed Jul  7 11:14:11 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::Collection::Iterator

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FileStore::Collection::Iterator;

use strict;
use Chj::xopendir;
use Carp;#hrm
use POSIX "ENOENT";

use Class::Array -fields=> (
			    'Parent',
			    'Criterion',
			    #'Dirfh',
			    'Array',#ach wie schön eben doch wie immer
			    'Pos',
			    'Basedircopy',
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new(@_);
    @$self[Parent,Criterion]=@_;
    #$$self[Dirfh]=xopendir $$self[Parent]->basedir;
    #my $dir=xopendir $$self[Parent]->basedir;
    $$self[Basedircopy]= $$self[Parent]->basedir;
    my $dir=xopendir $$self[Basedircopy];#nananajajaja
#     $$self[Array]=[

# 		   grep {
# 		       $$self[Criterion] ? $$self[Criterion]->($_) : 1
# 		   }
# 		   $dir->xnread # geht das überhaupt in list kontext?
# 		   ];
    #ist das doof oben weil liste builden fur nix? oder ich dubel doch effizienter?
    $$self[Array]=[
		   grep {
		       $$self[Criterion] ? $$self[Criterion]->($_) : 1
		   }
		   map {
		       Chj::FileStore::Collection::_unescape $_
		   }
		   $dir->xnread # geht das überhaupt in list kontext?
		  ];
    $$self[Pos]=0;
    $self
}

sub sort {
    my $self=shift;
    my ($sub)=@_;
    if ($sub) {
	#$$self[Array]= [sort $sub @{$$self[Array]}];
	#kotz geht eht nicht?.
	$$self[Array]= [sort {$sub->($a,$b)} @{$$self[Array]}];
    } else {
	$$self[Array]= [sort @{$$self[Array]}];
    }
    $$self[Pos]=0;
}

sub next {
    my $self=shift;
    #use Data::Dumper; print Dumper($self);
    if ($$self[Pos]<= $#{$$self[Array]}) {
	my $key= $$self[Array]->[$$self[Pos]];
	$$self[Pos]++;
	my $rawval= readlink $$self[Basedircopy]."/".Chj::FileStore::Collection::_escape_key($key);
	if (defined $rawval) {
	    ($key, Chj::FileStore::Collection::_unescape $rawval)
	} else {
	    if ($!==ENOENT) {
		$self->next
	    } else {
		croak "next: readlink gave error: $!";
	    }
	}
    } else {
	()
    }
}


1;
