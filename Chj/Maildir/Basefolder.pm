#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Maildir::Basefolder

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Maildir::Basefolder;

use strict;

use Chj::Path::Truncator::MD5; # a bit misused here.

use Chj::Maildir -extend=> (
			    'Basedirectorypath',# unix path
			    'Truncator',# undef or Chj::Path::Truncator::MD5 object
			   );


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Basedirectorypath])=@_;
    $s
}

# get the basefolder (toplevel parent) object (recursively called from
# Subfolder)
sub basefolder {
    my $s=shift;
    $s
}


# for courier, I returned "INBOX" from both of the following. courier
# expected subfolders like Maildir/.foo.bar/{new,cur,tmp} to be
# recorded in it's subscriptions file as "INBOX.foo.bar\n", whereas
# dovecot expects them as "foo.bar\n".

sub name {
    #"INBOX"
    # hm return undef here as well? Anyone using this method already?
    undef
}
sub imapboxstring {
    undef # meaning real empty, no dot to append. imapboxstring in
          # Subfolder.pm checks for undef on each iteration.
}

#sub add_childfolder {
#    my $s=shift;
#    
#}

sub create {
    my $s=shift;
    $s->maildirmake;
}

# unix path to directory containing new/cur/tmp/etc.
sub basepath {
    my $s=shift;
    $$s[Basedirectorypath]."/";
    # ^ / is needed so that recursion from Subfolder will work
}

# see Subfolder.pm
sub basename {
    ""
}

sub basedirectorypath { shift->[Basedirectorypath] }


sub truncator {
    my $s=shift;
    $$s[Truncator]||= do {
	my $t= Chj::Path::Truncator::MD5->new($$s[Basedirectorypath]);
	my $max= int( $t->maxfilename / 2.5);
	# ^ +- arbitrary decision that we occupy up to half the space
	# - this should allow to get a nesting depth of 2 of
	# automatically generated folders.
	$t->set_maxfilename($max);
	$t
    };
}
sub set_truncator {
    my $s=shift;
    ($$s[Truncator])=@_;
}


1
