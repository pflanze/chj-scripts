#
# Copyright 2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Return_path

=head1 SYNOPSIS

 use Chj::Mail::Return_path;
 Return_path ( )
  or
 Return_path ( "fromaddress_or_messageid" )


=head1 DESCRIPTION


=cut


package Chj::Mail::Return_path;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Return_path);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# something like:
# Return-path: <christian@jaeger.mine.nu>

use Chj::Mailfrom qw(mailfromaddress);

sub Return_path ( ; $ ) {
    my ($maybe_from)=@_;
    my $fallback=sub {
	"<".mailfromaddress.">"
    };
    if ($maybe_from) {
	my $s=$maybe_from;
	$s=~ s/^.*<//s;
	$s=~ s/>.*//s;
	if ($s=~ /\@/) {
	    "<".$s.">"
	} else {
	    &$fallback
	}
    } else {
	&$fallback
    }
}

1
