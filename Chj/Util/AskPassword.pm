# Thu Jun 19 11:56:43 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Util::AskPassword

=head1 SYNOPSIS

 use Chj::Util::AskPassword; 
 my $pw= askpassword "Prompt: ";

=head1 DESCRIPTION

Ask for a text (after an optional prompt) on STDIN, without echoing it
to the terminal. It is returned without a terminating newline.

=head1 BUGS

Should maybe some excension to my Chj::IO:: classes - so that one
could say

 $stdout->print_unbuffered("Prompt: ");
 my $pw= $stdin->askpassword;

but currently I dunno much about what is the best mix of the two worlds.

=cut


package Chj::Util::AskPassword;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(askpassword);

use strict;

use IO::Stty;

sub askpassword {
    my ($prompt)=@_;
    if (defined $prompt) {
	local $|=1;
	print $prompt;
    }
    my $old_mode=IO::Stty::stty(\*STDIN,'-g');
    IO::Stty::stty(\*STDIN,'-echo');
    my $pw = <STDIN>; chomp $pw;
    IO::Stty::stty(\*STDIN,$old_mode);
    if (defined $prompt) {
	print "\n";
    }
    $pw
}


1;
