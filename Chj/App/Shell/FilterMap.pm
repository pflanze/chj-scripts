# Sun Feb 10 06:11:54 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Shell::FilterMap

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::App::Shell::FilterMap;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Main);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

(my $email='pflanze%gmx,ch')=~ tr/%,/@./;

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);


our $description=
  { "filter"=> "If the cmd exits with a true value, the input record is written to stdout.",
    "map"=> "The output of the command is written as an output record to stdout." };

sub Main { #only to be called once!! (GetOptions)
    my ($name)=@_;
    my $description= $$description{$name}
      or die "?? '$name'";
    my $usage= sub {
	print STDERR map{"$_\n"} @_ if @_;
	print "$myname [--] cmd [args] '<>' [args]

  Reads records from stdin and runs cmd with args and the input record
  value substituted for the '<>' position.  If no '<>' is given, the
  value is appended to the argumet list of the cmd.

  $description

  Currently 'records' means 'lines'.

  (Christian Jaeger <$email>)
";
    exit (@_ ? 1 : 0);
    };

    use Getopt::Long;
    our $verbose=0;
    GetOptions("verbose"=> \$verbose,
	       "help"=> sub{&$usage},
	       ) or exit 1;
    &$usage unless @ARGV;

    my @cmd=@ARGV;

    # find the <> argument position:
    our $pos;
    {
	my $i=0;
	for (@cmd) {
	    if ($_ eq '<>') {
		if (defined $pos) {
		    die "$myname: @cmd: multiple '<>' given\n";
		}
		$pos= $i;
	    }
	    $i++
	}
    }
    defined $pos
      or $pos= @cmd;

    use Chj::IO::Command;

    my $recordsep="\n";
    local $/= $recordsep;
    #^- already prepare for changes.

    while (<STDIN>) {
	chomp;
	$cmd[$pos]=$_;
	if ($name eq "map") {
	    # since we care about the record separator being output always
	    # correctly, we filter the output ourselves:
	    my $s= Chj::IO::Command->new_sender(@cmd);
	    $cmd[$pos]=undef; $_=undef; # save memory.
	    my $out= $s->xcontentref;
	    $s->xxfinish;
	    chomp $$out;
	    print $$out,$recordsep
	      or die "$myname: error writing to stdout: $!\n";
	} else { # filter
	    my $rv= xsystem(@cmd);
	    if ($rv==0) {
		print $_,$recordsep
		  or die "$myname: error writing to stdout: $!\n";
	    }
	}
    }

}
#use Chj::ruse;use Chj::Backtrace; use Chj::repl; repl;

1
