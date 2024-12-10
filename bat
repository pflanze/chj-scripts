#!/usr/bin/perl -w

# Sam Apr 18 14:13:16 CEST 2015
(my $email='XXX%YYY,ch')=~ tr/%,/@./;

use strict; use warnings FATAL => 'uninitialized';

our $loopsleep= 10; # seconds

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);
sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname

  Show battery status.

  Options:

   -l|--loop   show BAT0 percentage oneline with timestamp

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

use Getopt::Long;
our $verbose=0;
our $opt_loop;
GetOptions("verbose"=> \$verbose,
	   "help"=> sub{usage},
	   "loop"=> \$opt_loop,
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

use Chj::xopen 'xopen_read';
sub contents ($) {
    my ($path)=@_;
    my $f= xopen_read $path;
    my $cntref= $f->xcontentref;
    $f->xclose;
    chomp $$cntref;
    $$cntref
}

sub pseudonumify {
    my ($v)=@_;
    length $v ? $v : -1
}

# /move


use Chj::xopendir;

our $power_base = "/sys/class/power_supply";

sub hardware_by_prefixes {
    my $by_prefix={};
    my $d= xopendir $power_base;
    while (defined (my $item= $d->xnread)) {
	my ($pref,$perhaps_num)= $item=~ /^(.+?)(\d*)\z/
	  or die "no match: '$item'";
	xset_once $by_prefix, [$pref, $perhaps_num],
	  "$power_base/$item"; #spend some space..
    }
    for (keys %$by_prefix) {
	$_ eq "AC" or $_ eq "BAT" or /USBC/
            or die "unknown type '$_'";
    }
    $by_prefix
}


our $by_prefix;

sub show_bat_percentage {
    my ($prefix,$field)=@_;
    my $now= &$field("energy_now");
    my $full= &$field("energy_full");
    printf "$prefix%3.1f\n", 100 * $now / $full;
}

sub kindnum2field {
    my ($kind,$num)=@_;
    my $path= $$by_prefix{$kind}{$num}
      or die "do not have a $kind$num";
    sub {
	my ($name)=@_;

	# So they decided to rename this file, sigh:
	if ($name=~ /^energy_/) {
	    if (! -e "$path/$name") {
		$name=~ s/^energy/charge/;
	    }
	}

	contents("$path/$name");
    }
}

sub show {
    my ($kind,$num)=@_;
    print "$kind$num:\n";
    my $field= kindnum2field ($kind,$num);
    print " type: ", $field->("type"), "\n";
    if ($kind eq "AC") {
	print " online: ", $field->("online"), "\n";
    } elsif ($kind eq "BAT") {
	show_bat_percentage(" charge: ",$field);
    } elsif ($kind =~ /USBC/) {
	print " online: ", $field->("online"), "\n";
    } else {
	die "bug"
    }
    print "\n";
}


$by_prefix= hardware_by_prefixes;

if ($opt_loop) {
    $|=1;
    my $lasthw= time;
    my $rescan= sub {
	my ($maybe_t)=@_;
	my $t= $maybe_t || time;
	# (could optimize _full file similarly.)
	$lasthw= $t;
	$by_prefix= hardware_by_prefixes;
    };
    while (1) {
	eval {
	    my $t= time;
	    if ($t > ($lasthw + $loopsleep * 10)) {
		&$rescan ($t);
	    }
	    my $field= kindnum2field ("BAT","0");
	    show_bat_percentage (localtime."\t", $field);
	    1
	} || do {
	    print STDERR "note: $@";
	    &$rescan;
	};
	sleep $loopsleep;
    }
} else {
    for my $kind (sort { $a cmp $b } keys %$by_prefix) {
	my $h= $$by_prefix{$kind};
	for my $num (sort { pseudonumify($a) <=> pseudonumify($b) } keys %$h) {
	    show $kind, $num;
	}
    }
}



#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;
