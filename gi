#!/usr/bin/perl -w

# Fri 15 Nov 14:00:07 GMT 2019
(my $email='ch%christianjaeger,ch')=~ tr/%,/@./;

use strict; use warnings FATAL => 'uninitialized';

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);
sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname [-i] name-regex...

  Find items in the current Git repository, including parent directory
  paths of them, whose name matches the given regex(es/en).

  (Wrapper around gfind, see docs there.)

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

use Getopt::Long;
our $verbose=0;
my $opt_i;
#our $opt_dry;
GetOptions("verbose"=> \$verbose,
	   "help"=> sub{usage},
           "i"=> \$opt_i,
	   #"dry-run"=> \$opt_dry,
	   ) or exit 1;
usage unless @ARGV;

exec "gfind", ($opt_i ? "-i" : ()), map { ("--name", $_) } @ARGV;

