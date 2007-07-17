# Sat Oct  8 16:29:37 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::catfiletrim

=head1 SYNOPSIS

 use Chj::catfiletrim;
 my $first_non_commented_line_trimmed= catfiletrim "foo";
 my @all_non_commented_lines_trimmed= catfiletrim "foo";
 catfiletrim "nonexistingfile" # returns undef/emtpy list.

=head1 DESCRIPTION

=head1 NOTE

I'm not putting this into Chj::IO::File because I think it would be overload
(even if requiring dependencies only on usage, it's still codewise on the bloat
side; put such utils into their own packages).

=cut


package Chj::catfiletrim;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(catfiletrim);

use strict;

use Chj::xopen 'xopen_read';
#use Chj::trimspace;ehgibts nich
use Chj::chompspace;
use POSIX 'ENOENT'; ##

sub catfiletrim { # return undef if file doesn't exist.  assume only one line of input but ignore comment lines. (well or return all noncommented lines in list context?.)
    my ($path)=@_;
    my $wantarray= wantarray;
    my @res;
    eval {
	#my $cnt= xopen_read($path)->xcontents;
	my $f= xopen_read($path);
	while(<$f>) {
	    next if /^ \s* \# /x;
	    push @res, Chj::chompspace::chompspace $_;
	    if (!$wantarray) {
		last;
	    }
	}
    };
    if (ref$@ or $@) {
	if($Chj::IO::ERRNO and $Chj::IO::ERRNO == ENOENT) {
	    return
	} else {
	    die
	}
    } else {
	if ($wantarray) {
	    @res
	} else {
	    $res[0]
	}
    }
}
*Chj::catfiletrim= \&catfiletrim;


1
