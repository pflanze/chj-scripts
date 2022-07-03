#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::IO::DirDeep

=head1 SYNOPSIS

With a similar interface as Chj::IO::Dir, but recursing deeply.

=head1 DESCRIPTION


=cut


package Chj::IO::DirDeep;

use strict;

use Chj::FP::Pair;

use Class::Array -fields=>
  -publica=>
  # 'deep iterator'
  #'curfh', #yeah we had this in some place..
  #well actually:
  'fhs', # pair list of Chj::IO::Dir objects
  # since Chj::IO::Dir already keeps the path, don't keep the item
  # names here
  ;


use Chj::xopendir;

sub new {
    my $proto=shift;
    my ($path)=@_;
    my $fh= xopendir $path;
    if (ref $proto) {
	my $s= $proto;
	$$s[Fhs]= Chj::FP::Pair->cons($fh, $$s[Fhs]);
	()
    } else {
	my $s= $proto->SUPER::new;
	$$s[Fhs]= Chj::FP::Pair->cons($fh, undef); # undef?.well why not.
	$s
    }
}

use Chj::xperlfunc 'Xlstat';

#sub xnread_deep {
#hm actually only interested in files?
sub xnread_deep_files { # returns a (path,stat) for each call
    my $self=shift;
    if (defined (my $c= $$self[Fhs])) { #that's why we use undef above. 'CL.'
	my $fh= $c->car;
	if (defined (my $item= $fh->xnread)) {
	    my $path= $fh->path."/$item";
	    if (my $s= Xlstat $path) {
		if ($s->is_dir) {
		    $self->new ($path); # side-effecting $self
		    $self->xnread_deep_files; #should be tail call, well.
		} elsif ($s->is_file) {
		    ($path, $s)
		      #^oh, wantarray mode wouldbenogood.hah
		} else {
		    # warn ignoring non-file...
		    $self->xnread_deep_files; #should be tail call, well.
		}
	    } else {
		warn "(ignoring path that could not be stat'ed: '$path': $!)";
		$self->xnread_deep_files; #should be tail call, well.
	    }
	} else {
	    $fh->xclose;
	    $$self[Fhs]= $$self[Fhs]->cdr;
	    $self->xnread_deep_files; #should be tail call, well.
	}
    } else {
	()
    }
}


end Class::Array;
