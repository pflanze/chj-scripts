# Sun Oct 24 00:09:08 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Shelllike::Stamp

=head1 SYNOPSIS

=head1 DESCRIPTION

just an aliase for Chj::FileStore::Stamp

(the latter being preferred)

=cut


use Chj::FileStore::Stamp;

*Chj::Shelllike::Stamp:: = *Chj::FileStore::Stamp::;

