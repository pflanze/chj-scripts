#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parallel::Instance

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parallel::Instance;

use strict;

use Chj::FP2::Lazy;
use Scalar::Util 'weaken';
use Chj::FP2::List ":all";
use Chj::Transmittable;
use Chj::Parallel::Job; # ::JobNoreturn;
use Chj::PClosure;
use Chj::Parallel::Alldone;


sub Chj::Parallel::Instance_::batch_for_each {
    my ($pclosure,$pos,$batch)=@_;
    $pclosure->call($_,$pos++) for @$batch;
}

# XX move to some lib
sub input_available {
    my ($fh,$maybe_timeout)=@_;
    if (@_==1) {
	$maybe_timeout=0
    }
    # i.e. not eof
    my $bits='';
    my $fileno= fileno($fh);
    vec ($bits, $fileno, 1) = 1;
    my $outbits=$bits;
    select ($outbits,undef,$outbits,$maybe_timeout);
    vec ($outbits, $fileno, 1)
}

use Chj::Struct [
		 "proxypid",
		 "workerpids",
		 "job_enqueue_fd",
		 "donemaster_r_fd",
		 "doneproxy_w", # for the Alldone feature
		 "doneproxy_w_lock", # dito
		 "suppress_exceptions", # 1 = show them to stderr, 2 = ignore completely
		 # ^ XX: bad feature as if used with batchsize>1, it
		 # will lead to some work not being done.
		 "jobid", # counter
		];

sub next_jobid {
    my $s=shift;
    $$s{jobid}||=0;
    $$s{jobid}++
}

sub stream_for_each {
    my $self=shift;
    @_==3 or @_==2 or die;
    my ($pclosure, $s, $maybe_batchsize)=@_;
    # $pclosure: Chj::Parallel::Closure object or anything else with a
    # call method that takes the input to be worked on as an argument
    weaken $_[1];
    my $batchsize= $maybe_batchsize||1;

    my $pos=0;
  LP: {
	my $i=1;
	my @batch;
	my $batchstartpos= $pos;
      LP2: {
	    $s= Force $s;
	    if (defined $s) {
		push @batch, car $s;
		$s= cdr $s; $pos++;
		if ($i < $batchsize) {
		    $i++;
		    redo LP2;
		}
	    }

	    xtransmit
	      (Chj::Parallel::JobNoreturn->new_
	       (id=> $self->next_jobid,
		pclosure=> PClosure(*Chj::Parallel::Instance_::batch_for_each,
				    $pclosure),
		vals=> [$batchstartpos,\@batch]),
	       $$self{job_enqueue_fd});

	    # check for eventual exceptions
	  CHECKEXN: {
		if (input_available $$self{donemaster_r_fd}) {
		    my $msg= xreceive $$self{donemaster_r_fd};
		    if (UNIVERSAL::isa($msg, "Chj::Parallel::DoneWithException")) {
			# COPYPASTE below
			if ($$self{suppress_exceptions}) {
			    warn "ignoring exn: ".($msg->e)
			      unless $$self{suppress_exceptions}==2;
			    redo CHECKEXN;
			} else {
			    die $msg->e
			}
		    } else {
			warn "ignoring spurious message: $msg";
			redo CHECKEXN;
		    }
		}
	    }

	    if (defined $s) {
		redo LP;
	    }
	}

	# request notification once last job is done
	xlocktransmit (Chj::Parallel::RequestAlldone->new($self->jobid - 1),
		       $$self{doneproxy_w},
		       $$self{doneproxy_w_lock}
		      );
    }

    # wait for end of last job
  WAITEND: {
	my $msg= xreceive $$self{donemaster_r_fd};
	defined $msg or die "unexpected EOF waiting for finishing";
	if (UNIVERSAL::isa($msg, "Chj::Parallel::DoneWithException")) {
	    # COPYPASTE above
	    if ($$self{suppress_exceptions}) {
		warn "ignoring exn: ".($msg->e)
		  unless $$self{suppress_exceptions}==2;
		redo WAITEND;
	    } else {
		die $msg->e
	    }
	} elsif (UNIVERSAL::isa($msg, "Chj::Parallel::Alldone")) {
	    $msg->id == ($self->jobid - 1) or die "assertion failure";
	    # return.
	} else {
	    warn "ignoring spurious message: $msg";
	    redo WAITEND;
	}
    }

    # return length of stream
    $pos
}

_END_
