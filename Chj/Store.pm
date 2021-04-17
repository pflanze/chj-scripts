# Wed Feb 11 19:10:43 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Store

=head1 SYNOPSIS

 my $thestore= new Chj::Store::Foo "foo/bar";
 my $obj= new .....; # do something with it.
 $thestore->store($obj);
 my $obj2= $thestore->load($obj);

=head1 DESCRIPTION

(This is the interface only, it's empty here. You have to use a subclass instead. Well, actually this is rather totally useless here)

It defines how to create a storage pool.

It then works by giving the storage pool objects for storage or loading; those objects have to implement the following interface (methods):

 ->key   the key of this object. must return some string.
 ->data hmm?
 ->set_data

=cut

#'

package Chj::Store;

use strict;

use Class::Array -fields=> ();


1;

__END__

  Design?
  - OO weil nix anderes weiss
  sollte wohl doch eher prozedural denken und dann oo machen aus datensammlungen die man will?


  - i give you a thing that can be sent signals

  neuer store,
  give to store

  objekt dem man sagen kann nimm diese daten

  


  ein store dem man obj's zum  ent-/beladen geben. jup

das obj muss seine daten präsentieren gemäss einem vordefinierten interface.
anderes interface als dieses hier



Welche strukturen soll es speichern koennen?

- collection.  key=>undef    hm wie?  emtpyfile oder symlink  aber  symlink rausfinden waere costly

PS das obj seine Daten holen lassen hätte vorteil dass es sie dann holen kann wenn es sie benoetigt
aber es muss dafur den eigenen  "handle" haben ?



- listen von listen?
 [ "fofo", $sublistref, "fasdsfsadf",...]

na  einfach data verlangen  wenn das 1 element isch dann isch das key (ausser es sei ne ref?)  und  

