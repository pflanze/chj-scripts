# Fri Mar 19 21:22:49 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Web::FileescapeUrl

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 BUGS

shit, urls containing minus and slash adjacent, will be in-returnable. irrecreatable.

=cut


package Chj::Web::FileescapeUrl;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(fileescapeurl);
use strict;

sub fileescapeurl {
    # Die Regel ist: wenn die url ein - enthält, dann / mit zwei -- ersetzen.
    # Wenn die url -- enthält, / mit --- ersetzen.
    # Also: (fürs unescapen) die maxzahl der minusse ist die die ICH verwende für /.
    my ($url)=@_;
    my $minuslen=0;
    while ($url=~ /(-{1,})/sg) {
            $minuslen= length($1) if length($1)>$minuslen;
    }
    my $replacement= "-"x($minuslen+1);
    $url=~ s|/|$replacement|sg;
    $url
}

1;
