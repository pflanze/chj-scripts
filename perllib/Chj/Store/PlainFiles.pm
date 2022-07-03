# Wed Feb 11 20:45:27 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Store::PlainFiles

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Store::PlainFiles;

use strict;
use utf8;
use Chj::xopen qw(xopen_write xopen_read);
use POSIX qw(ENOENT EEXIST);

use Chj::Store -extend=> (
			  'Basepath',
			 );

#my $path2=sub

sub new {
    my $class=shift;
    my ($basepath)=@_;
    my $self= $class->SUPER::new(@_);
    @$self[Basepath]=$basepath;
    $self
}

sub primaryfilepath {
    my $self=shift;
    my ($key)=@_;
    "$$self[Basepath]/$key"
}

sub put {
    my $self=shift;
    my ($obj)=@_;
    # find out key
    my $key= $obj->key;
    my $path=$self->primaryfilepath($key);
    my $f=xopen_write $path;
    $f->xprint($obj->data);
    $f->xclose;
}

sub get {
    my $self=shift;
    my ($obj)=@_;
    my $f=xopen_read ($self->primaryfilepath($obj->key));
    $obj->set_data($f->xcontent);
}

sub delete {
    my $self=shift;
    my ($obj)=@_;
    unlink $self->primaryfilepath($obj->key)
}

sub exists {
    my $self=shift;
    my ($obj)=@_;
    #-e $self->primaryfilepath($obj->key)
    # oder besser stat vermeiden? doch dann 2 syscalls. oder? coole idee:
    my $path=$self->primaryfilepath($obj->key);
    link $path,$path;
    if ($!==ENOENT) {
	return 0
    } elsif ($!==EEXIST) {
	return 1;
    } else {
	die "exists '$path': $!";
    }
}

1;

__END__
  hmm, nur mit get isch es scheiss zu prüfen ob ein key existiert
  va mit dieser ramschexception

  
