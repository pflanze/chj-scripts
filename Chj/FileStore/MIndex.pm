# Wed Jul  7 11:04:35 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::MIndex

=head1 SYNOPSIS

 use Chj::FileStore::MIndex;
 use Chj::FileStore::MIndex::NonsortedIterator;

 my $basedir="/tmp/chris/coll";
 mkdir $basedir;

 my $coll= new Chj::FileStore::MIndex $basedir;
 $coll->add("hallo","welt");
 $coll->add("hal/lo\0huh","welt\0bla/smir");
 $coll->add("hallo","welt1");
 $coll->remove("hallo","welt");
 $coll->add("hallo","welt2");

 my $iter= Chj::FileStore::MIndex::NonsortedIterator # strange weil das auch die query macht.
	    ->new($coll,sub{my ($k)=@_;
			    #warn "checking '$k'.\n";
			    $k=~ /ll/
			   });
 while(defined(my $val=$iter->next_val)) {
     print "$val\n";
 }


=head1 DESCRIPTION

erstes in einer neuen Reihe von filesystem basierten storage modulen

Does not allow to add the same key,value pair more than once. add returns false if one such pair already exists.

=cut


package Chj::FileStore::MIndex;

use strict;
use Chj::xperlfunc;
use POSIX qw(EEXIST ENOENT ENOTEMPTY);
use Carp;
use Chj::xopendir;

use Class::Array -fields=> (
			    'Basedir',
			   );


###ps. lame copy  PIndex.pm <-> MIndex.pm
sub _escape_key {
    #my $self=shift;
    my ($str)=@_;
    $str=~ s|\%|\%25|sg;
    $str=~ s|/|\%2f|sg;
    $str=~ s|\0|\%00|sg;
    $str=~ s|\n|\%0a|sg;# weil sonst perl warnings gibt bei exists etc 'unsuccessful stat on filename with newline' auch wenn nicht am ende.
    "=".$str
}

sub _escape_val {
    my ($str)=@_;
    $str=~ s|\%|\%25|sg;
    $str=~ s|\0|\%00|sg;# ich könnte hier auch s|\0|\\0|sg machen weil eine normalanerkannte solche escape besteht die dann umgewandelt wird; bei / isch das andersch, gibt es keine allganerk escape die den / nicht enthaelt. daher escape_key andersch noetig
    $str=~ s|/|\%2f|sg;# nun auch nötig
    #$str=~ s|,|\%2c|sg;#das trennzeichen nein.
    $str=~ s|\n|\%0a|sg;# weil sonst perl warnings gibt bei exists etc 'unsuccessful stat on filename with newline' auch wenn nicht am ende.
    "=".$str
}

sub _unescape {
    my ($str)=@_;
    $str=~ s|\%0a|\n|sg;
    $str=~ s|\%00|\0|sg;
    $str=~ s|\%2f|/|sg;
    $str=~ s|\%25|\%|sg;
    #$str=~ s|\%2c|,|sg;
    substr($str,1)
}

sub new {
    my $class=shift;
    my $self= $class->SUPER::new(@_);
    @$self[Basedir]=@_;
    $self
}

# 2 varianten:
# a)  key/{id1,id2,id3..}
# b)  key->id1,id2,id3..
# a isch doch easier
# und so habe ich es ja doch schon bei thea gemacht  ps "warum code ich es erneut?"

sub add { # returns 0= (key,val) already existed. 1=new entry of val to existing key. 2=new key
    my $self=shift;
    my ($key,$val)=@_;
    my $k=_escape_key $key;
    my $new_key=
      mkdir "$$self[Basedir]/$k" or $!==EEXIST or croak "add: $!";
    symlink " ", "$$self[Basedir]/$k/"._escape_val($val)
      or do {
	  if ($!==EEXIST) {
	      #croak "add: entry ($key,$val) already exists";# oder hier echt auch returnwert?
	      return 0;#0 not undef, so that == comparisons don't warn
	  } else {
	      croak "add: creating symlink '$$self[Basedir]/$k/"._escape_val($val)."': $!";
	  }
      };
    $new_key ? 2 : 1;
}

sub remove {# returns true on successful removal, false if non removed.
    my $self=shift;
    @_==2 or croak "remove needs two arguments: (self,key,val)";
    my ($key,$val)=@_;
    my $k=_escape_key $key;
    unlink "$$self[Basedir]/$k/"._escape_val($val)
      or do {
	  if ($!==ENOENT) {
	      return;
	  } else {
	      croak "remove: unlink '$$self[Basedir]/$k/"._escape_val($val)."': $!";
	  }
      };
    # check ob verzeichnis leer zurückgelassen? resp einfach versuchen:
    rmdir "$$self[Basedir]/$k"
      or $!==ENOENT or $!==ENOTEMPTY or croak "remove: rmdir '$$self[Basedir]/$k': $!";
    1;
}

