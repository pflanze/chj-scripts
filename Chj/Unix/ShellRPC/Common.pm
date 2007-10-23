# Sun Oct 21 20:38:42 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::ShellRPC::Common

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::ShellRPC::Common;

use strict;

use Chj::IO::CommandBidirectional;
use Chj::Random::Formatted ();
use Carp;

use Class::Array -fields=>
  -publica=>
  'fh', # bidirectional filehandle
  ;

sub do_connect {
    my $s=shift;
    $$s[Fh]= Chj::IO::CommandBidirectional->new_inout
      ($s->connection_command($s->remote_shellcommand));
}

sub do_connect_and_chdir {
    my $s=shift;
    $s->do_connect;
    if (my $p= $s->location_path) {
	my $method= $s->location_path_is_shellcode ? "remote_chdir" : "remote_chdir_safe";
	$s->$method($p)
    }
}

sub remote_shellcommand { # a list
    my $s=shift;
    # default:
    #("bash","-e") no, -e is actually not a good idea if I want to get the value, right?
    ("bash")
}

sub NewMarker {
    Chj::Random::Formatted::random_passwd_string(16); #128bit
}

sub remote_run_commandstring_with_statusreply { # returns (\@replylines, $status_code) ((should that be wrapped up in an objct eh going silly?))
    my $s=shift;
    @_==1 or @_==2 or croak "wrong number of arguments";
    my ($cmdstring,$maybe_sendcb)=@_;
    my $marker= NewMarker;
    my $wholecmd= $cmdstring.' ; echo -e \\\\n'.$marker.'-$?'."\n";
    $$s[Fh]->xprint($wholecmd);
    if ($maybe_sendcb) {
	&$maybe_sendcb($$s[Fh])
    }
    $$s[Fh]->xflush;
    my @reply;
    #warn "marker: ".Chj::singlequote::singlequote_many($marker);#
    while(1) {
	my $line= $$s[Fh]->xreadline;
	#warn "got line: ".Chj::singlequote::singlequote_many($line);#
	if ($line=~ /^$marker-(\d+)/) {
	    return (\@reply, $1)
	}
	push @reply,$line;
    }
}

# sub remote_run_command_with_statusreply {
#     my $s=shift;
#     @_>=1 or croak "missing arguments";
#     my (@cmd)=@_;
#     $s->remote_run_commandstring_with_statusreply(join(" ",map{ quotemeta $_ } @cmd))
# }
#sinnlos, besser das generisch allgemein offerieren. statt danach  jede methode wählen zu wollen.
our $shellquoted= sub {
    my (@cmd)=@_;
    join(" ",map{ quotemeta $_ } @cmd)
};
# our $identity= sub {
#     @_==1 or die;
#     my ($v)=@_;
#     $v
# };
# our $passthrough= sub {
#     @_
# };
# eh brauch ich ja doch nid bräucht ich eben nur wenn obige
# einzelnejedefunc ansatz verfolgt würde.

sub CheckSuccess {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; ####shit 'aha' eben wieder das WAS für ein error bitte. msg how.
    $reply
}
sub CheckSuccessAndEmptyness {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; #####dito
    (@$reply==1 and $$reply[0] eq "\n")
      or die "error: the command gave some (or none at all) output: ".Chj::singlequote::singlequote_many(@$reply);
}
sub CheckSuccessJoin {
    my ($reply,$code)=@_;
    $code == 0 or die "error"; #####dito
    my $cnt= join("",@$reply);
    chop($cnt) eq "\n" or die "??missing additional newline at end of content";
    $cnt
}

sub _Mk_remote_chdir {
    my ($path2cmd)=@_;
    sub {
	my $s=shift;
	my ($path)=@_;
	CheckSuccessAndEmptyness
	  ($s->remote_run_commandstring_with_statusreply
	   (&$path2cmd($path)));
    }
}

*remote_chdir=
  _Mk_remote_chdir(sub {
		       my ($path)=@_;
		       "cd $path"
		   });
*remote_chdir_safe=
  _Mk_remote_chdir(sub {
		       my ($path)=@_;
		       &$shellquoted("cd",$path)
		   });

sub ChopNL {
    my ($str)=@_;
    my $ch= chop($str);
    $ch eq "\n" or die "chopped character is not a newline: ".Chj::singlequote::singlequote_many($str,$ch);
    $str;
}

*remote_get_cwd=
  sub {
      my $s=shift;
      ChopNL
	(CheckSuccessJoin
	 ($s->remote_run_commandstring_with_statusreply
	  ("pwd -P")));
  };

# sub new {
#     my $class=shift;
#     my $s= $class->SUPER::new;
#     (@$s[])=@_;
#     $s
# }

#sub DESTROY {
#    my $s=shift;
#    local $@;
#    # ç rausschmeissen wenn nicht benutzt, ebenso wie sub new
#    $s->SUPER::DESTROY;
#}

end Class::Array;
