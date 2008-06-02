# Sat Oct  8 15:53:09 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mailfrom

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Mailfrom;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(mailfrom mailfromaddress
	      maybe_extend_with_realname
	      maybe_mailrealname
	      maybe_name_from_gcos
	     );

use strict;
use Chj::Fileutil qw(MaybeChompCatfile xChompCatfile);
use Chj::username;

sub maybe_name_from_gcos {
    @_==1 or die "expecting 1 argument";
    my ($username)=@_;
    if (my ($name,$passwd,$uid,$gid,  $quota,$comment,$gcos,$dir,$shell,$expire)
	= getpwnam $username) {
	(split /,/, $gcos)[0]
    } else {
	undef
    }
}

sub maybe_mailrealname {
    my ($maybe_path)=@_;
    $ENV{MAILREALNAME} || do {
	$maybe_path||= "$ENV{HOME}/.mailrealname";
	MaybeChompCatfile $maybe_path;
    } || do {
	#my $user=$ENV{USER} and maybe_name_from_gcos ($user)   nope. it's 'recursive', not cond
	my $user;
	$user=$ENV{USER} and maybe_name_from_gcos ($user)
    }
}

sub maybe_extend_with_realname ( $ ) {
    my ($email,$maybe_realname_path)=@_;
    if (my $realname=maybe_mailrealname($maybe_realname_path)) {
	if ($email=~ /\S\s*<[^<>]*\@[^<>]*>/
	    or
	    $email=~ /<[^<>]*\@[^<>]*>\s*\S/
	   ) {
	    # fullname already there.
	    $email
	} else {
	    my $quotedrealname= $realname;
	    $quotedrealname=~ s/\"//sg;#well
	    $quotedrealname="\"$quotedrealname\"";
	    if ($email=~ /<[^<>]*\@[^<>]*>/) {
		# angle brackets already there.
		"$quotedrealname $email"
	    } else {
		"$quotedrealname <$email>"
	    }
	}
    } else {
	$email
    }
}

our $controlbase= "/var/qmail/control";
sub mailfrom_from_qmail_configuration {
    my $dom= xChompCatfile("$controlbase/me");
    unless ($dom=~ /\./) {
	$dom.= ".".xChompCatfile("$controlbase/defaultdomain");
    }
    username.'@'.$dom
}

sub mailfromaddress {
    my ($maybe_mail_path)=@_;
    $maybe_mail_path||= "$ENV{HOME}/.mailfrom";
    ($ENV{EMAIL}
     || $ENV{MAILFROM}
     || MaybeChompCatfile($maybe_mail_path)
     || mailfrom_from_qmail_configuration)
}

sub mailfrom {
    my ($maybe_mail_path)=@_;
    maybe_extend_with_realname mailfromaddress ($maybe_mail_path)
}



1
