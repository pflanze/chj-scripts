# Sun Mar 30 23:33:28 2003
# Copyright 2001 Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# Published under the same terms as perl.
#
# $Id$

=head1 NAME

Chj::Cwd

=head1 SYNOPSIS

 use Chj::Cwd;
 print cwd,"\n";

=head1 DESCRIPTION

Implements a super fast cwd function on linux with /proc filesystem,
many times faster than everything Cwd.pm offers. And it looks safe as well.

On other systems, falls back to the standard Cwd::cwd.

Hmmmmmm, /proc method does not work in some conditions. Prolly it was
the euid!=ruid case. So, after realizing that POSIX.pm already has an xs getcwd
function (arghhhh) calling getcwd(2) I'm now aliasing to that one insted.

=cut

#'

package Chj::Cwd;

@EXPORT="cwd";
require Exporter;
@ISA="Exporter";

use strict;

#if (readlink "/proc/$$/cwd") {
#    *cwd= sub {
#	readlink "/proc/$$/cwd" or die "error reading from /proc filesystem: $!";
#    }
eval {
    require POSIX;
    import POSIX; ## needed?
};
if (!$@) {
    *cwd= \&POSIX::getcwd;
} else {
    require Cwd;
    *cwd= \&Cwd::cwd;
    # Well, instead we could probably also reimplement fastcwd from Cwd.pm
    # to not use chdir (but stat "../"x$n instead), right? But I'm lazy and
    # only use linux.
}



1;
