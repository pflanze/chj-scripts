# Wed Jul 21 15:49:55 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Maildir

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 TODO

 - quoting. derzeit darf kein . oder / drin sein in den namen. -- hm but see Subfolder, ?
 - not sure about transaction safety (sync), it's definitely unsafe on non-transactional filesystems (and maybe still on those as well)

=cut


package Chj::Maildir;

use strict;

use Chj::Hostname;
use Carp;
use Scalar::Util 'tainted'; ##only for debugging ç (zum glück störts nicht wenn tainted aufrufe unten drin wenn -T gar nicht aktiv)

use Class::Array -fields=> (
			    #'Basepath',nope
			   );

my $hostname = do {
    my $n= Chj::Hostname::hostname;
    $n =~ s|/|--|sg;
    $n =~ s|\.|,|sg;
    $n =~ m|(.*)|s;
    # ^- warum eigentlich nicht normale quoting func aufrufen? (cj24.10.04)
    $1
};

# # schönheitsmethode?:
# #sub create_childfolder {
# sub new_childfolder {
#     my $s=shift;
#     my ($name)=@_;
#     require Chj::Maildir::Subfolder;
#     Chj::Maildir::Subfolder->create_in_parent($s,$name);
# }

sub deliver_file {
    my $s=shift;
    my ($path,$optionalfilename)=@_;
    # 1090356705.4588.ethlife-a
    warn "deliver_file: tainted" if tainted $path;
    warn "deliver_file: tainted" if tainted $optionalfilename;
    my $basepath= $s->basepath;
    warn "deliver_file: tainted" if tainted $basepath;
    my $filename= $optionalfilename || $s->create_filename;
    my $targetpath= "$basepath/new/$filename";
    link $path,$targetpath
      or croak "deliver_file: link('$path','$targetpath'): $!";
    # todo: is this automatically fail save on reiserfs? or do i have to do a dir sync anyway ?
    $targetpath
}

{
    my $deliverylaufnummer=0;# just to make sure that we don't get into problems in case we aren't using a fork-one-process-per-delivery approach.

    sub create_filename {
	#my $class=shift;
	my $f=time().".${$}_$deliverylaufnummer.$hostname";
	$deliverylaufnummer++;
	$f;
    }
}

sub xmaildirmake {
    my $s=shift;
    my $basepath= $s->basepath;
    for("","new","tmp","cur") {
	mkdir "$basepath/$_",0700
	  or croak "xmaildirmake: mkdir '$basepath/$_': $!";
    }
}
sub maildirmake {
    my $s=shift;
    my $basepath= $s->basepath;
    return if -d $basepath;
    for("","new","tmp","cur") {
	mkdir "$basepath/$_",0700
	  or croak "xmaildirmake: mkdir '$basepath/$_': $!";
    }
    1
}


1;
