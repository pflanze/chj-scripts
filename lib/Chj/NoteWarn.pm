#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::NoteWarn

=head1 SYNOPSIS

 use Chj::NoteWarn ();
 local $Chj::NoteWarn::attenuation_level= 1; # or NoteWarn_attenuation_level(1);
 # silence NOTE (level 1) down, only WARN (level 2) and above make it out

 use Chj::NoteWarn ();
 WARN "foo";
 NOTE "Bar"; # silenced

=head1 DESCRIPTION


=cut


package Chj::NoteWarn;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(NOTE
	   WARN
	   PROBLEM
	   NoteWarn_attenuation_level
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# XX just because there's no way to get the standard warn handler if
# $SIG{__WARN__} is undefined:
use Chj::Try 'standard_warn';

sub KIND ($) {
    my ($str)=@_;
    bless \$str, "KIND"
}

our $attenuation_level=0;

sub NoteWarn_attenuation_level {
    if (@_==1) {
	($attenuation_level)=@_;
    } elsif (@_==0) {
	$attenuation_level
    } else {
	die "expecting 0 or 1 arguments"
    }
}

our $levels=
  +{
    NOTE=> 1,
    WARN=> 2,
    __WARN__=>5, # to be used as default level, i.e. by 'warn'
    PROBLEM=> 10,
   };

sub mk {
    my ($key)=@_;
    my $kind= KIND $key;
    my $level= $$levels{$key}; defined $level or die;
    sub {
	if ($attenuation_level < $level) {
	    unshift @_, $kind;
	    goto ($SIG{__WARN__}||\&standard_warn)
	}
    }
};

*NOTE= mk "NOTE";
*WARN= mk "WARN";
#*__WARN__= mk "__WARN__"; to be used indirectly by 'warn' only
*PROBLEM= mk "PROBLEM";


1
