# Thu Oct 18 16:23:15 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::SuperPATH

=head1 SYNOPSIS

 use Chj::Unix::SuperPATH;
 use Chj::xperlfunc;

 strip_me_from_PATH;
 xexec $myname,@args;
 # or just:  xsuperexec $myname,@args

=head1 DESCRIPTION

Remove the dirname of the currently running program from the PATH
environemntal variable.

=head1 NOTES

Why didn't I call it setSuperPATH or so? I thought, maybe I'd make a
Supercall sub { } child-forking procedure sometime. Ah, let's create
a xsuperexec procedure!

=cut


#'

package Chj::Unix::SuperPATH;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   xsuperexec
	   strip_me_from_PATH
	  );
@EXPORT_OK=qw(
	      strip_dirname_from_PATHvalue
	      strip_dirname_from_PATH
	     );
%EXPORT_TAGS=(all=>[@EXPORT_OK,@EXPORT]);

use strict;

#use Cwd 'abs_path';  no, grr, does output warning.
use Chj::Cwd::realpath 'realpath';
use Chj::FP::Memoize 'memoize_1ary';
use Chj::xperlfunc 'dirname';
use Chj::singlequote ':all';
use Carp;

*caching_realpath= memoize_1ary \&realpath;


sub strip_dirname_from_PATHvalue ($ $ ) { # function
    my ($dirname,$PATHvalue)=@_;
    if (my $key= caching_realpath($dirname)) {
	join(":",
	     grep {
		 if (my $value= caching_realpath($_)) {
		     not($key eq $value)
		 } else {
		     1 # well could also strip it since it doesn't exist anyway, but be conservative
		 }
	     }
	     split /:/, $PATHvalue)
    } else {
	# no sense stripping a directory that doesn't exist
	undef
    }
}


sub strip_dirname_from_PATH ( $ ) { # procedure
    my ($dirname)=@_;
    if (my $newval= strip_dirname_from_PATHvalue($dirname,$ENV{PATH})) {
	$ENV{PATH}=$newval
    }
    ()
}

sub strip_me_from_PATH { # "me" rather meaning "my class", my directory in shell world.
    my ($maybe_dirname)=@_;
    if ($maybe_dirname) {
	if (-d $maybe_dirname) {
	    strip_dirname_from_PATH $maybe_dirname
	} elsif (-e _) {
	    strip_dirname_from_PATH dirname $maybe_dirname
	} else {
	    die "strip_me_from_PATH: '$maybe_dirname' does not exist";
	}
    } else {
	strip_dirname_from_PATH dirname $0
    }
}

sub xsuperexec {
    strip_me_from_PATH;
    # nope, localize the change, in case the exec fails!:
    #local $ENV{PATH}= 
    no warnings;
    exec @_ or croak "xsuperexec ".singlequote_many(@_).": $!";
}

1
