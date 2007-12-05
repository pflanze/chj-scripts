# Wed Dec  5 02:36:34 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::is_if_up

=head1 SYNOPSIS

=head1 DESCRIPTION

Linux only atm. Beware, very old code of mine (moved here from
(non-namespace-prefixed) 'is_if_up').

=cut


package Chj::is_if_up;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(extractfromone is_if_up);# export everything for backwards compatibility
%EXPORT_TAGS=(all=>[@EXPORT]);

use strict;

our $ifconfig= "/sbin/ifconfig";

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
