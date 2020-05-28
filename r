#!/usr/bin/perl -w

# Sat Sep 17 11:56:26 EDT 2011
(my $email='XXX%YYY,ch')=~ tr/%,/@./;

use strict;
use utf8;

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
      utf8::decode($_); # grr.
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

    # XX localized date strings are a pain; or, how to match a
    # unicode "wordy" character?
    if ($str=~ /^\(?([\wäöüéè]{26,27})[-\)~]/) {
	$1
    } else {
	undef
    }
}

use Chj::TEST;
TEST { maybe_trunc '(Fre_Mär_20_184758_CET_2015-secupgrades~' }
'Fre_Mär_20_184758_CET_2015';


# (which arguments should be removed?)

our @tildefiles= grep { /.~\z/s } keys %existingargs;


our %sizes; # sizes to cut down to (in additional to maybe_trunc
            # value) for checking truncatedtildes

sub tilde_trunc {
    my ($path, $do_register)= @_;
    if (defined (my $trunc= maybe_trunc $path)) {
        $trunc
    } else {
        # For files that don't fit maybe_trunc, record the sizes, so
        # that those can be tried separately (don't want to build up
        # a trie):
        my $str= substr $path, 0, -1;
        # sooo ugly
        $sizes{length($str)}++
            if $do_register;
        $str
    }
}

our %truncatedtildes= # mix of maybe_trunc strings and full path except for "~"
    map {
        tilde_trunc($_,1) => 1
    } @tildefiles;

my @sizes= reverse sort keys %sizes;


# Now, go through the non-tilde files and see which ones match a tilde
# one, if it does, mark it here, so we can then ignore those:

my %suppresstilde; # trunc of those ~ files which have a trunc-able
                   # non-~ file

sub tstsetfound { # returns if found
    my ($t)=@_;
    debug "tstsetfound: '$t'";
    if ($truncatedtildes{$t}) {
        debug "  found!";
        $suppresstilde{$t}++;
        1
    } else {
        debug "  not found";
        0
    }
}

for my $k (keys %existingargs) {
    debug  "CHECKING: '$k'";
    next if $k=~ /.~\z/s;
    # non-~ file:
    #my $trunc= tilde_trunc($k."~");  oh  no  no go. have to treat cases differently
    if (defined (my $t= maybe_trunc $k."~")) {
        debug "C: '$t'";
        tstsetfound $t
    } else {
        tstsetfound $k;
        for my $siz (@sizes) {
            tstsetfound(substr $k,0,$siz)
                and last;
        }
    }
}


our @fixedargs=
    grep {
        if (/.~\z/s) {
            my $t= tilde_trunc($_, 0);
            not $suppresstilde{$t}
        } else {
            # always keep
            1
        }
  } @ARGV;

#use Chj::singlequote ':all';
#print singlequote_many(@fixedargs)."\n";


#use lib "/opt/functional-perl/lib"; use FP::Repl::AutoTrap; use FP::Repl; repl;

exec ($cmd, @fixedargs)
  or exit 127; # did I remember the correct code ?

#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;
