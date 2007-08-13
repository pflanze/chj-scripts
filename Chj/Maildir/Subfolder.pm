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


=head1 NOTES

The create() method does locking (necessary, right?, to prevent double
subscriptions) by itself. Everything else should be
thread/multiprocessing safe anyway (right?).


=cut


package Chj::Maildir::Subfolder;

use strict;
use Chj::xsysopen;
use Chj::xsysopen 'xsysopen_append';
use Carp;
use Chj::Lockfile;
use Chj::Encode::Imap;

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

sub basefolder { # get the basefolder (toplevel parent) object
    my $s=shift;
    $$s[Parent]->basefolder
}

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
    # change the chars which aren't escaped by encode_imap:
    $n=~ s/\./,/sg;##
    $n=~ s|/|--|sg;##  ps kann auf ersetzerei aussenrum ev verzichen dann.?
    $n=~ s/\0/\\0/sg;##  (just to be sure weil weiss nie wie sich das schraeg auswirken kann wenn in c string umgewandelt wird)
    # Thunderbird and/or Dovecot munge everything starting from and
    # including any ">" char, so replace that one as well:
    $n=~ s/>/}/sg;

    Chj::Encode::Imap::encode_imap ($n)
}

sub imapboxstring {
    my $s=shift;
    my $parent_imapboxstring= $$s[Parent]->imapboxstring;
    (defined($parent_imapboxstring) ? $parent_imapboxstring."." : "")
      . $s->quotedname # $$s[Name]; ## oder darf hier / vorkommen?
}


sub basedirectorypath {
    my $s=shift;
    $$s[Parent]->basedirectorypath
}

sub lock { # create lock file in basefolder (if not exists) and lock it and return that lock
    my $s=shift;
    my ($is_allowed_to_create_basedir)=@_;
    my $basedirectorypath= $s->basedirectorypath;
    if (! -d $basedirectorypath and $is_allowed_to_create_basedir) {
	$s->basefolder->create
    }
    my $lockpath= $basedirectorypath . "/chj-maildir.lck";
    Chj::Lockfile->get($lockpath)
}


our $subscribedfilename= "subscriptions"; # "subscriptions" for dovecot; "courierimapsubscribed" for courier.

sub create {
    my $s=shift;
    my ($subscribe, $maybe_lock)=@_;

    return if $s->exists; # do not take lock and recurse into parents if not necessary.

    my $lock= $maybe_lock || $s->lock (1);

    # first create parents
    $$s[Parent]->create($subscribe, $lock);
    $s->maildirmake or return;# we exist already (right?) (ç)

    my $basepath= $s->basepath;
    xsysopen "$basepath/maildirfolder",O_CREAT,0700;
    if ($subscribe) {
	my $basedirectorypath= $s->basedirectorypath;
	my $imapboxstring= $s->imapboxstring;
	my $append= xsysopen_append "$basedirectorypath/$subscribedfilename";
	$append->xprint("$imapboxstring\n");
	$append->xclose;
    }
}

sub basepath {
    my $s=shift;
    $$s[Parent]->basepath . "." . $s->quotedname #  $$s[Name]
}

sub exists { #note: currently only used internally by Subfolder class (there's no such method in Basefolder class)
    my $s=shift;
    -d $s->basepath  # good enough check?
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
