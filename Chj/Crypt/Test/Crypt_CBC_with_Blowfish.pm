# Sun Nov  7 21:50:24 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Crypt::Test::Crypt_CBC_with_Blowfish

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Crypt::Test::Crypt_CBC_with_Blowfish;

use strict;

use Chj::Crypt::Test::Crypt_CBC_with_Blowfish::Key;
use Chj::IO::File;
use Class::Array -fields=>
  ;

sub new {
    __PACKAGE__
}

sub new_public_key {
    my $class=shift;
    #my ($path)=@_;
    #Chj::Crypt::Test::Crypt_CBC_with_Blowfish::Key->new
    #	( Chj::IO::File->xopen("<",$path)->xcontent );
    # EH.
    Chj::Crypt::Test::Crypt_CBC_with_Blowfish::Key->new( $_[0] );
}
*new_private_key= \&new_public_key;

sub generate_key {
    die "ç well einfach zufallsstring generieren.  ur alte sache"
}



1;
