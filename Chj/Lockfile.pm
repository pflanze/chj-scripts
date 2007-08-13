# Mon Aug 13 14:15:56 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Lockfile

=head1 SYNOPSIS

=head1 DESCRIPTION

 use Chj::Lockfile;
 {
    my $lock= Chj::Lockfile->get("path/to/foo" [, 0600 ] ); # permissions. optional. umask masked.
    ...critical section...
 }

=cut


package Chj::Lockfile;

use strict;

use Chj::xsysopen ();
use Fcntl ':flock';

use Class::Array -fields=>
  -publica=>
  #'maybe_mode', hm really?
  'fh',
  ;

our $verbose=0;

sub new {
    my $class=shift;
    my ($path,$maybe_mode)=@_;
    my $s= $class->SUPER::new;
    $$s[Fh]= Chj::xsysopen::xsysopen_append($path,$maybe_mode);#ok?
    $s
}

sub get {
    my $class=shift;
    $class->new(@_)->lock_ex
}

sub lock_ex {
    my $s=shift;
    print STDERR "getting lock $s (".$$s[Fh]->path.").." if $verbose;
    flock ($$s[Fh], LOCK_EX) or die "can't get lock on ".$$s[Fh]->path.": $!";
    print STDERR "got it.\n" if $verbose;
    $s
}

# could add lock_sh and unlock operations if wanted.
# atm it's unlocked when released (because of closing).


sub DESTROY {
    my $s=shift;
    if ($verbose) {
	print STDERR "releasing lock $s (".$$s[Fh]->path.")\n"
    }
}

end Class::Array;

__END__

HMM todo find out what's the problem with this:

calc> :l { my $l= new Chj::Lockfile "Hallo"; $l->lock_ex ; 0 }
0
calc> :l { my $l= get Chj::Lockfile "Hallo"; 0 }
0
these are ok, release the lock at the end of the scope

calc> :l $l= new Chj::Lockfile "Hallo"
Chj::Lockfile=ARRAY(0x84c2298)
calc> :l $l->lock_ex
Chj::Lockfile=ARRAY(0x84c2298)
calc> :l undef $l

this does not release it. even after subsequent
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1
calc> :l 1
1

where could it be hanging on ?
