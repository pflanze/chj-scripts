# Sun Oct 21 20:38:16 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::SSH

=head1 SYNOPSIS

 use Chj::Unix::ShellRPC::SSH;
 my $rcmd= Chj::Unix::ShellRPC::SSH->new_parse_location('chris@foo:/bar');
 $rcmd->do_connect_and_chdir;

=head1 DESCRIPTION


=cut


package Chj::Unix::ShellRPC::SSH;

use strict;

use Chj::Parse::Location; # a class
use Chj::Parse::LocationURIorSSH; # a module exporting a constructor function
use Carp;
use Chj::singlequote ();

use Chj::Unix::ShellRPC::Common -extend=>
  -publica=>
  'location', # a Chj::Parse::Location (or subclass or compatible) object
  ;


sub new_user_host_port_path { # some are optional!
    my $class=shift;
    my $s= $class->SUPER::new;
    $$s[Location]= Chj::Parse::Location->new_user_host_port_path(@_);
    # hopefully correct, whatever.
    $s
}

sub new_parse_location { # I'm not calling it new_location to prevent misunderstanding as passing it a location object.
    my $class=shift;
    my ($string_or_uri)=@_;
    my $s= $class->SUPER::new;
    $$s[Location]= MaybeLocationURIorSSH($string_or_uri)
      or croak "location string not valid ".Chj::singlequote($string_or_uri);
    $s
}

sub connection_command { # virtual
    my $s=shift;
    my (@cmd_to_be_run)=@_;
    my $maybevalue= sub {
	my ($methodname, $flagname)=@_;
	if (my $v= $$s[Location]->$methodname) {
	    ($flagname, $v)
	} else {
	    ()
	}
    };
    ("ssh",
     &$maybevalue("user","-l"),
     &$maybevalue("port","-p"),
     $$s[Location]->host,
     join(" ",map { quotemeta $_ } @cmd_to_be_run) ##[ is this always safe?.]
    )
}

sub location_path { # virtual
    my $s=shift;
    $$s[Location]->path
}

sub location_path_is_shellcode { # virtual
    my $s=shift;
    # for URI locations, it's unsafe, for SSH locations, it's safe. is this good terminology?  or  'shellcode', meaning, from SSH locations.
    $$s[Location]->path_is_shellcode
}

end Class::Array;

__END__

  tests:

calc> :l $r= Chj::Unix::ShellRPC::SSH->new_parse_location('chrissbx@p:/tmp/`echo $USER`')
Chj::Unix::ShellRPC::SSH=ARRAY(0x103ba470)
calc> :l $r->do_connect_and_chdir 
1
calc> :l $r->remote_get_cwd 
/tmp/chrissbx

calc> :l $r= Chj::Unix::ShellRPC::SSH->new_parse_location('ssh://chrissbx@p/tmp/`echo $USER`')
Chj::Unix::ShellRPC::SSH=ARRAY(0x103bd324)
calc> :l $r->do_connect_and_chdir 
bash: line 1: cd: /tmp/%60echo%20$USER%60: Datei oder Verzeichnis nicht gefunden
error at /usr/local/lib/site_perl/Chj/Unix/ShellRPC/Common.pm line 108, <GEN0> line 2.

calc> :l $r= Chj::Unix::ShellRPC::SSH->new_parse_location('ssh://chrissbx@p/')
Chj::Unix::ShellRPC::SSH=ARRAY(0x103dd38c)
calc> :l $r->do_connect_and_chdir 
1
calc> :l $r->remote_get_cwd 
/
calc> :l $r= Chj::Unix::ShellRPC::SSH->new_parse_location('ssh://chrissbx@p')
Chj::Unix::ShellRPC::SSH=ARRAY(0x104012e8)
calc> :l $r->do_connect_and_chdir 

calc> :l $r->remote_get_cwd 
/home/chrissbx

calc> :l $r= Chj::Unix::ShellRPC::SSH->new_parse_location('ssh://chrissbx@p/~')
Chj::Unix::ShellRPC::SSH=ARRAY(0x104048dc)
calc> :l $r->do_connect_and_chdir 
bash: line 1: cd: /~: Datei oder Verzeichnis nicht gefunden
error at /usr/local/lib/site_perl/Chj/Unix/ShellRPC/Common.pm line 108, <GEN12> line 2.

it's open how i should handle this.

