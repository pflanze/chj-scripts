# Wed Jul  7 11:04:35 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::Collection

=head1 SYNOPSIS

 my $coll= new Chj::FileStore::Collection "base/path/of/store";
 $coll->add($key,$val); # key and val must be strings (or maybe overloaded as such), and can contain any byte
 #$coll->get_iterator;
 my $iterator= $coll->iter_get(sub{my $v=shift; $v cmp "foo" < 0 });
 #while(my $obj= $iterator->next) {
 #   print $obj->key, "\t", $obj->val, "\n"  #quasi variante wenn scheme kein multivalue return hätte
 #}
 while(my ($key,$val)=$iterator->next) {
     print "$key\t$val\n";
 }

 #warum eigentlich iter_get und nicht einfach manuell Collection::Iterator->new aufrufen? um das basedirzu transferieren klar, aber ja?

=head1 DESCRIPTION

erstes in einer neuen Reihe von filesystem basierten storage modulen

ach gaga, collection isch ja doppelt falsch:
- mehrrere values per key
- ohnehin, colection meint, key=val

eigentlich isches ein index bloss, ein mindex. map. auf id irgendeiner form "ja".

todo isch, mehrere add gleichen keys  und dasselbe bei holen undsoweiter. (ps. holen muss ja ned unbeding sortieren sondern einfach criterion reicht fur x-sms)

=cut


package Chj::FileStore::Collection;

use strict;
use Chj::xperlfunc;
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
    xsymlink
      _escape_val($val),
	"$$self[Basedir]/"._escape_key($key);
}

sub remove {
    my $self=shift;
    my ($key)=@_;
    xunlink
      "$$self[Basedir]/"._escape_key($key);
}

sub iter_get {
    my $self=shift;
    require Chj::FileStore::Collection::Iterator;#tja,komisch?
    Chj::FileStore::Collection::Iterator->new($self,@_);
}

#tja die ollen ewigen accessors
sub basedir {
    my $self=shift;
    $$self[ Basedir];
}

1;
