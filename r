#!/usr/bin/perl -w

# Sat Sep 17 11:56:26 EDT 2011
(my $email='XXX%YYY,ch')=~ tr/%,/@./;

use strict;

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);
sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname cmd args..

  removes files ending in ~ if the same file is given without ~ too.
  (i.e. remove backup files added by shell patterns)

  e.g.
    r _e *foo*

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

our $debug=$ENV{DEBUG_R};
sub debug {
    print STDERR "@_\n" if $debug;
}

@ARGV or usage;
our $cmd= shift @ARGV;
usage if $cmd eq "-h" or $cmd eq "--help"; # disables usage of those as cmd.


# which arguments ending in ~ are given without ~?

# stat all args, need to do it anyway to know which ones to index as
# truncs (below)

our %existingargs=
  map {
      if (lstat $_) {
	  $_ => 1
      } else {
	  ()
      }
  } @ARGV;

# are there other 'basenames'?  Even suppress tildefiles if another
# tildefile matches: case of backup files of file that then has been
# renamed. E.g. foo~ foo-bar~ foo-bar => foo-bar ; thus, build index
# of truncs to match.

sub maybe_trunc ( $ ) {
    my ($str)=@_;
    # scratch files
    if ($str=~ /^\(?(\w{26,27})[-\)~]/) {
	$1
    } else {
	undef
    }
}

our %truncatedargs=
  map {
      if (defined (my $trunc= maybe_trunc $_)) {
	  ($trunc => 1)
      } else {
	  ()
      }
  } keys %existingargs;

# (which arguments should be removed?)

our @tildefiles= grep { /.~\z/s } keys %existingargs;

our %suppresstilde=
  (map {
      /^(.+)~$/s or die "??";
      my $k=$_;
      my $tildeless=$1;
      $k=> do {
	  if ($existingargs{$tildeless}) {
	      debug "FOUND existingfile arg '$tildeless', so yep suppress '$k'";
	      1
	  } else {
	      debug "nonexisting arg '$k'";
	      if (defined (my $trunc= maybe_trunc $k)) {
		  debug "examine '$trunc'";
		  if ($truncatedargs{$trunc}) {
		      debug "FOUND trunc '$trunc', so yep suppress '$k'";
		      1
		  } else {
		      0
		  }
	      } else {
		  0
	      }
	  }
      }
  } @tildefiles);


our @fixedargs=
  grep {
      not $suppresstilde{$_}
  } @ARGV;

#use Chj::singlequote ':all';
#print singlequote_many(@fixedargs)."\n";

exec ($cmd, @fixedargs)
  or exit 127; # did I remember the correct code ?

#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;
