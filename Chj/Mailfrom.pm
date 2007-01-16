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
@EXPORT_OK=qw(mailfrom
	      maybe_extend_with_realname
	      mailrealname
	     );

use strict;
use Chj::catfiletrim;
use Chj::username;

sub mailrealname {
    my ($maybe_path)=@_;
    $maybe_path||= "$ENV{HOME}/.mailrealname";
    catfiletrim $maybe_path;
}

sub maybe_extend_with_realname ( $ ) {
    my ($email,$maybe_realname_path)=@_;
    my $realname=mailrealname($maybe_realname_path);
    unless($realname) {
	return $email
    }
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
}

our $controlbase= "/var/qmail/control";
sub mailfrom_from_qmail_configuration {
    my $dom= catfiletrim("$controlbase/me");
    unless ($dom=~ /\./) {
	$dom.= ".".catfiletrim("$controlbase/defaultdomain");
    }
    username.'@'.$dom
}

sub mailfrom {
    my ($maybe_mail_path)=@_;
    $maybe_mail_path||= "$ENV{HOME}/.mailfrom";
    my $mailfrom= $ENV{EMAIL} || $ENV{MAILFROM} || catfiletrim($maybe_mail_path) || mailfrom_from_qmail_configuration;
    maybe_extend_with_realname $mailfrom
}



1
