# Sat Sep  3 22:29:56 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::System::Processes

=head1 SYNOPSIS

 use Chj::System::Processes;

 for (Chj::System::Processes->pids) { ... } # [sorted as in processtable]

 for (Chj::System::Processes->sorted_pids) { ... } # numerically sorted

 my $s= Chj::System::Processes->new;
 $s->start;
 while (defined (my $pid=$s->next_pid)) {... }

 my $s= Chj::System::Processes->new;
 $s->set_callback(sub{my $pid=shift; print "pid=$pid\n"});
 $s->run;

=head1 DESCRIPTION

Currently only supports linux, might be improved to support other sys'es as well.

=cut


package Chj::System::Processes;
use strict;
use Chj::xopendir();

use Class::Array -fields=>
  -publica=>
  'dirhandle',
  'callback', # subref to call when called run
  ;


sub start {
    my $s=shift;
    $$s[Dirhandle]= Chj::xopendir::xopendir("/proc");
}

sub next_pid {
    my $s=shift;
    $$s[Dirhandle] or return;
  REDO: {
	if (defined (my $item= $$s[Dirhandle]->xnread)) {
	    if ($item=~ /^(\d+)\z/) {
		return $1
	    } else {
		redo REDO;
	    }
	} else {
	    undef $$s[Dirhandle];
	    return
	}
    }
}

sub pids {
    #my $s=shift;
    my $d= Chj::xopendir::xopendir("/proc");
      grep {
	  defined $_
      } map {
	  /^(\d+)\z/ ? $1 : undef
      } $d->xnread;
}

sub sorted_pids {
    my $s=shift;
    sort { $a <=> $b } # <=> allein geben ist nicht
      $s->pids;
}

sub run {
    my $s=shift;
    $s->start;
    while (defined(my $pid=$s->next_pid)) {
	$$s[Callback]->($pid)
    }
}

end Class::Array;
