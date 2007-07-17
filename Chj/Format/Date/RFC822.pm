# Mon Feb 13 00:28:45 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Date::RFC822

=head1 SYNOPSIS

=head1 DESCRIPTION

calls Chj::Format::Time::Mail::format_time_mail_date underneath.

(i did this class to make it more consistent
with  Chj::Parse::Date::*)

=cut

# 'HMM should we have called this Chj::Parse::Date::RFC822  yes of course'


package Chj::Format::Date::RFC822;

use strict;


use Chj::Format::Time::Mail (); #('format_time_mail_date');

use Class::Array -fields=>
  -publica=>
  ;


#sub unix_to_822 {
sub from_unix { # damit es dann so ausschaut: $format_822->from_unix($x)
    my $s=shift;
    Chj::Format::Time::Mail::format_time_mail_date $_[0];
}#schon bireweich?


end Class::Array;
