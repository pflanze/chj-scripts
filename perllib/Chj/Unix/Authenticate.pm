# Thu Mar  8 13:42:19 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Authenticate

=head1 SYNOPSIS

=head1 DESCRIPTION

Uses the same interface as Authen::Simple::PAM, but works; requires to
be run as root, though, and only works for md5 and /etc/shadow based
systems.

=head1 BUGS / WARNING!

 - there is no test suite!
 - prone to race conditions (on user/password changes while running)
   (but not really worse than any other way to check the user db, right?)

=head1 SEE ALSO

L<Chj::Unix::Object::Shadowentry>

=cut


# I did look at http://www.virusexperts.com/xbi/programming/md5-crypt
# The rest of the fields deal with password aging and expiry. "Hmmmmmm"

# http://www.tldp.org/LDP/lame/LAME/linux-admin-made-easy/shadow-file-formats.html

# man 5 shadow


package Chj::Unix::Authenticate;

use strict;

use Crypt::PasswdMD5;
use Chj::Unix::Object::User;
use Chj::Unix::Object::Shadowentry;

use Class::Array -fields=>
  -publica=>
  ;


sub new {
    my $class=shift;
    @_ % 2 == 0 or die "expecting even argument count";
    my $param= { @_ };

    keys( %$param )==1 or die "unknown arguments";
    my ($firstkey)= keys (%$param);
    $firstkey eq "service" or die "unknown argument '$firstkey'";
    $$param{service} eq "login" or die "only service=>'login' is supported, given '$$param{service}'";

    my $s= $class->SUPER::new;
    #(@$s[])=@_;
    $s
}

our $warn= sub {
    print STDERR __PACKAGE__,": ",@_,"\n";
};

sub authenticate {
    my $s=shift;
    @_==2 or die "expecting user,password";
    my ($user,$password)=@_;
    if (my $u= Chj::Unix::Object::User->get_by_nam($user)) {
	if (my $shad= $u->passwd) {
	    my $substr= substr $shad,0,1;
	    my $longsubstr= substr ($shad,0,3);
	    if ($substr eq "x") {
		die "got 'x' entry (probably from /etc/passwd, not /etc/shadow? - must be running as root, \$>=$>)"
	    } elsif ($substr eq "!" or $substr eq "*") {
		$warn->("no/suspended password: '$substr\[..\]'");
		return undef;
	    } elsif ($longsubstr eq '$1$') {
		my $salt= substr $shad,3,8;
		substr ($shad,3+8,1) eq '$' or die "expected '$' after the salt";
		#my $hash= substr $shad,3+8+1;
		my $cryptedpassword = unix_md5_crypt($password, $salt);
		if ($cryptedpassword eq $shad) {
		    #$u->set_passwd(undef); # does it make sense? no
		    # still definitely depend on /etc/shadow...:
		    my $shadowentry= Chj::Unix::Object::Shadowentry->get_by_nam ($user)
		      or die "missing shadowentry for user '$user'";
		    $shadowentry->passwd eq $shad or die "unequal shadow entries"; ##well, prone to race conditions, of course! (but that is true anyway for user checks!!) (does PAM use locks?)
		    if ($shadowentry->is_expired) {
			$warn->("password expired");
			return 0
		    } else {
			return $u
		    }
		} else {
		    $warn->("invalid password");
		    return 0
		}
	    } else {
		die "unknown shadow entry format (we are only supporting md5 hashes!) : '$substr\[..\]'";
	    }
	} else {
	    $warn->("??no password");
	    return undef
	}
    } else {
	$warn->("unknown user");
	return
    }
}

end Class::Array;
