#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Net::HTTPS

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Net::HTTPS;

use strict;

use Chj::Socket::SSL;

#use base "Net::HTTP";
#foo. seems too complicated, not openly designed. don't see how to
# feed a port (filehandle) there. seems to reopen new ones.

use Chj::Parse::Location::URI;

use Class::Array -fields=>
  -publica=>
  
  ;



sub get_url_to {
    my $class=shift;
    @_==2 or die "wrong number of arguments";
    my ($url,$out)=@_;
    #my $s= $class->SUPER::new;
    #(@$s[])=@_;
    my $uri= Chj::Parse::Location::URI->new($url);
    my $port= Chj::Socket::SSL->new_host_port ($uri->host, $uri->port); # or die?
    $port->xvalid;# force certificate check, throw exception if not valid.
    $port
    #$s
}

#sub DESTROY {
#    my $s=shift;
#    local (,Inappropriate ioctl for device,0);
#    # ç rausschmeissen wenn nicht benutzt, ebenso wie sub new
#    $s->SUPER::DESTROY; # or rather NEXT::
#}

end Class::Array;

