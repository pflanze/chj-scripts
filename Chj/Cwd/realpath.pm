#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Cwd::realpath

=head1 SYNOPSIS

 use Chj::Cwd::realpath;
 print xrealpath "/dev/hda11"; # die's if the given path does not resolve
 print realpath("/dev/hda11")||die;

=head1 DESCRIPTION

Replacement for my XS-based module of the same namespace (interface to
the realpath function from the Unix C library), but relying on Perl
builtins or base libraries (currently using Cwd::abs_path and -e,
which is stupid).

=cut


package Chj::Cwd::realpath;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(realpath xrealpath);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub realpath;
sub xrealpath;

if ($ENV{"USE_Chj_Cwd_realpath"}) {
    my $version= $^V;
    $version=~ s|^v||;
    my $path= "/usr/local/lib/perl/$version/Chj/Cwd/realpath.pm";
    require $path;
} elsif ($ENV{"USE_Chj_xrealpath"}) {
    require Chj::xrealpath;
    *realpath= \&Chj::xrealpath::realpath;
    *xrealpath= \&Chj::xrealpath::xrealpath;
} else {
    require Cwd;
    *realpath= sub {
	my ($path)=@_;
	#Cwd::realpath ($path) nope.

	my $tmp= Cwd::abs_path ($path) // return;
	# XX race condition, which is bad, but it's not so bad since
	# the program would need some locking anyway. But, also, twice
	# the cost which is of course stupid. Different solution?
	-e $tmp ? $tmp : undef
    };
    *xrealpath= sub {
	my ($path)=@_;
	realpath($path) // die "xrealpath($path): $!";
    };
}

use Chj::TEST;

our $test_d;
sub test_prepare {
    require Chj::xtmpdir;
    $test_d= Chj::xtmpdir::xtmpdir();
}

our $test_d_abs;

TEST {
    test_prepare;

    $test_d_abs= xrealpath $test_d; 7
} 7;

TEST {
    require Chj::xperlfunc;
    Chj::xperlfunc::xsystem ("touch", "$test_d/foo");

    xrealpath ("$test_d/foo") eq "$test_d_abs/foo"
} 1;

TEST {
    realpath ("$test_d/foo") eq "$test_d_abs/foo"
} 1;

TEST {
    realpath ("$test_d/bar")
} undef;

TEST {
    eval {
	xrealpath ("$test_d/bar"); 7
    } || "exn"
} "exn";

TEST {
    # cleanup
    unlink "$test_d/foo"
} 1;


Chj::TEST::run_tests (__PACKAGE__)
  if $ENV{RUN_TESTS_Chj_Cwd_realpath};

1
