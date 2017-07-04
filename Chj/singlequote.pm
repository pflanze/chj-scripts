#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::singlequote

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::singlequote;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(singlequote);
@EXPORT_OK=qw(singlequote_sh singlequote_sh_lenient
	      singlequote_many many);
# importing 'many' is probably not a good idea (depreciated)
%EXPORT_TAGS=(all=>[qw(singlequote singlequote_sh singlequote_many)]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub singlequote($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/\'/\\\'/sg;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}
sub singlequote_sh($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/\'/'\\\''/sg;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}

sub singlequote_sh_lenient($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	if ($str=~ /^[\w\/.\@+:=-]+\z/s) {
	    $str
	} else {
	    $str=~ s/\'/'\\\''/sg;
	    "'$str'"
	}
    } else {
	defined($alternative)? $alternative:"undef"
    }
}


*Chj::singlequote= \&singlequote;
*Chj::singlequote_sh= \&singlequote_sh;

sub many {
    if (wantarray) {
	map { singlequote($_) } @_
    } else {
	join ", ", map { singlequote($_) } @_
    }
}
*singlequote_many= \&many;


1
