#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::home

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::home;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

#our $HOME=

sub xHOME () {
    defined (my $home=$ENV{HOME})
      or die "environment variable HOME is not set";
    length ($home)
      or die "environment variable HOME is the empty string";
    $home
      or die "environment variable HOME is false";
    $home=~ m|^/|
      or die "environment variable HOME does not start with a slash: '$home'";
    $home
}

sub xhome () {
    
}

#sub xrealuserhome () {
#ehr, this is what's interestin right?:
sub xeffectiveuserhome () {
    my $uid= $>;
    
}

1
