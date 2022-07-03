# Mon Jun 16 02:14:23 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::Unix::Groups

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item secondarygroups ( username )

Returns a list of id's for the given user.
Dies if the user does not exist.
Note: this currently forks off a process and executes /usr/bin/id.

=back

=cut


package Chj::Unix::Groups;
@EXPORT_OK=qw(secondarygroups);
@ISA="Exporter";
require Exporter;

use strict;
use Chj::backtick 'xputget';
use Carp;

#getgrent?
sub secondarygroups {
    my ($username)=@_;
    #    my getgrnam($username)
    #      or die "unknown user or no group for user '$username' ??";
    # eh nein das ist wirklich  gruppeninfo abfragen?.
    # ps. warum nicht das dingsda einlogg ?

    # hmm  how to redirect stderr?  not easy.
    local $ENV{LANG}="C";
    #my $supplgroups= xbacktick "/usr/bin/id","-G","--",$username;
    my ($supplgroups,$errs); ##=("","");#gr nein, sondern unten [""] oder "" statt [] hat es gebraucht.
    xputget "",[ "/usr/bin/id","-G","--",$username ], $supplgroups,$errs;
    if ($? != 0) {
	croak "secondarygroups: no such user '$username'".($errs=~/no.*user/i ? "" : " ($errs)")
    }
    #warn "\$supplgroups=$supplgroups";
    #my (@supplgroups)= $supplgroups=~ /^(?:\s*(\d+))*\s*\z/s or die "invalid formad of id output '$supplgroups'";
    #my (@supplgroups)= $supplgroups=~ /^(?:(\d+)\s+)*(\d+)\s*\z/sg ;#or die "invalid formad of id output '$supplgroups'";
    #my (@supplgroups)= $supplgroups=~ /^(?:\s*(\d+))*\s*\z/s or die "invalid formad of id output '$supplgroups'";
    #chomp $supplgroups;
    #$supplgroups.="world";
    #my (@supplgroups)= $supplgroups=~ /\G\s*(\d+)(?:\b|\z)/g or die;
    #my (@supplgroups)= $supplgroups=~ /\G\s*(\d+)(?:(?=\s)|\z)/g or die;
    
    my @supplgroups;
    push @supplgroups,$1 while $supplgroups=~ /\G\s*(\d+)\s*/sgc;
    die "invalid format of id output '$supplgroups'" if pos $supplgroups < length $supplgroups;
    #print "User $username has supp groups @supplgroups\n";
    @supplgroups
}

1;
