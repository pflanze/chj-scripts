#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::NoteWarn

=head1 SYNOPSIS

 use Chj::NoteWarn ();
 local $Chj::NoteWarn::attenuation_level= 1;
 # silence NOTE (level 1) down, only WARN (level 2) and above make it out

 use Chj::NoteWarn ();
 WARN "foo"; # uses global::warn from Chj::Try
             #  to give possibly-contextual output
 NOTE "Bar"; # silenced

=head1 DESCRIPTION


=cut


package Chj::NoteWarn;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(NOTE
	   WARN
	   EMERGENCY);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::Try;

sub KIND ($) {
    my ($str)=@_;
    bless \$str, "KIND"
}

our $attenuation_level=0;

our $levels=
  +{
    NOTE=> 1,
    WARN=> 2,
    EMERGENCY=> 10,
   };

sub mk {
    my ($key)=@_;
    my $kind= KIND $key;
    my $level= $$levels{$key}; defined $level or die;
    sub {
	if ($attenuation_level < $level) {
	    unshift @_, $kind;
	    goto \&global::warn;
	}
    }
};

*NOTE= mk "NOTE";
*WARN= mk "WARN";
*EMERGENCY= mk "EMERGENCY";


1
