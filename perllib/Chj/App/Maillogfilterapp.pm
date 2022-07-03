# Sat May 10 23:20:21 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Maillogfilterapp

=head1 SYNOPSIS

=head1 DESCRIPTION

Implements base for qp-log and qm-log scripts

=cut


package Chj::App::Maillogfilterapp;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(maillogfilterapp);

use strict;

(my $email='pflanze%gmx,ch')=~ tr/%,/@./;

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);

use Getopt::Long;
use Chj::xperlfunc;

my $nfiles=3;

sub maillogfilterapp {
    my ($singlelogquotedstring,
	$multilogglobstring,
	$logpostprocess,
	$maillogfilteroptions)=@_;

    my $usage= sub {
	print STDERR map{"$_\n"} @_ if @_;
	print "$myname

  Options:
  -n|--n-files n   use the n instead of $nfiles newest log files
  -f               follow mode
  -H|--no-hide     do not hide (md5sum) mail adresses
                   (only use with grep or similar)

  (Christian Jaeger <$email>)
";
	exit (@_ ? 1 : 0);
    };

    local our $verbose=0;
    local our $DEBUG=0;
    local our ($opt_f,$opt_nohide);
    GetOptions("verbose"=> \$verbose,
	       "d|debug"=>\$DEBUG,
	       "help"=> sub{&$usage},
	       "f|follow"=> \$opt_f,
	       "n|n-files=i"=> \$nfiles,
	       "H|no-hide"=>\$opt_nohide,
	       ) or exit 1;
    &$usage if @ARGV;

    my $quoted_mydir= quotemeta $mydir;
    # just for the insane case where s.o. installs in a weird location.

    if ($opt_f) {
	xexec
	  (
	   "fasttail $singlelogquotedstring"
	   .($opt_nohide ? ""
	     : "| $quoted_mydir/maillogfilter $maillogfilteroptions")
	   .$logpostprocess);
    } else {
	xexec
	#use Data::Dumper;
	#print Dumper
	  (
	   "myzcat `ls -rt $multilogglobstring|tail -"
	   .$nfiles
	   .'`'
	   .($opt_nohide ? ""
	     : ('|'
		.$quoted_mydir
		.'/maillogfilter'))
	   .$logpostprocess
	   .'|less');
    }

}

1
