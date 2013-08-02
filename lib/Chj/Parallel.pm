#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parallel

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel;

use strict;

use Chj::Parallel::Instance;
use Chj::Parallel::NullInstance;
use Chj::Parallel::Proxy;
use Chj::Parallel::Worker;
use Chj::xperlfunc;
use Chj::xpipe;
use Chj::IO::File;

use Chj::Struct ["nparallel"];

sub instantiate {
    my $s=shift;
    if ($$s{nparallel} > 1) {
	@_==1 or die;
	my ($dir)=@_;
	# fork off proxy and workers
	my ($doneproxy_r,$doneproxy_w)= xpipe;
	my ($donemaster_r,$donemaster_w)= xpipe;
	my ($jobqueue_r,$jobqueue_w)= xpipe;
	if (my $proxypid= xfork) {
	    my $workerpids=
	      [
	       map {
		   if (my $pid= xfork) {
		       $pid
		   } else {
		       $0 .= " [worker]";
		       $doneproxy_r->xclose;
		       $donemaster_r->xclose;
		       $jobqueue_w->xclose;
		       Chj::Parallel::Worker->new_(jobrecvfd=> $jobqueue_r,
						   jobdonemasterfd=> $donemaster_w,
						   jobdoneproxyfd=> $doneproxy_w,
						   proxydir=> $dir )
			   ->loop;
		       exit 0;
		   }
	       } (0..$$s{nparallel}-1)
	      ];
	    # master
	    $doneproxy_r->xclose;
	    $donemaster_w->xclose;
	    $jobqueue_r->xclose;
	    Chj::Parallel::Instance->new_(proxypid=> $proxypid,
					  workerpids=> $workerpids,
					  job_enqueue_fd=> $jobqueue_w,
					  donemaster_r_fd=> $donemaster_r,
					  doneproxy_w=> $doneproxy_w,
					 );
	} else {
	    $0 .= " [proxy]";
	    $_->xclose for ($doneproxy_w, $donemaster_r,
			    $jobqueue_r, $jobqueue_w);
	    Chj::Parallel::Proxy->new_
		(
		 basedir=> $dir,
		 signallingfh=> $doneproxy_r,
		 donemaster_w=> $donemaster_w,
		 outerr=> bless(*STDERR{IO}, "Chj::IO::File"),
		 # ^ REALLY want them separate? later.
		)->loop;
	    exit 0;
	}
    } else {
	Chj::Parallel::NullInstance->new;
    }
}

_END_
