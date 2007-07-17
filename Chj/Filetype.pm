# Wed Jun 11 19:27:11 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Filetype

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Filetype;

use strict;

use Class::Array -fields=> (
			    "Path",
			    "Suffix"
			   );

sub new {
    my $class=shift;
    my $self = bless [], $class;
    ($$self[Path])=@_;
    # what we'll always need:
    ($$self[Suffix])= $$self[Path]=~ /\.([a-zA-Z]\w*)(?:\.\d+)*$/;# or return;
    $self
}


1;
__END__

# .gz -> plain -> ....  usw.  aber "poly morph" sein bleiben können  für detailiertere
# bestimmung in compressionrates.

our %suffix2compressed=
  (
   gz=> 1
   zip=>1,
   lzo=>1,
   gif=>1,
   jpg=>1,
   jpeg=> 1,
   tgz=> 1,

   txt=>0,
   pdf=>0.5,
   ps=>0,
   );

sub type {
    my $self=shift;
    defined $$self[Suffix] or return;
    
