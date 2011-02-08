# Thu May 20 21:29:17 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Daemonizer

=head1 SYNOPSIS

 use Chj::Unix::Daemonizer;
 use Chj::xsysopen qw(xsysopen_append);

 my $daemonizer=  Chj::Unix::Daemonizer->default->clone;
 $daemonizer->set_runpath("run");# this will be a file
 {
     my $log= xsysopen_append "log";
     #$log->autoflush(1);# would not help since it's forgot by the dup
     $daemonizer->set_outputs($log);
 } # but note that the log fd will currently be kept around in $daemonizer even in the parent

 if ($daemonizer->fork) {
     # just exit, leaving the child running alone
 } else {
     # IMPORTANT: with the current usage of DaemonRunfile,
     # do not destroy $daemonizer here! or the runfile lock will be gone
     # (exec is ok as long as the open filehandle is not closed)
     $|++; # now, after the dup, setting autoflush helps
     print "Hello World\n";
     sleep 10;
     print "Bye World.\n";
 }


Note: calling Chj::Unix::Daemonizer->default->clone as opposed to
Chj::Unix::Daemonizer->new will make the namegiver (which caches
ip/hostname) shared for all daemonizer instances, so it's preferred if
you create multiple of them.


=head1 DESCRIPTION

Easy daemon generator.

=head1 METHODS

=over 4

=item new() default() set_default($obj)

default() calls new() once and then always returns that same instance.

=item set_in(x) set_out(x) set_err(x)

x may be either a filehandle object/reference or a filedescriptor
number.  These are stored and used after the fork call for dup2 in the
child.  If never called or undef is given, the redirections will go to
/dev/null; if the empty string is given, no redirection will be done.

=item set_outputs(x)

sets both the out and err fields to the same value.

=item set_runpath(path)

This call is (currently, well we could live without a runfile too)
mandatory; this is then passed to Chj::Unix::DaemonRunfile->new.

=item namegiver() set_namegiver($obj)

usually not necessary, uses a builtin namegiver; passed to
Chj::Unix::DaemonRunfile->new.

=item fork()

Does one fork, and in the child: calls writefile on DaemonRunfile,
calls setsid, redirects stdin/out/err to the values in the In/Out/Err
fields or /dev/null unless they are set to the empty string, then
returns with either the pid of the child in the parent or undef in the
child.

Throws exceptions on error, propagating exceptions during the
initialization phase in the child to the parent.

=back

=head1 SEE ALSO

L<Chj::Unix::DaemonRunfile>

=cut


package Chj::Unix::Daemonizer;

use strict;
use Chj::xperlfunc qw(xfork xfileno);
use Chj::xpipe;
use POSIX "setsid";
use Chj::Unix::DaemonRunfile;
use Carp;

use Class::Array -fields=> (
			    "Runpath",# file path e.g. ".../foo.run" (or maybe .lck)
			    "_Runfile",
			    "In", # zahl oder fh, oder undef, oder: "" für gar nix machen
			    "Out",
			    "Err",
			    "Namegiver",
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    @$self[Runpath,Namegiver]=@_;## sinn hier was zu geben wenn dann ja doch später übergeben müssen?!
    #$$self[Namegiver]= Chj::Unix::Daemonizer::Namegiver->default; sigh, Can't call method "default" without a package or object reference
    $$self[Namegiver] ||= "Chj::Unix::Daemonizer::Namegiver"->default;
    $self
}


#my $single;
my $default;# defaultinstance wär halt auch besser; na, "my $a= default Daemonizer" tönt aber auch gut. Die Frage ist nur, soll eine programmiersprache gut tönen?
sub default {
    my $class=shift;
    $default||=$class->new(@_);# komisch, bei erstmalig werden argumente angekuckt? und ja muss andersch lauten als set_default in dem fall   aber eh komisch dass ein obj transparent kreiert wird dadurch oder findsch nöd?.
}
sub set_default {#(sollte einen required parameter haben)
    my $class=shift;
    ($default)=@_;
}

# clone is already implemented in Class::Array

# ----

sub set_in {
    my $self=shift;
    ($$self[In])=@_;
}
sub set_out {
    my $self=shift;
    ($$self[Out])=@_;
}
sub set_err {
    my $self=shift;
    ($$self[Err])=@_;
}
sub set_outputs {
    my $self=shift;
    ($$self[Err])=@_;
    $$self[Out]=$$self[Err];
}

sub set_runpath {
    my $s=shift;
    ($$s[Runpath])=@_;
}
# ---

