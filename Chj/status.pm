# Thu Dec  2 03:18:22 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004-2020 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::status

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 NOTE

Use L<Chj::Unix::Exitcode> instead now, ok?

=cut


package Chj::status;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      exitstatus
	      signal
	      status
	     );

use strict;
use utf8;

# sub status {
#     my $st= @_ ? $_[0] : $?;
#     my $exitvalue= $st >> 8;
#     my $signal= $st & 255;
#     wantarray ? ($exitvalue,$signal) : "$exitvalue
# }
# ps irgendwo hab ichs schon mal geschrieben wo?. (bigl?)

sub exitstatus {
    my $st= @_ ? $_[0] : $?;
    $st >> 8
}
sub signal {
    my $st= @_ ? $_[0] : $?;
    $st & 255
}

sub status_list {
    (&exitstatus, &signal)
}

sub status_str {
    if (my $s=&signal) {
	#irgendwo habe ich schon mal!
	# Frage ob es terminiert wurde.
	# Annahme dass nur für wait funktionniert also  ich mein echte exits hum
	"killed by signal $s" #loclz..
    } else {
	"exited with status ".&exitstatus
    }
}

sub status {
    wantarray ? &status_list : &status_str
}


1
