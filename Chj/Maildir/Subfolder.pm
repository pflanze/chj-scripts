# Wed Jul 21 16:02:09 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Maildir::Subfolder

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Maildir::Subfolder;

use strict;
use Chj::xsysopen;
use Chj::xsysopen 'xsysopen_append';
use Carp;

use Chj::Maildir -extend=> (
			    'Parent',
			    'Name',
			   );


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Parent],$$s[Name])=@_ or croak "new: requires parent to be given";
    $s
}

sub new_from_subbasename { # parentkette bilden und mich, am schluss, zurückgeben.     ALMOST same thing in SubfolderAndSubfolders.pm
    my $class=shift;
    my ($parent,$subbasename)=@_;# bei fla/Maildir/.blah.bluh.blam: und wir sind blah, dann: subbasename: .bluh.blam
    if ($subbasename=~ s/^\.([^.]+)//s) {
	my $quotedname=$1;
	my $s=$class->new_quoted($parent,$quotedname);
	if (length $subbasename) {
	    $class->new_from_subbasename($s,$subbasename);
	} else {
	    $s
	}
    } else {
	croak "new_from_subbasename: subbasename '$subbasename' does not match criteria";
    }
}

sub new_quoted {
    my $class=shift;
    my ($parent,$quotedname)=@_;
    my $s= $class->SUPER::new;
    $$s[Parent]=$parent;
    $$s[Name]= _unquotename ($quotedname);
    $s
}


sub name {shift->[Name]}
sub set_name {
    my $s=shift;
    ($$s[Name])=@_;
}

sub parent {shift->[Parent]}

sub _unquotename {
    my $n=shift;
    #$n=~ s|0x  nee, wo ischt ende?
    $n=~ s/\&ANY-/Ö/sg;
    $n=~ s/\&APY-/ö/sg;
    $n=~ s/\&ANw-/Ü/sg;
    $n=~ s/\&APw-/ü/sg;
    $n=~ s/\&AMQ-/Ä/sg;
    $n=~ s/\&AOQ-/ä/sg;
    $n=~ s/\&-/\&/sg;
    $n=~ s/\\0/\0/sg;#nicht unbedingt originalgetreu
    $n=~ s|--|/|sg;#nicht unbedingt originalgetreu
    $n=~ s/,/\./sg;#nicht unbedingt originalgetreu
    $n
}

# once again up-dispatching to the toplevel parent.
sub truncator {
    my $s=shift;
    $$s[Parent]->truncator
}
sub set_truncator {
    my $s=shift;
    $$s[Parent]->set_truncator(@_)
}

sub quotedname {
    my $s=shift;
    my $n= $s->truncator->trunc($$s[Name]);
    $n=~ s/\./,/sg;##
    $n=~ s|/|--|sg;##  ps kann auf ersetzerei aussenrum ev verzichen dann.?
    $n=~ s/\0/\\0/sg;##  (just to be sure weil weiss nie wie sich das schraeg auswirken kann wenn in c string umgewandelt wird)
    # begin of a quoting implementation. ((but NOTE: if you take the value of a header in a received email, for finding out the mailboxname the mail should be filtered into, it'll have to be unencoded from mime stuff first))
    $n=~ s/\&/\&-/sg;
    $n=~ s/ä/\&AOQ-/sg;
    $n=~ s/Ä/\&AMQ-/sg;
    $n=~ s/ü/\&APw-/sg;
    $n=~ s/Ü/\&ANw-/sg;
    $n=~ s/ö/\&APY-/sg;
    $n=~ s/Ö/\&ANY-/sg;
    $n=~ s|(.)|my $c=$1; if (ord($c)>127) { '0x'.ord($c) } else { $c }|seg;
    $n=~ m/(.*)/s;
    $1
}

sub imapboxstring {
    my $s=shift;
    $$s[Parent]->imapboxstring . ".". $s->quotedname # $$s[Name]; ## oder darf hier / vorkommen?
}


sub basedirectorypath {
    my $s=shift;
    $$s[Parent]->basedirectorypath
}

sub create {
    my $s=shift;
    my ($subscribe)=@_;
    #$s->maildirmake or return;# if already exists, not even bother to check if parent subfolders exist as well (not very dangerous since if only we and other well-behaving clients are creating subfolders correctly nothing will go wrong)
#     if ($$s[Parent]->isa("Chj::Maildir::Basefolder")) {
# 	$$s[Parent]->create($subscribe);
# 	$s->maildirmake or return;
#     } else {
# 	$s->maildirmake or return;
# 	$$s[Parent]->create($subscribe);
#     }	
# we can only optimize, if we know that the basedirectory already exists.Stophackingaroundnow

    # first create parents
    $$s[Parent]->create($subscribe);
    $s->maildirmake or return;# we exist already (right?) (ç)

    my $basepath= $s->basepath;
    xsysopen "$basepath/maildirfolder",O_CREAT,0700;
    if ($subscribe) {
	my $basedirectorypath= $s->basedirectorypath;
	my $imapboxstring= $s->imapboxstring;
	my $append= xsysopen_append "$basedirectorypath/courierimapsubscribed";
	$append->xprint("$imapboxstring\n");
	$append->xclose;
    }
}

sub basepath {
    my $s=shift;
    $$s[Parent]->basepath . "." . $s->quotedname #  $$s[Name]
}

sub basename {# haha, in the shell `basename` sense: the last part of the unix path that's without slashes.
    my $s=shift;
    $$s[Parent]->basename . "." . $s->quotedname
}

# sub create_in_parent {
#     my $class=shift;
#     my ($parent)=@_;# Basefolder oder Subfolder
#     my $s=$class->new();
#     $$s[Parent]=$parent;
#     #....
#     $s
# }



# sub create_childfolder {
#     my $s=shift;
    
# }


# cj 4.8.04:
# rename?  oder delete?  in beiden fällen müsste geprüft werden ob es subfolders gibt.
# in welchem falle der folder nur geleert werden dürfte, nicht rmeoved. oder aber: alle sub folders nach-gemoved.
# mitmoven isch wohl gescheiter
# sub list_of_subfolders {
#     my $s=shift;
#     my $basedirectorypath= $s->basedirectorypath;
#     my $d=xopendir $basedirectorypath;
#-> Chj::Maildir::SubfolderAndSubfolders

#sub DESTROY {
#    my $self=shift;
#    # çç dito rausschmeissen wenn nicht benutzt
#    $self->SUPER::DESTROY;
#}

1;
