# Thu Dec 20 06:02:53 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::Date

=head1 SYNOPSIS

 my $parser= Chj::Parse::Date::Localtime->new;
 my $unixtime= $parser->xparse("Don Dez 20 05:09:38 MET 2007");
 my $unixtime= $parser->parse("Don Dez 20 05:09:38 MET 2007")
   or die $parser->errmsg;


 NO   JUST USE  use Date::Parse; str2time !!!

=head1 DESCRIPTION

Parse the date format as printed by the "date" utility with LANG=C locale.

=cut


package Chj::Parse::Date::Date;

use strict;

use Class::Array -fields=>
  -publica=> 'error', #numeric
  ;

sub parse {
    my $s=shift;
    my ($str)=@_;
    
}
die "JUST USE  use Date::Parse; str2time !!!";
#GRRRRRRRR

end Class::Array;
