# is interface xxx up?
# cj Sat Aug  4 02:29:09 CEST 2001

# Wed, 26 Jun 2002 02:33:50 +0200
# - wenn in keine inet addr stadium bei dhcp: sollte kein ERROR ausgeben! Sondern? -> done, nur bei warnings.
# - pppon: is_if_up: ppp0: error fetching interface information: Device not found -> done.

# Mon, 26 May 2003 06:39:28 +0200:
# correct this:
# is_if_up: no match for 'inet addr' in interface output:
# eth0:1    Link encap:Ethernet  HWaddr 00:B0:D0:F9:12:E7  
#           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1




my $ifconfig= "/sbin/ifconfig";

sub extractfromone {
    my ($a)=@_; # string from ifconfig of one interface
    if ($a=~ /^\s+UP\s/m) {
	if ($a=~ /inet addr:(\d+\.\d+\.\d+\.\d+)\s+/) {
	    return $1
	} else {
	    if (defined $if   # prevent undef warnings in 'vserver case'
		 and
		 $if=~ /^(\w+)\:\d+\z/s) {
		# sub-interface.
		my $mainif= is_if_up($1);
		if ($mainif) {
		    return ""
		}
	    }
	    #warn "is_if_up: no match for 'inet addr' in interface output:\n$a\n"
	    #  if $^W;
	    #return undef
	    # 13.4.04: ach was soll das obige.
	    die "is_if_up: no match for 'inet addr' in interface output:\n$a\n";
	}
    } else {
	return ""
    }
}


sub is_if_up {
    my $flag_listmode;
    my $if= shift or wantarray ? $flag_listmode=1 : die "is_if_up: missing interface argument (like eth0 or eth1:1)";
    local $ENV{LANG}="C";
    pipe is_if_up_RH,is_if_up_WH;# be careful about polluting the foreign namespace
    my $pid=fork; die "is_if_up: could not fork" unless defined $pid;
    if ($pid) {
        close is_if_up_WH;
        local $/=undef;
        my $a= <is_if_up_RH>;
        close is_if_up_RH;
        wait;
        if ($?) {
            warn "is_if_up: $a" unless $a=~ /device not found/i;## 13.4.04: todo auch dieses noch in ne exception umwandeln, oder nicht?
            return undef; # probably "interface not found"; $? should still be readable outside
        }
	if ($flag_listmode) {
	    # make list of arrayrefs:  [ "eth0", "..ip.." ], ...
	    return map {
		/^(\S+)/ or die "???: $_";
		my $iface=$1;
		my $ip= extractfromone $_;
		[ $iface,$ip ]
	    } split /\n{2,}/, $a
	} else {
	    return extractfromone $a
	}
    } else {
        close is_if_up_RH;
        open STDOUT, ">&is_if_up_WH" or die;
        open STDERR, ">&is_if_up_WH" or die;
        $flag_listmode ? exec $ifconfig : exec $ifconfig, $if;
        die "could not execute $ifconfig";
    }
}

1;
__END__
# test:
my $if=shift;
#print is_if_up($if) ? "oben" : "unten";
my $ret=is_if_up($if);
if (defined $ret) { print $ret ? "oben" : "unten"; }
else { print "gibt es nicht" }
print "\n";

See also is_if_up script.

  Sun, 10 Aug 2003 21:09:00 +0200
  TODO::  !!:  (für publicip) welches interface nehmen: einfach das wo das default gateway geht \drauf.
