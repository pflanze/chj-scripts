#
# Copyright 2017 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Future

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Future;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(future);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::xperlfunc ":all";
use Chj::xpipe;
use Storable qw(store_fd fd_retrieve);


{
    package Future;
    use Storable qw(store_fd fd_retrieve);

    sub result {
	my $s=shift;
	die "wrong anticipation of wantarray"
	  unless ((!wantarray) eq !($$s{wantarray}));
	waitpid $$s{pid}, 0;
	my $res= fd_retrieve($$s{r});
	my ($kind, $val)= @$res;
	if ($kind eq "OK") {
	    if ($$s{wantarray}) {
		@$val
	    } else {
		$val
	    }
	} elsif ($kind eq "EXCEPTION") {
	    die $val
	} else {
	    die "Future result: invalid message: $kind"
	}
    }
}

sub future (&;$) {
    my ($thunk, $wantarray)=@_;
    my ($r,$w)= xpipe;
    if (my $pid= xfork) {
	$w->xclose;
	bless +{
		wantarray=> $wantarray,
		pid=>$pid,
		r=>$r,
	       }, "Future";
    } else {
	$r->xclose;
	eval {
	    my $res= $wantarray ? [ &$thunk() ] : scalar &$thunk();
	    store_fd ["OK", $res ], $w;
	    1
	} || do {
	    store_fd ["EXCEPTION", $@], $w;
	};
	$w->xclose;
	exit 0;
    }
}

1
