# Mon Nov  1 21:17:21 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vserver

=head1 SYNOPSIS

 use Chj::Vserver;

 my $vs= new Chj::Vserver "voip";
 print "Vserver Name: ".$vs->name."\n";
 if (my $st= $vs->status) {
     # now we at least know such a vserver configuration exists
      for (qw(context status processes uptime)) {
          print "  $_: ",$st->$_,"\n";
      }
      print "is it running?: ", $st->running ? "yes":"no","\n";
      # we can also be confident that we get a defined rootdir (vdir, chroot, vroot) value.
      print "the root directory of the vserver is at: ",$vs->rootdir,"\n";
      print "\n";
 } else {
     print "no such vserver exists\n";
 }


=head1 DESCRIPTION


=head1 SEE ALSO

L<Chj::Vserver::Status>

=cut


package Chj::Vserver;
use strict;
use Carp;
use Chj::Vserver::Status;
use Chj::Cwd::realpath;
use Chj::VserverSettings '$etcbase','chroot_sh_cat';

use Class::Array -fields=>
  -pub=>
  'name',#hm, should this really be private so noones circumventing the set_name method? but protected, and for reading, it still makes sense to access the field directly, no?

  -private=>
  ;
end Class::Array;

sub new {
    my $cl=shift;
    my $s=$cl->SUPER::new;
    #($$s[Name])=@_;
    my ($name)=@_;
    $s->set_name($name) if defined $name;
    $s
}

sub set_name {
    my $s=shift;
    my ($name)=@_;
    $name=~ m|^([^./\s]+)\z|s or croak "name '$name' is invalid"; ##(should we restrict it even further? it's being untainted here after all) --heh ja, . war noch akzeptiert....
    $$s[Name]=$1
}


sub status {
    my $s=shift;
    # create status object.
    # but code it here since here it's more generically usable? or should we rahter create a base class for vserver_cmd stuff? ok latter
    new Chj::Vserver::Status $$s[Name];
}

sub is_running { #ah just delegate..
    my $s=shift;
    $s->status->running
}

sub has_unification {
    my $s=shift;
    -d $s->configdir."/apps/vunify"
}

sub xname {#actually I should use "name" for guaranteed value and "maybe_name" for accessor?
    my $s=shift;
    $s->name or croak "vserver name is undefined";
}

sub configdir {
    my $s=shift;
    "$etcbase/".$s->xname  #check for existence? not, too many stats.'for nothing'.('at least not until I cache the result here' but weh)
}

sub rootdir {
    # actually we should (really) do as in status: call the external tool; (but return an object?)
    my $s=shift;
    my $name= $s->name or croak "vserver name is undefined";
    my $attempt1= realpath "/vservers/$name"
      or croak "vserver root does not seem to exist? (or I won't trust the config in '$etcbase' alone)";
    if (my $attempt2= realpath "$etcbase/$name/vdir") {
	if ($attempt1 eq $attempt2) {
	    # assume it's all dandy
	    $attempt1
	} else {
	    die "the two attempts differ";
	}
    } else {
	# hope it's fine.
	carp "root: WARNING: THIS IS NOT really a good way, don't trust this too much";
	$attempt1
    }
}

sub Stripspace ($ ) { #wie ewig dieser hier?
    my ($str)=@_;
    $str=~ s/^\s+//s;
    $str=~ s/\s+\z//s;
    $str
}

sub maybe_debian_version {
    my $s=shift;
    my $rd= $s->rootdir;
    my $f= chroot_sh_cat $rd,"/etc/debian_version";
    my $val= $f->xreadline_chomp;
    if ($f->xfinish ==0) {
	Stripspace($val)
    } else {
	warn "not a debian vserver: '$rd'";
	undef # or return ?  implicit lists debianeh perl difficult.shig.
    }
}

1;
__END__

  btw see tests on elvis:(inchroot)tmp/test/

