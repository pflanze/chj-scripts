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

sub mget { #(get; did I call some such mget instead? in thea anyway. hm yeah call it mget)
    my $s=shift;
    @_==1 or croak "expecting 1 argument";
    my ($key)=@_;
    my $k=_escape_key $key;
    if (my $d= do {
	# weil ich nur xopendir habe. und nid mal richtige exns
	# ach. hm.xopendir "$$self[Basedir]/$k/";
	my $res= eval {
	    xopendir "$$s[Basedir]/$k/"
	};
	my $e=$@; my $errno= $!+0;
	if (ref $e or $e) {
	    if ("$e"=~ /^xopendir/ and $errno == ENOENT) {
		undef
	    } else {
		die $e
	    }
	} else {
	    $res
	}
    }) {
	map {
	    # (( ignore items ending in ~ ? *No* of course. heh. ))
	    # but, ignore those not starting in = right? because of left-over tmp files.!
	    #should _unescape croak in such cases instead of blindingly doing substr? TODO
	    if (/^=/) {
		_unescape ($_)
	    } else {
		()
	    }
	} $d->xnread
    } else {
	()
    }
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
	my $d=xopendir $dirpath;###TODO bug right?: dies if none there!
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
