# Tue Oct 23 05:27:41 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::Functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::ShellRPC::Functions;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      NewMarker
	      $shellquoted
	      CheckSuccess
	      CheckSuccessAndEmptyness
	      CheckSuccessJoin
	      ChopNL
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::Random::Formatted qw(random_passwd_string);
use Chj::singlequote ':all';

sub NewMarker {
    random_passwd_string(16); #128bit
}

our $shellquoted= sub {
    my (@cmd)=@_;
    join(" ",map{ singlequote_sh $_ } @cmd)
};
# our $identity= sub {
#     @_==1 or die;
#     my ($v)=@_;
#     $v
# };
# our $passthrough= sub {
#     @_
# };
# eh brauch ich ja doch nid bräucht ich eben nur wenn obige
# einzelnejedefunc ansatz verfolgt würde.

sub CheckSuccess {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; ####shit 'aha' eben wieder das WAS für ein error bitte. msg how.
    $reply
}
sub CheckSuccessAndEmptyness {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; #####dito
    (@$reply==1 and $$reply[0] eq "\n")
      or die "error: the command gave some (or none at all) output: ".Chj::singlequote::singlequote_many(@$reply);
}
sub CheckSuccessJoin {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; #####dito
    my $cnt= join("",@$reply);
    chop($cnt) eq "\n" or die "??missing additional newline at end of content";
    $cnt
}

sub ChopNL {
    my ($str)=@_;
    my $ch= chop($str);
    $ch eq "\n" or die "chopped character is not a newline: ".Chj::singlequote::singlequote_many($str,$ch);
    $str;
}


1
