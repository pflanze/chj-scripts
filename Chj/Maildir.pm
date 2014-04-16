#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Maildir

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 TODO

 - quoting. Currently names may not contain . or / -- hm but see
   Subfolder, ?

 - not sure about transaction safety (sync), it's definitely unsafe on
   non-transactional filesystems (and maybe still on those as well)

=cut


package Chj::Maildir;

use strict;

use Chj::Hostname;
use Carp;
# XX only for debugging (luckily there's no problem calling tainted
# even when -T is not used):
use Scalar::Util 'tainted';

use Class::Array -fields=> (
			   );

my $hostname = do {
    my $n= Chj::Hostname::hostname;
    $n =~ s|/|--|sg;
    $n =~ s|\.|,|sg;
    $n =~ m|(.*)|s;
    # (^- why not call normal quoting function?)
    $1
};

# sub create_childfolder {
#     my $s=shift;
#     my ($name)=@_;
#     require Chj::Maildir::Subfolder;
#     Chj::Maildir::Subfolder->create_in_parent($s,$name);
# }

sub deliver_file {
    my $s=shift;
    my ($path,$optionalfilename)=@_;
    warn "deliver_file: tainted" if tainted $path;
    warn "deliver_file: tainted" if tainted $optionalfilename;
    my $basepath= $s->basepath;
    warn "deliver_file: tainted" if tainted $basepath;
    my $filename= $optionalfilename || $s->create_filename;
    my $targetpath= "$basepath/new/$filename";
    link $path,$targetpath
      or croak "deliver_file: link('$path','$targetpath'): $!";
    # is this automatically fail safe (on which filesystems?)? or do i
    # have to do a dir sync anyway ?
    $targetpath
}

{
    # to make sure that we don't get into problems in case we aren't
    # using a fork-one-process-per-delivery approach.
    my $deliverycount=0;

    sub create_filename {
	my $f=time().".${$}_$deliverycount.$hostname";
	$deliverycount++;
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


1
