#!/usr/bin/perl -w

# Sam Apr 18 14:13:16 CEST 2015
(my $email='XXX%YYY,ch')=~ tr/%,/@./;

use strict; use warnings FATAL => 'uninitialized';

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);
sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname

  Show battery status.

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

use Getopt::Long;
our $verbose=0;
#our $opt_dry;
GetOptions("verbose"=> \$verbose,
	   "help"=> sub{usage},
	   #"dry-run"=> \$opt_dry,
	   ) or exit 1;
usage if @ARGV;


# XX move?
sub xset_once ($$$) {
    my ($table,$keys,$val)=@_;
    if (@$keys==1) {
	exists $$table{$$keys[0]} ? die "key already set"
	  : ($$table{$$keys[0]}= $val);
    } elsif (@$keys==2) {
	exists $$table{$$keys[0]}{$$keys[1]} ? die "key already set"
	  : ($$table{$$keys[0]}{$$keys[1]}= $val);
    } elsif (@$keys==2) {
	exists $$table{$$keys[0]}{$$keys[1]}{$$keys[2]} ? die "key already set"
	  : ($$table{$$keys[0]}{$$keys[1]}{$$keys[2]}= $val);
    } else {
	die "don't know how to handle more than 3 keys at this time"
    }
}


use Chj::xopendir;

our $power_base = "/sys/class/power_supply";

our $by_prefix={};
{
    my $d= xopendir $power_base;
    while (defined (my $item= $d->xnread)) {
	my ($pref,$perhaps_num)= $item=~ /^(.+?)(\d*)\z/
	  or die "no match: '$item'";
	xset_once $by_prefix, [$pref, $perhaps_num],
	  "$power_base/$item"; #spend some space..
    }
}

for (keys %$by_prefix) {
    $_ eq "AC" or $_ eq "BAT" or die "unknown type '$_'";
}

use Chj::xopen 'xopen_read';
sub contents ($) {
    my ($path)=@_;
    my $f= xopen_read $path;
    my $cntref= $f->xcontentref;
    $f->xclose;
    chomp $$cntref;
    $$cntref
}

sub show {
    my ($kind,$num)=@_;
    my $path= $$by_prefix{$kind}{$num}
      or die "BUG";
    my $field= sub {
	my ($name)=@_;
	contents("$path/$name");
    };
    print "$kind$num:\n";
    print " type: ", &$field("type"), "\n";
    if ($kind eq "AC") {
	print " online: ", &$field("online"), "\n";
    } elsif ($kind eq "BAT") {
	my $now= &$field("energy_now");
	my $full= &$field("energy_full");
	printf " charge: %3.1f\n", 100 * $now / $full;
    } else {
	die "bug"
    }
    print "\n";
}


sub pseudonumify {
    my ($v)=@_;
    length $v ? $v : -1
}

for my $kind (sort { $a cmp $b } keys %$by_prefix) {
    my $h= $$by_prefix{$kind};
    for my $num (sort { pseudonumify($a) <=> pseudonumify($b) } keys %$h) {
	show $kind, $num;
    }
}
	


#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;
