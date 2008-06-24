# Wed Jun 25 00:40:40 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Trash

=head1 SYNOPSIS

 use Chj::App::Trash;
 my $trash= new Chj::App::Trash;
 $trash->trash(@paths);
 #print Dumper $trash->ls; not yet impl.
 # ..

=head1 DESCRIPTION


=cut


package Chj::App::Trash;

use strict;

use Carp; #always. well. we pay the (electricity bill)
use POSIX 'EEXIST'; #dito.joyofprl.5.

use Class::Array -fields=>
  -publica=>
  'trashdir', # for now; simplicistic.as always.(just.a.basedir.)
  ;

our $trash_alternatives=
  [
   $ENV{TRASHCAN}, # or make this special priority hm?
   $ENV{HOME}."/Desktop/Trash",
   $ENV{HOME}."/Desktop/Mülleimer",
   $ENV{HOME}."/.trash",# lowercase now so that hopefully gnome won't move it.
  ];
our $trash_to_create_index= -1; # the last.

sub trashdir {
    my $s=shift;
    $$s[Trashdir] || do {
	my $res;
      TRY: {
	    for (@$trash_alternatives) {
		next unless $_;
		if (-e $_) {
		    $res=$_; last TRY;
		}
	    }
	    $res= $$trash_alternatives[$trash_to_create_index]
	}
	$res
    }
}


sub maybe_create_trashdir {
    my $s=shift;
    my $path= $s->trashdir;
    if (mkdir $path, 0700) {
	1
    } else {
	my $errno= 0+$!;
	if ($errno == EEXIST) { ### silly if it did check for -e already above.
	    0
	} else {
	    croak "maybe_create_trashdir: could not create '$path': $!"
	}
    }
}

use Chj::FP::Memoize "memoize_thunk";
use Chj::xperlfunc 'dirname', 'basename';

sub Mv { #rename would give 'Invalid cross-device link'
    if (fork) {
	wait;
    } else {
	exec '/bin/mv', '--', @_
    }
}

sub trash {
    my $s=shift;
    $s->maybe_create_trashdir;
    my $trashdir= $s->trashdir;# as said. silly double mobble.
    #[is this  eiffelalike btw?]

    our $localtime= memoize_thunk sub {
	"".localtime()
    };
    our $appendi= do {
	my $n;
	sub {
	    my $oldn= $n++;
	    &$localtime . (defined ($oldn) ? "\#$oldn" : "");
	}
    };

    for my $path (@_) {
	my $onlyname= basename $path;
	if ($onlyname eq '.') {
	    warn "Ignoring '.'\n";
	    next;
	}
	if ($onlyname eq '..') {
	    warn "Ignoring '..'\n";
	    next;
	}
	my $trashedpath= "$trashdir/$onlyname";
	if (-e $trashedpath) {
	    ##btw assumes no concurrent instances of trashing running!.
	    ##todo locking hm?.or?.
	    Mv($path, "$trashedpath (trashed ".&$appendi.")");
	} else {
	    Mv($path, $trashdir);
	    ##[ $trashdir better than $trashedpath in conflict situations?]
	}
    }
}


end Class::Array;
