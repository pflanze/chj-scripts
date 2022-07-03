#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

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
use utf8;
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

# build parent chain and return myself at the end. (Almost same thing
# in SubfolderAndSubfolders.pm.)
sub new_from_subbasename {
    my $class=shift;
    my ($parent,$subbasename)=@_;
    # with 'fla/Maildir/.blah.bluh.blam', we are 'blah',
    #   then subbasename is '.bluh.blam'
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
    #$n=~ s|0x  nah
    $n=~ s/\&ANY-/Ö/sg;
    $n=~ s/\&APY-/ö/sg;
    $n=~ s/\&ANw-/Ü/sg;
    $n=~ s/\&APw-/ü/sg;
    $n=~ s/\&AMQ-/Ä/sg;
    $n=~ s/\&AOQ-/ä/sg;
    $n=~ s/\&-/\&/sg;
    # XX these are not necessarily restoring the original:
    $n=~ s/\\0/\0/sg;
    $n=~ s|--|/|sg;
    $n=~ s/,/\./sg;
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
    $n=~ s|/|--|sg;##  ps can't do without replacement outside? --?
    # (possibly important for security, too: )
    $n=~ s/\0/\\0/sg;
    # Thunderbird and/or Dovecot munge everything starting from and
    # including any ">" char, so replace that one as well:
    $n=~ s/>/}/sg;

    Chj::Encode::Imap::encode_imap ($n)
}

sub imapboxstring {
    my $s=shift;
    my $parent_imapboxstring= $$s[Parent]->imapboxstring;
    (defined($parent_imapboxstring) ? $parent_imapboxstring."." : "")
      . $s->quotedname # $$s[Name]; ## or may / be used here?
}


sub basedirectorypath {
    my $s=shift;
    $$s[Parent]->basedirectorypath
}

# create lock file in basefolder (if not exists) and lock it and
# return that lock
sub lock {
    my $s=shift;
    my ($is_allowed_to_create_basedir)=@_;
    my $basedirectorypath= $s->basedirectorypath;
    if (! -d $basedirectorypath and $is_allowed_to_create_basedir) {
	$s->basefolder->create
    }
    my $lockpath= $basedirectorypath . "/chj-maildir.lck";
    Chj::Lockfile->get($lockpath)
}


# "subscriptions" for dovecot; "courierimapsubscribed" for courier.
our $subscribedfilename= "subscriptions";

sub create {
    my $s=shift;
    my ($subscribe, $maybe_lock)=@_;

    return if $s->exists; # do not take lock and recurse into parents if not necessary.

    my $lock= $maybe_lock || $s->lock (1);

    # first create parents
    $$s[Parent]->create($subscribe, $lock);
    $s->maildirmake or return;# we exist already (XX right?)

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

sub exists {
    # note: currently only used internally by Subfolder class (there's
    # no such method in Basefolder class)
    my $s=shift;
    -d $s->basepath  # good enough check?
}

sub basename {
    # in the shell `basename` sense: the last part of the unix path
    # without slashes
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


1
