# Mon Oct 22 18:06:52 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::Upsync

=head1 SYNOPSIS

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

sub Randomname {
    ".tmp-".Chj::Random::Formatted::random_passwd_string (16);
}
# 'imports':
#require Chj::Unix::ShellRPC::Common;# soooschwach. soviel zu unabhängigem mixin. aber ok eben sollte die funcs aus lagern!tdgrr IMMMER grr.
use Chj::Unix::ShellRPC::Common;
*NewMarker= \&Chj::Unix::ShellRPC::Common::NewMarker;
our $shellquoted= $Chj::Unix::ShellRPC::Common::shellquoted;#yes I'm weird.superconsistnt
*CheckSuccessAndEmptyness= \&Chj::Unix::ShellRPC::Common::CheckSuccessAndEmptyness;#grr.tediaous langsma.

use Chj::singlequote ':all';

sub upload_file_fh { # upload_file_by_fh  or through_fh or ?.
    @_==3 or die "wrong number of arguments";#grrrrrr ich depp. soweit bin ich schon  dass ich darauf nimmeracht.(vergass remotepath immer  und wunder mich)
    my ($s, $inputfh, $remotepath)=@_;
    my $remotetmp= $remotepath.Randomname;
    my $marker= NewMarker();#grr needs parens because it's not imported at compiletime.
    CheckSuccessAndEmptyness
      ($s->remote_run_commandstring_with_statusreply
       (q/perl -wne 'if (defined $lastline) { print $lastline or die $! } $lastline=$_; END { chop $lastline; print $lastline or die $! }' > /.singlequote_sh($remotetmp).q/ << '/
	.$marker.q/'/, # do not forget the singequotes around the marker! (or the shell will interpolate stuff into the contents)
	sub {
	    my ($fh)=@_;
	    $fh->xflush;#see below
	    $inputfh->xsendfile_to($fh);  # 'depends on xsendfile_to *not* being the lowlevel linux call. (or at least it doing flushing of perl buffers first)'---d'oh, it *is* lowlevel, even the perl implementation of it (using sysread/-write), thus the xflush above now.
	    $fh->xprint("\n".$marker."\n");
	}));
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

