# Sun Oct 24 20:55:50 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Path::Truncator::MD5

=head1 SYNOPSIS

 my $truncator= new Chj::Path::Truncator::MD5 "/base/path/of/your/stuff";# ,5; to give 5 chars 'reserve' to the length
 my $shortenough= $truncator->trunc("/some/path");

=head1 DESCRIPTION

Truncates filenames so that the resulting path is short enough for
being handled by the OS/filesystem.

Currently only the filename length is looked
at, not the whole path length (which would probably require the given
paths to be realpaths -> either trust or overhead).

A filename is left unmodified, if it's one shorter than the maximal path
lenth (so you can determine for sure if it has been shortened or not by looking
at it's length). If it is longer, it's md5 sum is calculated, and it is shortened
so that the hex'ed md5 sum can be appended in brackets and tree dots
put in between, like
  '/some/path/with/too_long_filename...(snipped)...too_long_fi...(MD5_HEX)'

=cut


package Chj::Path::Truncator::MD5;

use strict;
use Chj::Config::Path;
use Carp;
use Digest::MD5;

use Class::Array -fields=> (
 "Initpath", # currently not useful to keep but don't care
 "MaxFilename",
);

sub maxfilename { shift->[MaxFilename] }
sub set_maxfilename {
    my $s=shift;
    ($$s[MaxFilename])=@_;
}


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    my $reserve;
    ($$self[Initpath], $reserve) =@_;
    $$self[MaxFilename]= Chj::Config::Path::max_filename_length($$self[Initpath]);
    $$self[MaxFilename] -= $reserve if $reserve;
    $self
}

sub trunc {
    my $self=shift;
    my ($path)=@_;
    my ($origdir,$origfilename)= $path=~ m|(.*?)([^/]+)/?\z|s #hm, accept trailing slash and assume that the user wants the last dir part truncated. reasonable? send me mail if you count on this feature.
      or croak "trunc: invalid path '$path'";
    if (length($origfilename) < $$self[MaxFilename]) {
	$path
    } else {
	my $dig= Digest::MD5::md5_hex($origfilename);
	$origdir.substr($origfilename,0,
			$$self[MaxFilename]-3-2-32)."...($dig)";
    }
}

1;
