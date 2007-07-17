# Sun Oct 16 16:07:49 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# -16:50
#
# Copyright 2005 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::userfullname

=head1 SYNOPSIS

=head1 DESCRIPTION


Giving false means, return false in the respective case. Giving a code ref means,
call that one with the username or uid as argument.

If the user is only giving the first of those two, it is valid for the second as well.


=cut


package Chj::userfullname;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(userfullname);

use strict;
use Carp;
use Chj::chompspace;

sub userfullname {
    my ($uid,$replacement_nofullname,$replacement_notexist);
    my $dflt_replacement_nofullname= sub { shift };#(nun doch nicht mehr für eq gebraucht. nun stehts halt hier für nix.)
    if (@_>3) {
	croak "userfullname: expecting 0 to 3 arguments, got ".@_;
    } else {
	if (@_>=1) {
	    $uid=$_[0];
	} else {
	    $uid= $<; #real, not effective uid. der verursacher einer handlung.
	}
	if (@_>=2) {
	    $replacement_nofullname=$_[1];
	} else {
	    $replacement_nofullname= $dflt_replacement_nofullname;
	}
	if (@_>=3) {
	    $replacement_notexist= $_[2];
	} else {
	    #if (!defined $replacement_nofullname) {
	    #  # leave $replacement_notexist undef as well
	    #} else {
	    if (@_==2) {
		$replacement_notexist= $replacement_nofullname
	    } else {
		$replacement_notexist= sub {
		    my $uid=shift;
		    "(unknown user id $uid)";
		};
	    }
	}
    }
    if (my @e= getpwuid($uid)) {
	my $gcos=$e[6];
	$gcos=~ s/,.*//s; # there seems to be no way quoting commas? *
	$gcos= Chj::chompspace($gcos);
	if (length $gcos) {
	    $gcos
	} else {
	    #Invoke($replacement_nofullname)
	    if ($replacement_nofullname) {
		$replacement_nofullname->($e[0])
	    } else {
		return
	    }
	}
    } else {
	if ($replacement_notexist) {
	    $replacement_notexist->($uid)
	} else {
	    return
	}
    }
}
# well dann gibts noch den Fall der system accounts wo der fullname auf username gesetzt wird von Debian. Ob man das evtl. erkennen müsste. ..

1


__END__

* interesting bits on linux:

chris@lombi chris > chfn  -f Chrigu
chfn: Permission denied.

root@lombi root# chfn -f 'Chrigu,' chris
chfn: invalid name: "Chrigu,"
root@lombi root# chfn -f 'Chrigu\,' chris
chfn: invalid name: "Chrigu\,"
root@lombi root# chfn -f 'Chrigu,,' chris
chfn: invalid name: "Chrigu,,"

"	## hmm auch dann replacementtext wenn gcos userfullname feld leer ist ? (as opposed to uid existiert nicht)
"

"Special strings '.. $username ..', '.. $uid ..', and 'die [..]' are recognized.

Well chrank? besser sub geben.
"
