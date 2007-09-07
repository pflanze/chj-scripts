# Wed Sep  5 23:20:01 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Detectoutgoing

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mail::Detectoutgoing;

use strict;

use Class::Array -fields=>
  -publica=>
  ;


# sub new {
#     my $class=shift;
#     my $s= $class->SUPER::new;
#     (@$s[])=@_;
#     $s
# }

sub head_is_outgoing {
    my $s=shift;
    my ($head)=@_;
    my @r= $head->headers("received");
    if (@r==0) {
	1
    } elsif (@r==1) {
	# check for squirrelmail thing.
	#     Received: from 10.0.1.1
	# 	    (SquirrelMail authenticated user chrismail)
	# 	    by 192.168.27.1 with HTTP;
	# 	    Sun, 25 Feb 2007 20:53:18 +0100 (CET)
	#     Message-ID: <36501.10.0.1.1.1172433198.squirrel@192.168.27.1>
	if (my $by= $r[0]->maybe_received_by) {
	    if (my $msgid= $head->maybe_header_value ("message-id")) {
		if ($msgid=~ /\@([^<>]+)/) {
		    $by eq $1
		} else {
		    warn "strange message-id: '$msgid'";
		    0
		}
	    } else {
		warn "has 1 received header but is missing message-id";#(ja  irgend  wo  solltemanimmer  loggenso  jo jo .)
		0
	    }
	} else {
	    # by not found.
	    warn "strange received header does not contain \"by\" part: ".Chj::singlequote($r[0]->value);
	    0
	}
    } else {
	0
    }
}

end Class::Array;
