# Mon Jul 14 07:21:22 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::xtmpdir

=head1 SYNOPSIS

 xtmpdir($opt_basepath,$opt_mask)

=head1 DESCRIPTION

By default, dirs are created below /tmp/, which can be changed by
setting the CHJ_TEMPDIR (path to a directory) or CHJ_TEMPDIR_BASEPATH
(a basepath) env vars, or passing a value for $opt_basepath. A
"basepath" is simply prefixed to the random path, i.e. if it does not
end in a slash, the last part after the slash will be the prefix to
the name of the created temp directory.

=cut


package Chj::xtmpdir;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xtmpdir);

use strict;
use Chj::IO::Tempdir;


sub xtmpdir {
    unshift @_, 'Chj::IO::Tempdir';
    goto &Chj::IO::Tempdir::xtmpdir;
}

1;
