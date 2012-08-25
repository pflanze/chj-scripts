#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Debian::DpkgAptList

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse files with this format:

 Key1: value1_of_first_record
 Key2: value2
 Key3: value3a
  value3b
  value3c
 Key4: value4

 Key1: value1_of_second_record
 ....

dpkglist($keys,$cb) parses "/var/lib/dpkg/status"

aptlist($keys,$cb) parses "/var/lib/apt/extended_states"

they both call $cb with a hash containing the key/value pairs for the
keys in $keys for each record. More precisely, each key is paired with
a list of list of line entries for that key (the first list containing
multiple entries if the key appears multiple times, and the second
list containing multiple entries if there were several lines for a key
entry).

=head1 BUGS

This doesn't obtain any lock, and on top of that uses mmap, if the
files change while this is running weird things will happen.

=cut


package Chj::Debian::DpkgAptList;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 dpkgaptlist_file
		 dpkglist
		 aptlist
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

BEGIN {
    eval 'use Mmap';
    if ($@) {
	eval 'use Sys::Mmap';
	if ($@) {
	    die $@
	}
    }
}

sub collect_keys {
    my ($keys)=@_;
    sub {
	my $collection= undef; #{};
	my $key=undef;
	my $lines=undef;
	my $pos;
	while ($_[0]=~ /\G([^\n]+?\n)/sgc) {
	    $pos= pos($_[0]);
	    my $line= $1; #now we have the copy. ha
	    if ($line=~ /^([\w-]+):[ \t]*(.*)/s) {
		push @{$$collection{$key}}, $lines
		  if $lines;
		$key= $1;
		if ($$keys{$key}) {
		    $lines=[$2];
		} else {
		    $lines=undef;
		}
	    } else {
		# continuation line?
		if ($line=~ /^ (.*)/s) {
		    push @$lines, $1 if $lines;
		} else {
		    die "parse failure, no match for line '$line'";
		}
	    }
	}
	($collection,$pos)
    }
}

sub dpkgaptlist_file {
    my ($path)=@_;
    sub {
	@_==2 or die "need 2 arguments";
	my ($keys,$cb)=@_;
	my $collect= collect_keys($keys);

	open my $fh, "<", $path
	  or die "open '$path': $!";
	my $in;
	mmap ($in,0, PROT_READ, MAP_SHARED, $fh)
	  or die "mmap: $!";

	# turn mmap into line based file reading; kind of a joke
      DO: {
	    my ($coll,$endpos)= &$collect ($in);
	    if (defined $coll) {
		&$cb($coll);
		pos($in)=$endpos+1;
		redo DO;
	    }
	}

	munmap($in)
	  or die "munmap: $!";
	close $fh
	  or die "close: $!";
    }
}

*dpkglist= dpkgaptlist_file "/var/lib/dpkg/status";

*aptlist= dpkgaptlist_file "/var/lib/apt/extended_states";

1
