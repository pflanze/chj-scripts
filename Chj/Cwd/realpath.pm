# Tue Jun 17 12:03:13 2003  Christian Jaeger, christian.jaeger at ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Cwd::realpath

=head1 SYNOPSIS

 use Chj::Cwd::realpath;
 print xrealpath "/dev/hda11"; # die's if the given path does not resolve
 print realpath("/dev/hda11")||die;

=head1 DESCRIPTION

Interface to the realpath function from the Unix C library.

=head1 NOTE

An alternative is the abs_path function from the Cwd.pm module, but
in the perl 5.6.1 distribution it has a bug preventing it to work
for file arguments. I started making my own module before I've been
told that in perl 5.8 Cwd::abs_path works on files.

=head1 AUTHOR

Christian Jaeger

=cut

#'

package Chj::Cwd::realpath;
$VERSION= "0.1";
@EXPORT=qw(realpath xrealpath);
require Exporter;
require DynaLoader;
@ISA=qw(Exporter DynaLoader);

use strict;

__PACKAGE__->bootstrap;


1;

# ways to load a shared lib?  ExtUtils::Mkbootstrap? DynaLoader? XSLoader...
