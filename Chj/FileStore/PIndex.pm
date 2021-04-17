# Wed Jul  7 11:04:35 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::PIndex

=head1 SYNOPSIS

 my $pindex= new Chj::FileStore::PIndex "base/path/of/store";
 $pindex->add($key,$val); # key and val must be strings (or maybe overloaded as such), and can contain any byte
 my $iterator= $pindex->iter_get(sub{my $v=shift; $v cmp "foo" < 0 });
 #while(my $obj= $iterator->next) {
 #   print $obj->key, "\t", $obj->val, "\n"  #quasi variante wenn scheme kein multivalue return hätte
 #}
 while(my ($key,$val)=$iterator->next) {
     print "$key\t$val\n";
 }

 #warum eigentlich iter_get und nicht einfach manuell Collection::Iterator->new aufrufen? um das basedirzu transferieren klar, aber ja?

=head1 DESCRIPTION

dies war-mal-erstes in einer neuen Reihe von filesystem basierten storage modulen,
von ....::Collection umbenannt.

=head1 METHODS

=over 4

=item add ($key,$val) -> success

=item xadd ($key,$val)

=item set ($key,$val)

set does not return any value.


=back


=head1 TODO

- get und xget methoden
- set ->done, und xset methoden.  set kreiert   xset geht davon aus dass es key schon gibt?.

=cut


package Chj::FileStore::PIndex;

use strict;
use Chj::xperlfunc;
use Carp;
use POSIX qw(EEXIST ENOENT);
use Chj::FileStore::Helpers;

use Class::Array -fields=> (
			    'Basedir',
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new(@_);
    @$self[Basedir]=@_;
    $self
}

sub add {
    my $self=shift;
    my ($key,$val)=@_;
    my $path="$$self[Basedir]/"._escape_key($key);
    symlink _escape_val($val),$path or do {
	$!==EEXIST or croak "add: symlink to '$path': $!";
	0;
    };
}

sub xadd {
    my $self=shift;
    my ($key,$val)=@_;
    xsymlink  ##sollten eben typisierte exceptions sein, und dann: nicht die von xsymlink sondern implementationsunabhängige.
      _escape_val($val),
	"$$self[Basedir]/"._escape_key($key);
}

sub set {
    my $self=shift;
    my ($key,$val)=@_;
    # random numbers?
    # no, pid should be enough, advantage: can unlink stale ones; - what with threading? todo.
    #my $tmppath="$$self[Basedir]/t.$$."._escape_key($key);  eh, warum langer pfad mit problem dass wenigerlange keys möglich als dann speicherbar, wenn doch kurzer auch geht.
    my $tmppath="$$self[Basedir]/t.$$";
    my $n;
  AGAIN:
    symlink _escape_val($val),$tmppath or do {
	if ($!==EEXIST) {
	    warn "unlinking stale path '$tmppath'";
	    xunlink $tmppath;
	    die "??" if $n++ > 4;
	    goto AGAIN;
	} else {
	    die
	}
    };
    xrename $tmppath,"$$self[Basedir]/"._escape_key($key);
}


sub exists {
    my $self=shift;
    my ($key,$val)=@_;
    -l "$$self[Basedir]/"._escape_key($key);
}

sub remove {
    my $self=shift;
    my ($key)=@_;
    my $path="$$self[Basedir]/"._escape_key($key);
    unlink $path or do {
	$!==ENOENT or croak "remove: unlink '$path': $!";
	0
    };
}
sub xremove {
    my $self=shift;
    my ($key)=@_;
    xunlink
      "$$self[Basedir]/"._escape_key($key);
}

sub iter_get {
    my $self=shift;
    require Chj::FileStore::PIndex::NonsortedIterator;#tja,komisch?
    Chj::FileStore::PIndex::NonsortedIterator->new($self,@_);
}
# Wed, 31 Jan 2007 15:26:03 +0100:
*get_iter= *iter_get;


sub maybe_get {
    my $self=shift;
    my ($key)=@_;
    my $path="$$self[Basedir]/"._escape_key($key);
    if (defined (my $val = readlink $path)) {
	_unescape($val);
    } else {
	$!==ENOENT or croak "get: readlink '$path': $!";
	undef;
    }
}

#backwards compat, doh. necessary?
*get= \&maybe_get;

#tja die ollen ewigen accessors
sub basedir {
    my $self=shift;
    $$self[ Basedir];
}

1;
