#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Web::url_encode

=head1 SYNOPSIS

=head1 DESCRIPTION

I don't expect this to be fully correct. Also, I expect there to be
some existing perl lib that does it. I'm too lazy to find it, though.

=cut


package Chj::Web::url_encode;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(url_encode);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

sub url_encode {
    my ($str)=@_;
    #my $str= decode("utf-8", $_str, Encode::FB_CROAK);
    #  -- nope, actually *want* it as utf-8 code points.
    #local our $u= URI->new($str);
    #hm no method for that.
    $str=~ sé(.)é
      my $c=$1;
      my $n= ord $c;
      if ($c=~ m{[A-Za-z0-9_/.=-]}) {
	  $c
      } else {
	  '%'.sprintf('%02X',$n)
      }
    éseg;
    $str
    #use Chj::repl;repl;
}


1
