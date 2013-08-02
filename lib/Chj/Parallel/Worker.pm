#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parallel::Worker

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel::Worker;

use strict;
use Chj::Transmittable;
use Chj::Parallel::Done;
use Data::Dumper;
#use Chj::IO::File;

use Chj::Struct ["jobrecvfd",
		 "jobrecv_lockfd",
		 "jobdonemasterfd", # to send the result as a Done object
		 "jobdoneproxyfd", # to send empty Done object (just the job id)
		 "proxydir",
		 "jobdonemaster_w_lockfd",
		 "jobdoneproxy_w_lockfd",
		 "filehandles", # array of fhs
		];

sub loop {
    my $s=shift;
    my $pid= $$;
    while (my $job= xlockreceive ($$s{jobrecvfd},
				  $$s{jobrecv_lockfd})) {
	# job needs a 'run' and an 'id' method.
	my $id= $job->id;

	my $pathbase= "$$s{proxydir}/$id:";
	my $fhs= $$s{filehandles};
	for (my $i=0; $i< @$fhs; $i++) {
	    my $p= $pathbase.$i;
	    open $$fhs[$i], ">>", $p
	      or die "open >> '$p': $!";
	}

	my $doneresult= do {
	    my $res;
	    if (eval {
		$res= $job->run;
		1
	    }) {
		Chj::Parallel::DoneWithResult->new_(id=> $id,
						    result=> $res,
						    pid=> $pid)
	    }  else {
		my $e= $@;
		Chj::Parallel::DoneWithException->new_(id=> $id,
						       e=> $e,
						       pid=> $pid)
	    }
	};
	my $done= Chj::Parallel::Done->new_(id=> $job->id);
	if (not ($job->noreturn)
	    or $doneresult->is_exception) {
	    xlocktransmit ($doneresult,
			   $$s{jobdonemasterfd},
			   $$s{jobdonemaster_w_lockfd});
	}

	# 2 reasons to only flush, not close:
	# 1) errors when sending are recorded, too
	# 2) only way to be safe(?) for reopening STDERR/STDOUT on same fd?
	# XX Bad though: holding on to file until getting new message.
	for my $fh (@$fhs) {
	    $fh->flush or die "flush $fh: $!";
	}

	xlocktransmit ($done,
		       $$s{jobdoneproxyfd},
		       $$s{jobdoneproxy_w_lockfd});
    }
}

_END_
