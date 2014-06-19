#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Parallel::Worker

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel::Worker;

use strict; use warnings FATAL => 'uninitialized';
use Chj::Transmittable;
use Chj::Parallel::Done;
use Data::Dumper;
use POSIX qw(O_CREAT O_EXCL O_APPEND O_WRONLY);


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
	    my $path= $pathbase.$i;
	    my $fh= $$fhs[$i];
	    # use POSIX instead of Perl procedures so as to keep
	    # PerlIO settings unchanged. XX how to improve
	    # portability? (But then porting Chj::Parallel may be
	    # difficult anyway since we're using pipes?)
	    my $fd= POSIX::open($path, O_CREAT|O_EXCL|O_APPEND|O_WRONLY, 0600)
	      or die "open >> '$path': $!";
	    POSIX::dup2($fd,fileno($fh))
		or die "dup2($fd,".fileno($fh)."): $!";
	    POSIX::close $fd or die "close($fd): $!";
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
