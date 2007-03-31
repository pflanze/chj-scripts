# Mon Nov  1 21:18:46 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Vserver::Status

=head1 SYNOPSIS

 my $s= $v->status;
 print $s->context; ## or  $s->ctxid; or ->s_context ?
 print $s->status; # running  or  ?
 print $s->processes; # number of processes
 print $s->uptime; # uptime

 etc.

=head1 DESCRIPTION


=head1 SEE ALSO

L<Chj::Vserver>, L<Chj::Vserver::Status_cmd_base>

=cut


package Chj::Vserver::Status;
use strict;
use Carp;#ps das poisened meinen method name space! wenn mir das bewusst wär

use Chj::Vserver::Status_cmd_base -extend=>
  -pub=>
  'context', # number
  'status', # string  ((symbol wäre richtig?  oder identity objects  ))
  'processes',
  'uptime',
  ;

sub new {
    my $cl=shift;
    my ($name)=@_;
    my $s= $cl->SUPER::new($name,"status");
    #return unless $$s[Cmdexitcode]==0;# do not return object at all in this case. do not throw exception either. hmm? no. return undef only if vserver with given name does not exist.
    if ($$s[Cmdexitcode] != 0 and $$s[Cmddata]=~ /make sure that the vserver configuration/) {
	return;
    }
    $$s[Cmddata]=~ /^Vserver \'([^\']*)\'(?: is (\S+)(?: at context [^\d]*(\d+))?)?/i
      or confess "unsuccessful parsing";
    my $nameagain;
    ($nameagain, @$s[Status,Context])= ($1,$2,$3);
    #use Data::Dumper;
    #warn Dumper $s;
    if ($$s[Status]) {
	if ($$s[Status] eq "not") {#och wieder mal hatte mich $$[X] gebissen
	    $$s[Status] = "not_running";
	}
    }
    if ($$s[Cmddata]=~ /^Number of processes[^\d\n]*(\d+)/mi) {
	$$s[Processes]= $1;
    }
    if ($$s[Cmddata]=~ /^Uptime[^\d\n]*(\d+)/mi) {
	$$s[Uptime]= $1;
    }
    $s
}


sub running {
    my $s=shift;
    $s->[Status] and $s->[Status] eq 'running'
}


end Class::Array;
