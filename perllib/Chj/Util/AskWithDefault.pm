# Sun Jun 22 01:19:40 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::AskWithDefault

=head1 SYNOPSIS

=head1 DESCRIPTION

only for backwards compatibility, use Chj::Util::Ask qw(ask_string) instead.

=cut


package Chj::Util::AskWithDefault;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(askwithdefault); ## oooohm, should we I call it ask_with_default?

use strict;
use Carp;

use Chj::Util::Ask qw(ask_string);

sub askwithdefault {
    @_==2 or croak "askwithdefault: must give 2 parameters";
    my ($prompt,$value)=@_;
    ask_string($prompt,defined $value ? $value : "");
}

1;
