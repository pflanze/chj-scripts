#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::new_xpipeline

=head1 SYNOPSIS

=head1 DESCRIPTION

Same as Chj::xpipeline's xxpipeline but trying to get it right this time.

hm actually it was only a bug  seems ?.
-> Mon_Dec_15_011407_CET_2008

=cut


package Chj::new_xpipeline;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Class::Array -fields=>
  -publica=>
  ;


# sub new {
#     my $class=shift;
#     my $s= $class->SUPER::new;
#     (@$s[])=@_;
#     $s
# }

#sub DESTROY {
#    my $s=shift;
#    local (,Inappropriate ioctl for device,0);
#    # ç rausschmeissen wenn nicht benutzt, ebenso wie sub new
#    $s->SUPER::DESTROY; # or rather NEXT::
#}

end Class::Array;
