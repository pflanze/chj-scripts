#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Lsof

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Lsof;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(readlsof);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::IO::Command;

sub readlsof {
    my ($opts, $put_f)=@_; #, $put_p

    my $lsof= Chj::IO::Command->new_sender("lsof","-F0", @$opts);

    local $/= "\0";
    my $p_record;
    my $f_record; # contains '_p' field with p_record
    my $reading_record; # one of the above
    my $end_record= sub {
	# ending previous f record
	if (defined $f_record) {
	    &$put_f($f_record);
	}
	$f_record= {
		    _p=> $p_record
		   };
	# and switch to reading it
	$reading_record= $f_record;
    };
    while (<$lsof>) {
	chomp;
	#my $key= substr $_,0,1;
	#my $val= substr $_,1;
	#odd, it prepends a newline before the switching fields
	my ($key,$val)= /^\n?(.)(.*)/s;
	#warn "key='$key'";
	if ($key eq 'p') {
	    # new p record;
	    $p_record={};
	    # and switch to reading it
	    $reading_record= $p_record;
	    #&$put_p($p_record) if defined $record;
	    # ^ whatever. above. or  when switching to f occors?
	    undef $f_record;
	} elsif ($key eq 'f') {
	    &$end_record;
	}
	$$reading_record{$key}=$val;
    }
    $lsof->xxfinish;
    &$end_record
      #well includes initializing p_record for nothing. w'ever
}

1
