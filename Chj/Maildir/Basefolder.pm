# Wed Jul 21 16:04:04 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Maildir::Basefolder

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Maildir::Basefolder;

use strict;

use Chj::Path::Truncator::MD5;# a bit misused here.

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


sub name {
    "INBOX"
}
sub imapboxstring {
    "INBOX"
}

#sub add_childfolder {
#    my $s=shift;
#    
#}

sub create {
    #my $class=shift;
    my $s=shift;
    $s->maildirmake;
}

sub basepath { # unix path to directory containing new/cur/tmp/etc.
    my $s=shift;
    $$s[Basedirectorypath]."/";# / is needed so that recursion will work out from Subfolder
}

sub basename {# see Subfolder.pm;
    ""
}

sub basedirectorypath { shift->[Basedirectorypath] }



sub truncator {
    my $s=shift;
    $$s[Truncator]||= do {
	my $t= Chj::Path::Truncator::MD5->new($$s[Basedirectorypath]);
	my $max= int( $t->maxfilename / 2.5);# +- arbitrary decision by myself that we occupy up to half the space - this should allow to get a nesting depth of 2 of automatically generated folders after all.
	$t->set_maxfilename($max);
	$t
    };
}
sub set_truncator {
    my $s=shift;
    ($$s[Truncator])=@_;
}



1;
