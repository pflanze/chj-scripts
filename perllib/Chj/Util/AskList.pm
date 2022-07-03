# Sun Jun 22 08:51:06 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::AskList

=head1 SYNOPSIS

=head1 DESCRIPTION

User may enter *multiple answers* to one question.

=cut


package Chj::Util::AskList;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(asklist);

use strict;

sub asklist {
    my ($prompt)=@_;
    local$|=1;
  ALL:{
	print "$prompt\n";
	my $n=1;
	my @ret;
      ENTRY: {
	    print "$n: ";
	    my $line=<STDIN>;
	    if (!defined $line){ # Ctl-d
		print "Cancelling entry, starting over..\n";
		redo ALL;
	    }
	    chomp $line;
	    if (!length $line){
		return @ret;
	    }
	    push @ret,$line;
	    $n++;
	    redo ENTRY
	}
    }
}

1;
