#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::TEST

=head1 SYNOPSIS

 use Chj::TEST;

 TEST { 1+1 } "2"; # ok, as it should be
 TEST { 1+1 } 2; # always expect a string, but this will
                 # work thanks to canonicalization
 TEST { 1+1 } 2.; # also succeeds; you really need to give strings to be precise
 TEST { 1+1 } "2."; # fails as expected
 TEST { 1+1 } '"2"'; # fails as expected
 TEST { (1+1)."" } '"2"';  # succeeds as expected

 use Chj::TEST ':all';
 run_tests;

=head1 DESCRIPTION


=cut


package Chj::TEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST);
@EXPORT_OK=qw(run_tests);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

our $tests_by_package={};
our $num_by_package={};

sub TEST (&$) {
    my ($proc,$res)=@_;
    my ($package, $filename, $line) = caller;
    $$num_by_package{$package}++;
    push @{$$tests_by_package{$package}},
      [$proc,$res, $$num_by_package{$package}, ($package, $filename, $line)]
}

use Data::Dumper;

sub eval_test ($$) {
    my ($t,$stat)=@_;
    my ($proc,$res, $num, $package, $filename, $line)=@$t;
    print "running test $num..";
    my $gotval= &$proc;
    my $gotstr= Dumper $gotval;
    my $ok= sub {
	print "ok\n";
	$$stat{success}++
    };
    if ($gotstr eq $res) {
	&$ok;
    } else {
	# may need to re-stringify result value (canonicalize)
	my $resval= eval $res;
	my $resstr= Dumper $resval;
	if ($gotstr eq $resstr) {
	    &$ok
	} else {
	    #fail
	    print "FAIL at $filename line $line:\n  expected: $resstr       got: $gotstr";
	    $$stat{fail}++
	}
    }
	
}

sub run_tests_for_package {
    my ($package,$stat)=@_;
    if (my $tests= $$tests_by_package{$package}) {
	local $|=1;
	print "=== running tests in package '$package'\n";
	for my $test (@$tests) {
	    eval_test $test, $stat
	}
    } else {
	print "=== no tests for package '$package'\n";
    }
}

sub run_tests {
    my (@maybe_packages)=@_;
    my $stat= {success=>0, fail=>0};
    if (@maybe_packages) {
	run_tests_for_package $_,$stat for @maybe_packages;
    } else {
	run_tests_for_package $_,$stat for keys %$tests_by_package;
    }
    print "===\n";
    print "=> $$stat{success} success(es), $$stat{fail} failure(s)\n";
    ()
}


1