sub remove_all {##not yet tested or used
    my $self=shift;
    @_==1 or croak "remove_all needs one argument: (self,key)";
    my ($key)=@_;
    my $k=_escape_key $key;
    #for (glob "$$self[Basedir]/$k/*") {
    #xunlink $_
    #} for whatever reason dis did not work
    {
	my $dirpath="$$self[Basedir]/$k";
	my $d=xopendir $dirpath;
	while (defined(my$item=$d->xnread)){
	    unlink "$dirpath/$item"
	      or die "remove_all: could not unlink '$dirpath/$item': $!";
	}
    }
    #xrmdir "$$self[Basedir]/$k";  #ps wirklich die wenn gar ned existiert? doch nicht. also todo change.
    rmdir "$$self[Basedir]/$k"
      or $!==ENOENT or die "remove_all: rmdir '$$self[Basedir]/$k': $!";
}


sub key_mtime {
    my $self=shift;
    @_==1 or croak "remove_all needs one argument: (self,key)";
    my ($key)=@_;
    my $k=_escape_key $key;
    defined (my $mtime=(stat "$$self[Basedir]/$k")[9])
      or $!==ENOENT or croak "key_mtime: stat '$$self[Basedir]/$k': $!";
    $mtime
}

# sub iter_get {
#     my $self=shift;
#     require Chj::FileStore::MIndex::Iterator;#tja,komisch?
#     Chj::FileStore::MIndex::Iterator->new($self,@_);
# }
#->nun eben doch manuell machen  einfach whatever so haha

#tja die ollen ewigen accessors
sub basedir {
    my $self=shift;
    $$self[ Basedir];
}

1;
__END__

  warum nöd bdb  gibt es da nich access tools  (und wenn nicht selber schreiben?) (Weil, wenn nich, hier ja doch die frage, soll ich datum als unixtime und dann bei listing umwandeln, oder andersch?)

  ach.

  und ich wollt dies als wrap around irgendwas,
  und dann noch   locking als wrap around this.

  "btw locking":
  DB_File:
       Starting with version 2.x, Berkeley DB  has internal support for locking.  The com­
       panion module to this one, BerkeleyDB, provides an interface to this locking func­
       tionality. If you are serious about locking Berkeley DB databases, I strongly rec­
       ommend using BerkeleyDB.

       If using BerkeleyDB isn't an option, there are a number of modules available on
       CPAN that can be used to implement locking. Each one implements locking differently
       and has different goals in mind. It is therefore worth knowing the difference, so
       that you can pick the right one for your application. Here are the three locking
       wrappers:


...

       DB_File::Lock
            An extremely lightweight DB_File wrapper that simply flocks a lockfile before
            tie-ing the database and drops the lock after the untie. Allows one to use the
            same lockfile for multiple databases to avoid deadlock problems, if desired.
            Use for databases where updates are reads are quick and simple flock locking
            semantics are enough.


ich kenne fuck das alles ja   "doch"


HMMMMM, BerkeleyDB isch ned installiert nödmal auf lo,mbi

thus föcking ebendochselber


PS.
DB_BTREE
       The DB_BTREE format is useful when you want to store data in a given order. By
       default the keys will be stored in lexical order, but as you will see from the
       example shown in the next section, it is very easy to define your own sorting func­
       tion.



------

=head1 SYNOPSIS

 my $coll= new Chj::FileStore::MIndex "base/path/of/store";
 $coll->add($key,$val); # key and val must be strings (or maybe overloaded as such), and can contain any byte
 #$coll->get_iterator;
 my $iter= $coll->iter_get(sub{my $k=shift; $k cmp "foo" < 0 });
 #  while(my $data= $iterator->next) {
 #      print $data->key, "\t",join("\t", $data->values), "\n"  #quasi variante wenn scheme kein multivalue return hätte
 #        #^- ps typischer fall wo der caller memory allozieren sollte  weil  sowohl  klar isch dass es ihn braucht und nur solang der caller ihn braucht  und sogar weil  er wiederverwendet werden kann quasi;  na in scheme, auch perl, wär ja moglich von aussen kreieren dann reingeben dort modifizieren lassen.  NA: könnte ja auch ein sub object per-parentobject machen vielleicht? isch damit schon garantiert dass keine clanches? hm  gefällt mir einfach nichtr das perl das so un efizient
 #        # Frage wie mach ich s eigentlich bei thea? pair oder multi oder irgen d iterator dort
 #        #=item iget_from_mindex($indexname,$criterion) -> Thea::PairIterator
 #        #und ja, das tut duplifikationieren einfach  jeder value der first column über die der zweiten   (und dann? object creation anhand dieser werte? id ja zweite  sowhat. ja und multicol sort isch damit ja noch nicht moglich)
 #  }
 # obiges allenfalls als $iter->next_bundle oder sowas machen.
 while (my ($key,$val)=$iter->next_key_val) {# so kann ich das sub objekt safely wiederverwenden oder? in mir drin
     # aber wurde es dadurch weniger modular?
     # weniger frei?
     # key isch halt hier mehrmals gegeben wird es. auch ne verschwendung?
     # ps wenn schon dann sub iterator?
     # iterator. was gibt es in der functional world dafur? callbacks?
 }
 while (defined(my $val=$iter->next_val)) {
 }



 #warum eigentlich iter_get und nicht einfach manuell Collection::Iterator->new aufrufen? um das basedirzu transferieren klar, aber ja?
