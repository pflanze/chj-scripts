# Sun Nov 28 15:32:09 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Df::Disk

=head1 DESCRIPTION

Represents one disk  with it's DiskFree sizes.

In string context, shows some nice text.

=head1 METHODS

 device
 total
 used
 avail_df     space as shown by df (available to users)
 avail_root   space available to root
 avail_user   same as avail_df

 stringify    return a string representation, used by string context overload

=head1 SEE ALSO

L<Chj::Unix::Df>

=cut


package Chj::Unix::Df::Disk;

use strict;
use Carp;
use overload '""'=> 'stringify';

use Class::Array -fields=>
  'df',
  -publica=>
  'mount', # mount point, or disk name.
  ;


sub new {
    my $class=shift;
    @_==2 or croak "wrong number of args";
    my $s= $class->SUPER::new;
    (@$s[Df,Mount])=@_;#und scho vergessen hier.
    $s
}

for my $method (qw(device total used)) { # all except mount (which is already available statically) and  avail (which I provide two better alternatives)
    no strict 'refs';
    *$method = sub {
	my $s=shift;
	$$s[Df]->$method($$s[Mount])
    };
}
# ^- ist das code generation? eigentlich nicht :))

sub avail_df {
    my $s=shift;
    $$s[Df]->avail($$s[Mount]);
}

sub avail_root {
    my $s=shift;
    $s->total - $s->used
}
# sub avail_user {
#     my $s=shift;
#     #$$s[Df]->avail  nope, not even usable for this purpose?
#     my $remain=  int(($s->total / $s->blocksize) * 0.9492) * $s->blocksize - $s->used;
#     # allow negative values? oh well do just allow them!
#     $remain
# }
# hm, the above has two problems: a) the constant is not 5% but something strange. b) for some partition it's even 0%.  And it seems, it's only this which disturbed me: the 5% limit is only active (at least by default) when using ext3, but not when using reiserfs. So df is calculating stuff correctly and not doing special casing full partitions as I already started to believe. So I now switch back to df's values:

*avail_user= \&avail_df;

#sub blocksize {
#    512  ##tja.
#}

sub stringify {
    my $s=shift;
    $s->device ." mounted on ". $s->mount
}

end Chj::Unix::Df::Disk;
