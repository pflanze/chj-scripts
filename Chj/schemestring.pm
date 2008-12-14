# Sun Apr 24 13:08:42 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::schemestring

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::schemestring;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(schemestring
	   schemestring_oneline
	   parse_schemestring
	  );

use strict;

sub schemestring {
    my ($s)=@_;
    $s=~ s/\\/\\\\/sg;
    $s=~ s/\"/\\\"/sg;
    "\"$s\""
}

sub schemestring_oneline {
    my ($s)=@_;
    $s=~ s/\\/\\\\/sg;
    $s=~ s/\"/\\\"/sg;
    $s=~ s/\n/\\n/sg;
    $s=~ s/\r/\\r/sg;
    $s=~ s/\t/\\t/sg;
    "\"$s\""
}

sub parse_schemestring {
    # expects the string including the leading and terminating double quotes
    my ($s)=@_;
    local $_=$s;
    # strip leading and ending double quotes:
    s/^.*?"//;
    s/"[^"]*\z//;

    # backslashes are 'difficult': one fresh backslash and a char is to be interpreted. ah, actually easy?:
    s{\\(.)?}{
        die "invalid schemestring ending with escaped end quote: '$s'"
           unless defined $1;
        (($1 eq '\\') ? '\\' : #yes it's different from sh where '\' would be the right thing
         ($1 eq 'n') ? "\n" :
         ($1 eq 'r') ? "\r" :
         ($1 eq 't') ? "\t" :
         ($1 eq '"') ? "\"" :
         die "unfinished: unknown backslashed code sequence '$1' in: '$s'")
    }seg;
    $_
}

*Chj::schemestring= \&schemestring;
*oneline= \&schemestring_oneline;

1
