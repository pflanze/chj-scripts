# Mon May 24 17:15:23 2004  Christian Jaeger, christian at jaeger mine nu
# Sat, 31 Mar 2007 14:08:52 +0200

# Copyright 2004, 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vservers

=head1 SYNOPSIS

 my @vservers= Chj::Vservers->new->all_running;
 # or even: since we don't really have any data to put into the Vservers object:
 # my @vservers= Chj::Vservers->all_running;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item all_running

Returns list of all running vservers as Chj::Vserver objects in list context,
or an iterator in scalar context.

=back

=cut


package Chj::Vservers;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
use strict;

use Chj::Vserver;
use Chj::xopen ();
use Chj::VserverSettings '$etcbase';

use Class::Array -fields=> ();


sub all {
    my $proto=shift;
    map {
	my $contextfile= $_;
	my $ctxid= Chj::xopen::xopen_read ($contextfile)->xreadline_chomp;
	# have to check for definedness here "right?". rileability he
	($ctxid and $ctxid=~ /^\d+\z/) or die "invalid contents '$ctxid' in '$contextfile'";
	# well Sinn von $ctxid ist nicht ganz obvious wenn ich ihn dann doch Vserver obj nicht gebe
	$contextfile=~ m|^\Q$etcbase\E/+(\w+)/+context\z| or die "??: '$contextfile'";
	my $name=$1;
	Chj::Vserver->new($name);
    } glob "$etcbase/*/context"
}

sub all_running {
    my $proto=shift;
    grep {
	$_->is_running
    } $proto->all
}

sub all_with_unification {
    my $proto=shift;
    grep  {
	$_->has_unification
    } $proto->all
}

1;
