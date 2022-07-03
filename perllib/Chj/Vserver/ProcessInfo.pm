# Sat Sep  3 21:18:46 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vserver::ProcessInfo

=head1 SYNOPSIS

 use Chj::Vserver::ProcessInfo;
 my $p= new_of_pid Chj::Vserver::ProcessInfo 1234;
 for my $r ($p->ipv4roots) { # returns Chj::Net::IpMask objects
     print "ip: ".$r->ip.", mask: ".$r->mask."\n";
 }

=head1 DESCRIPTION

=head1 SEE ALSO

Chj::System::Processes for looping over processtable

=cut


package Chj::Vserver::ProcessInfo;
use strict;
use Chj::xopen ();
use Carp;
use Chj::Net::IpMask;

use Class::Array -fields=>
  -publica=>
  "pid",
  "status", # whole file as string
  #"ipv4root",
  "status_field", # hash
  ;


sub new_of_pid {
    my $class=shift;
    @_==1 or croak "new_of_pid expects 1 argument";
    my $s= $class->SUPER::new;
    ($$s[Pid])=@_;
    $s
}

sub xget_status {
    my $s=shift;
    return if $$s[Status];
    $$s[Status]= Chj::xopen::xopen_read("/proc/$$s[Pid]/status")->xcontent;
}

sub xparse {
    my $s=shift;
    $s->xget_status;
    #$$s[Status]=~
    #/^ipv4root
#    while ($$s[Status]=~ /(.*)/mg) {
#	my $line=$1;
#    while (my ($line)= $$s[Status]=~ /\G(.*)/mg) {
#    while (my ($line)= $$s[Status]=~ /([^\n]+)/g) {
    while ($$s[Status]=~ /([^\n]+)/g) {# ENDLICH damit gehts. my muss raus auch noch.krgrck
	my ($line)= $1;
	#warn "line='$line'";
	$line=~ /^(\w+):\s*(.*)/ or die "invalid format of Status file line: '$line'";
	$$s[Status_field]{$1}=$2;
    }
}


sub ipv4roots {
    my $s=shift;
    $s->xparse;
    my $str= $$s[Status_field]{ipv4root};
    if ($str=~ /^\s*0\s*\z/s) {
	()
    } else {
	my @entries= split /\s+/, $str;
	map {
	    Chj::Net::IpMask->new_nethex(split '/',$_)
	  } @entries;
    }
}

end Class::Array;
