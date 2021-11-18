#!/usr/bin/perl -w

# Mon Jan  3 10:34:15 MET 2005
(my $email='XXX%YYY,ch')=~ tr/%,/@./;

use strict;
#use Chj::xopen qw(xopen_append);
#my $logpath= "/tmp/$ENV{USER}/ls.log";
#my $l= xopen_append $logpath;
#$l->xprint("$$ ".localtime()."\n");

our $ls= "/bin/ls";
our @default_args= qw(--quoting-style=literal --color=auto -I *~);

sub parent_process {
    #my $f= xopen_read("/proc/self/status")->xcontent;
    open PP,"</proc/self/status" or die $!;
    local $_;
    my $ppid;
    while(<PP>){
	if (/^PPid:\s*(\d+)/) {
	    $ppid=$1;
	    last;
	}
    }
    close PP or die $!;
    defined $ppid or die "didn't find PPid in /proc/self/status";
    $ppid
}

sub process_name {
    my ($pid)=@_;
    open PP,"</proc/$pid/status" or die $!;
    local $_;
    my $v;
    while(<PP>){
	if (/^Name:\s*(.*)/) {
	    $v=$1;
	    last;
	}
    }
    close PP or die $!;
    defined $v or die "didn't find entry in proc file";
    $v
}

my $ppname= process_name parent_process;

if ($ppname=~ /emacs/) {
    $ENV{LANG}="C";
    my @args=
      map{
	  if (/^-.*l/ and /t/ and not /r/) {
	      $_."r"
	  } else {
	      $_
	  }
      }
	@ARGV;
    exec $ls, @default_args, @args or exit 1;
}
else {
    exec $ls, @default_args, @ARGV or exit 1;
}
