#
# Copyright 2012 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Ssh_config

=head1 SYNOPSIS

 my $c= ssh_config_parse_path "/etc/ssh/ssh_config"
 ssh_cfg_ref $c, "foo", "host", sub { 'notfound' }
 # => notfound
 ssh_cfg_ref $c, "foo", "hosTname", sub { 'notfound' }
 # => 1.2.3.4

=head1 DESCRIPTION

I've seen
http://search.cpan.org/~ddumont/Config-Model-2.023/lib/Config/Model.pm,
but decided to roll my own. (Why? Mass of dependencies of the Debian
package, unclear how to use just for parsing, why is the parser not
separate (is it?). Roll my own KISS.)

=cut


package Chj::Parse::Ssh_config;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 ssh_config_parse_fh
		 ssh_config_parse_path
		 ssh_cfg_ref
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# Line based. 'host' introduces new host context. There are global
# settings that act across host contexts, thus keep a global settings
# object with persistent updates.

##XX ACH  '     For each parameter, the first obtained value will be used.'


use Chj::FP::Alist;
use Chj::FP::List;
use Chj::xopen 'xopen_read';

sub ssh_config_parse_fh {
    my ($fh)=@_;
    my $hostentries= empty_alist; # host => directives-alist
    my $current_host="*"; # XX correct? Does it start off for that context?
    my $current_directives= empty_alist;
    my $close_host= sub {
	$hostentries= alist_add
	  ($hostentries, $current_host, list_reverse($current_directives));
    };
    while (<$fh>) {
	chomp;
	# "Empty lines and lines starting with '#' are comments."
	next if /^\s*$/;
	# A line starting with whitespace then '#' is assumed to fit
	# the above rule, too.
	next if /^\s*#/; #
	# "Configuration options may be separated by whitespace or
	# optional whitespace and exactly one '='"
	if (/^\s*(\w+)\s*(?:=\s*)?(.*?)\s*$/) {
	    my ($_key,$rest)=($1,$2);
	    my $key= lc $_key;
	    if ($key eq 'host') {
		&$close_host;
		$current_directives= empty_alist;
		$rest=~ /^(\S+)$/s
		  or die "seems like invalid host directive value: '$rest'";
		# XXX: oh yeah and remove double quotes around it?
		$current_host= $1;
	    } else {
		$current_directives= alist_add ($current_directives, $key, $rest);
	    }
	} else {
	    warn "can't parse line: '$_'";
	}
    }
    &$close_host;
    list_reverse $hostentries
}

sub ssh_config_parse_path ($ ) {
    my ($path)=@_;
    my $f= xopen_read $path;
    my $res= ssh_config_parse_fh($f);
    $f->xclose;
    $res
}

use Chj::callcc2;

sub ssh_cfg_ref ($ $ $ $ ) {
    my ($cfg, $hostname, $directivename, $notfound)=@_;
    # XXX:  ip matching hmm not done at all.
    # XXX: glob matching, hmmm. not done either
    # Just hostname eq matching and matching '*' for now.
    callcc sub {
	my ($return)=@_;
	list_for_each
	  (sub {
	       my ($p)=@_;
	       my ($host,$directives)= ($p->car, $p->cdr);
	       if ($host eq '*'
		   or
		   lc($hostname) eq lc($host)) {
		   list_for_each
		     (sub {
			  my ($p)=@_;
			  my ($directive,$rest)= ($p->car, $p->cdr);
			  if (lc($directivename) eq $directive) {
			      &$return($rest)
			  }
		      },
		      $directives);
	       }
	   },
	   $cfg
	  );
	&$notfound
    };
}


1

__END__
TEST
calc> :l $c= ssh_config_parse_path "/etc/ssh/ssh_config"
calc> :l ssh_cfg_ref $c, "foo", "host", sub { 'notfound' }
notfound
calc> :l ssh_cfg_ref $c, "foo", "hostname", sub { 'notfound' }
1.2.3.4
calc> :l ssh_cfg_ref $c, "foo", "hosTname", sub { 'notfound' }
1.2.3.4