sub namegiver{shift->[Namegiver]} sub set_namegiver {my $s=shift;($$s[Namegiver])=@_}

# ---

## to do, die ersetzen durch etwas besseres. durch etwas was jenachdem wo der text eruiert wird was anderes anzeigt!.  ach oder halt regex scheisse

sub fork {
    my $s=shift;
    my ($maybe_alreadyrunningcb)=@_;
    my ($read,$write)=xpipe;
    if (my $pid=xfork) {
	$write->xclose;
	my $cont=$read->xcontent;
	$read->xclose;
	if ($cont) {
	    waitpid $pid,0;
	    my $status= $?;#well but so what~.
	    if ($cont eq "\0") {
		&$maybe_alreadyrunningcb
	    } elsif ($cont=~ s/^\001//s) {
		$cont=~ s/ at .*?\z//s;
		croak $cont;
	    } else {
		die "error in transmission??"
	    }
	} else {
	    $pid;
	}
    } else {
	eval {
	    $read->xclose;
	    $$s[_Runfile]= Chj::Unix::DaemonRunfile->new($$s[Runpath],$$s[Namegiver]);
	    $$s[_Runfile]->writefile
	      (undef,
	       $maybe_alreadyrunningcb && sub {
		   die (bless {}, "ALREADYRUNNING")
	       });
	    # ^ throws exception if already in use. ##interessant: erst nach dem fork?
	    #$$s[_Runfile]->autoclean;#(well, doch ziemlich unnötig
	    #   dass dies eine extra methode ist?)
	    # ^- rather dangerous since we do not know if the user is
	    # keeping the daemonizer instance till the end? well no,
	    # it'll release the lock anyway at that point so we loose
	    # nothing.
	    # ^- AH f*ck, yes it is a problem, in the case where the
	    # daemon forks off a perl child which does not exec but
	    # exit itself, it will remove the pidfile while the parent
	    # is still running. no chance switching that off except
	    # manually or hooking into fork.
	    setsid or die "setsid: $!";
	    if (defined $$s[In]) {
		if (length $$s[In]) {
		    open STDIN,"<&".xfileno($$s[In])
		      or die "error dupping from $$s[In]: $!";
		}
	    } else {
		open STDIN,"</dev/null"
		  or die "error opening /dev/null for reading: $!";
	    }
	    if (defined $$s[Out]) {
		if (length $$s[Out]) {
		    open STDOUT,">&".xfileno($$s[Out])
		      or die "error dupping to $$s[Out]: $!";
		}
	    } else {
		open STDOUT,">/dev/null" or die "error opening /dev/null for writing: $!";
	    }
	    if (defined $$s[Err]) {
		if (length $$s[Err]) {
		    open STDERR,">&".xfileno($$s[Err])
		      or die "error dupping to $$s[Err]: $!";
		}
	    } else {
		open STDERR,">/dev/null"
		  or die "error opening /dev/null for writing: $!";
	    }
	};
	my $e=$@;
	if (ref $e or $e){
	    if (UNIVERSAL::isa ($e,"ALREADYRUNNING")) {
		$write->xprint("\0");#belive in special, unquoted ugly stuff.hm.
	    } else {
		$write->xprint("\1".$e);#ok not unquoted. done right. well. uuugly.
	    }
	    $write->xclose;
	    exit 1;
	}
	$write->xclose;
	return;# yes, don't exit here, the real 'body' code is coming outside.
    }
}





{
    package Chj::Unix::Daemonizer::Namegiver;
    # which is a per-instance (and moreover per-method) caching implementation.

    use Sys::Hostname ();
    use Chj::Net::Publicip;
    use Chj::username ();

    use Class::Array -fields=> (
				"User",
				"Hostname",
				"Ip",
				"Pid"
			       );

    sub user {
	my $s=shift;
	$$s[User] ||= Chj::username::username;
    }
    sub hostname {
	my $s=shift;
	$$s[Hostname] ||= Sys::Hostname::hostname || "";## vorsicht exceptions?
    }
    sub ip {
	my $s=shift;
	$$s[Ip] ||= Chj::Net::Publicip::publicip || ""; ## vorsicht exceptions?
    }
    sub pid {
	my $s=shift;
	$$s[Pid] ||= $$
    }

    my $default;
    sub default {
	my $class=shift;
	$default||=$class->new(@_);
    }
    sub set_default {#(sollte einen required parameter haben)
	my $class=shift;
	($default)=@_;
    }
}

1;
