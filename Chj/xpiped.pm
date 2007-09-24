# Mon Sep 24 20:16:11 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xpiped

=head1 SYNOPSIS

 $ calc -MChj::xpipeline=:all -MChj::xopen=:all -MChj::xpiped=:all
 calc> :l $in=xopen_read "foo"; $out= xopen_write "foo2"; xxpiped $in, $out, [qw(tr a b)]
 1

=head1 DESCRIPTION


=head1 NOTE/TODO

I think that should have it's place in another library. But where? 
Chj::xperlfunc? Don't think so. Chj::xpipeline? But it's not a
pipeline, only one piece. But mabe Chj::xpipeline itself could build
upon this? After all the ability to run either subref and arrayref
'commands' should be common code. WHICH code IT DOESN't even have Yet!

=cut


package Chj::xpiped;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(xpiped xxpiped);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::xperlfunc 'xfork','xwaitpid','xexec';
#use Chj::xperlfunc ':all';
#use Chj::repl;
use Chj::Unix::exitcode;
use POSIX 'dup2';

#repl;  well hab kein xdup2 in xperlfunc nein. weil isch posix.

sub xdupfh2 ($ $ ) {
    my ($fh,$fd)=@_;
    my $fno=fileno($fh);
    dup2($fno,$fd) or die "could not dup2($fno,$fd): $!";
}

sub xpiped ($ $ $ ) {
    my ($stdin,$stdout,$cmd)=@_;
    if (ref($cmd) eq "CODE") { die "CODE refs not yet supported (well it'd be easy enough but well. doit when needed)" }
    if (my $pid= xfork) {
	xwaitpid($pid); #does this return $? already  ?
	#$?
    } else {
	xdupfh2($stdin,0);
	xdupfh2($stdout,1);
	xexec @$cmd
    }
}

sub xxpiped ($ $ $ ) {
    my $res= &xpiped;
    $?==0 or die "xxpiped (".singlequote_many(@_)."): ".exitcode($?)
}


1
