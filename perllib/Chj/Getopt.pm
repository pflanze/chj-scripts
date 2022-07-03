#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Getopt

=head1 SYNOPSIS

 use Chj::Getopt;
 our %opt;
 *opt= getopt("verbose","help","dry-run", "in=s", ...);
 #*opt= getopt_("verbose","help","dry-run", "in=s", ...);
 #      the latter turns '-' to '_' in keys

=head1 DESCRIPTION

Uses Getopt::Long to get options, hence changes @ARGV; the returned
hash is having all keys as given to Getopt, without the =.. parts, and
undef if not given by user, and the hash is locked, accesses to
non-existent keys will give an exception.

Exits with status 1 if there is an option parsing error.

=cut


package Chj::Getopt;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(getopt getopt_);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Getopt::Long;
use Hash::Util 'lock_hash';

sub getopt {
    my $res= +{map { my $str= $_;
		     $str=~ s/=.*//;
		     ($str=> undef) }
	       @_};
    GetOptions($res,@_) or exit 1;
    lock_hash %$res;
    $res
}

sub getopt_ {
    my $res0= getopt(@_);
    my $res1= +{map { my $key1=$_;
		      $key1=~ tr/-/_/;
		      ($key1=> $$res0{$_}) }
		keys %$res0};
    lock_hash %$res1;
    $res1
}

1
