# Mon Oct 22 18:06:52 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::Upsync

=head1 SYNOPSIS

(should rather be called ::UpsyncCommands; used by upsync script)

=head1 DESCRIPTION

This class does not have a super class. It is a mixin. (It doesn't
define own fields not only because it hopefully will not need them,
but because it can't (with my current class array implementation).)

(Delegation would be an alternative: ?)

=cut


package Chj::Unix::ShellRPC::Upsync;

use strict;
use Chj::Random::Formatted;
use Chj::xopen ();
use Chj::Unix::ShellRPC::Functions ':all';
use Chj::singlequote ':all';

sub Randomname {
    ".tmp-".NewMarker
}

sub upload_file_fh { # upload_file_by_fh  or through_fh or ?.
    @_==3 or @_==4 or die "wrong number of arguments";#grrrrrr ich depp. soweit bin ich schon  dass ich darauf nimmeracht.(vergass remotepath immer  und wunder mich)
    my ($s, $inputfh, $remotepath, $maybe_stat)=@_;
    my $remotetmp= $remotepath.Randomname;
    my $marker= NewMarker();#grr needs parens because it's not imported at compiletime.
    CheckSuccessAndEmptyness
      ($s->remote_run_commandstring_with_statusreply
       (q/perl -w -MChj::xperlfunc=xmkdir_p,dirname -e 'my ($end,$targetpath)= @ARGV; $end.="\n"; eval { xmkdir_p(dirname($targetpath)); open STDOUT, ">", $targetpath or die "opening ``$targetpath``: $!"; my $prevline=""; while(<STDIN>) { if ($_ eq $end) { $seenend++; chop $prevline; print $prevline or die $!; close STDOUT or die $!; exit } print $prevline or die $!; $prevline= $_ } exit 2}; print STDERR $@; unless($seenend) { while(<STDIN>) { if ($_ eq $end) { last }}} exit 3' /
	.singlequote_sh($marker)
	.q/ /
	.singlequote_sh($remotetmp),
	sub {
	    my ($fh)=@_;
	    $fh->xflush;#see below
	    $inputfh->xsendfile_to($fh);  # 'depends on xsendfile_to *not* being the lowlevel linux call. (or at least it doing flushing of perl buffers first)'---d'oh, it *is* lowlevel, even the perl implementation of it (using sysread/-write), thus the xflush above now.
	    $fh->xprint("\n".$marker."\n");
	}));
    # permissions: (ignore user and group   ?  hm?  TODO could even be dangerous with this!)
    if (defined(my $stat= $maybe_stat)) {
	#my $cmd= "chmod 0".sprintf('%o', $stat->permissions);#richtige knallköpfe
	my $cmd= ("chmod 0".sprintf('%o', $stat->permissions)
		  ." "
		  .singlequote_sh ($remotetmp));
	CheckSuccessAndEmptyness
	  ($s->remote_run_commandstring_with_statusreply
	   ($cmd));
    }
    my $cmd= $shellquoted->("/bin/mv", "--", $remotetmp, $remotepath);
    #warn "cmd=".singlequote($cmd);
    CheckSuccessAndEmptyness
      ($s->remote_run_commandstring_with_statusreply
       ($cmd));
}

sub upload_file_path {
    @_==3 or die "wrong number of arguments";#grrrrrr HIER muss es sein,ja
    my ($s, $sourcepath, $remotepath)=@_;
    $s->upload_file_fh(Chj::xopen::xopen_read($sourcepath), $remotepath);
}
#((praktisch, wie exceptions überall jeweils abbrechen automaticaly.))

use Chj::xperlfunc ();
sub upload_file_path_with_permissions {
    @_==3 or die "wrong number of arguments";#grrrrrr HIER muss es sein,ja
    my ($s, $sourcepath, $remotepath)=@_;
    $s->upload_file_fh(Chj::xopen::xopen_read($sourcepath),
		       $remotepath,
		       scalar Chj::xperlfunc::xstat($sourcepath), # NOT xlstat, right? ah YEAHYEAHYEAH once more don't forget scalar.
		      );
}


sub remote_unlink {
    @_==2 or die "wrong number of arguments";
    my ($s,$remotepath)=@_;
    my $cmd= $shellquoted->("/bin/rm","--",$remotepath);
    CheckSuccessAndEmptyness
      ($s->remote_run_commandstring_with_statusreply
       ($cmd));
}

sub remote_md5sum {
    @_==2 or die "wrong number of arguments";
    my ($s,$remotepath)=@_;
    my $cmd= $shellquoted->("md5sum","--",$remotepath);
    my $res= CheckSuccessJoin
      ($s->remote_run_commandstring_with_statusreply
       ($cmd));
    $res=~ /^([a-z0-9]{32}) +/ or die "invalid reply from md5sum: ".singlequote($res);
    $1
}

1


__END__
Why are 128 bits (16 bytes) of randomness enough?

calc> 2**(16*8)
3.40282366920938e+38 possibilities
calc> $res/2e9
1.70141183460469e+29 seconds of cycles of a todays machine. (one cycle per possibility)
calc> $res/(60*60*24*365)
5.39514153540301e+21 years
  well.
calc> $res/6.6e9
817445687182.274 years if every human on the earth owns a computer and participates in the calculation.
calc> $res/1000
817445687.182274 years if in 20 years every computer is 1000 times as powerful.
well anyway.

  NOTES:
- uglyness that errors aren't really propagated in exceptions? shoudl I trap stderr?
(or should I write a complete server process (script in perl).)


