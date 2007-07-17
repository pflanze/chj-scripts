# Sun Nov  7 21:52:48 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Crypt::Test::Crypt_CBC_with_Blowfish::Key

=head1 SYNOPSIS

=head1 DESCRIPTION

 - contains plaintext key
 - can encrypt


=cut


package Chj::Crypt::Test::Crypt_CBC_with_Blowfish::Key;
use strict;
use Crypt::CBC;

use Class::Array -fields=>
  'key', #string
  'cipher', #obj
  ;


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    ($$self[Key])=@_;
    $$self[Cipher]= Crypt::CBC->new({key=> $$self[Key],
				    cipher=> "Blowfish",#perl isch krank, (die leut)
				    regenerate_key=>1,#? waschdas?
				    });# mann, { } wirklich nötig.
    $self
    # eh nein viel simpler?: Crypt::CBC->new(...) zurückgeben?  ach weissjonichtsovoraus
}

sub encrypt {
    my $s=shift;
    #my $textrf= \ $_[0];
    $$s[Cipher]->encrypt($_[0]);
}
sub decrypt {
    my $s=shift;
    #my $textrf= \ $_[0];
    $$s[Cipher]->decrypt($_[0]);
}



1;
