# Sun Nov  7 21:45:11 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Crypt::Test::Crypt_OpenSSL_RSA

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Crypt::Test::Crypt_OpenSSL_RSA;
use strict;

use Crypt::OpenSSL::RSA;

use Class::Array -fields=>
  ;


#sub new_public_key {
#    
#jo, warummmmm denn sollte man das?

#ach, um den namespace weg zu nehmen?.

sub new {
    "Crypt::OpenSSL::RSA"
}
# damit isch der dispatch danach gleich direkt ins eigentliche modul. work done.

1;
