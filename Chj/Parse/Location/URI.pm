# Sun Oct 21 20:50:41 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Location::URI

=head1 SYNOPSIS

=head1 DESCRIPTION

Also provide parsing for nonusual uris like ssh:// or rsync://

=cut


package Chj::Parse::Location::URI;

use strict;

use URI;
use Chj::FP::lazy qw(Delay Force);

use Class::Array -fields=>
  -publica=>
  'uri', # URI object.
  # caches:
  '_didcalculate', # bool
  'user',
  'host',
  'port',
  'path',
  ;


sub new {
    my $class=shift;
    my ($uri_object_or_string)=@_;
    my $s= $class->SUPER::new;
    ($$s[Uri])=
      ref ($uri_object_or_string) ?
	$uri_object_or_string :
	  URI->new($uri_object_or_string);
    $s
}

sub scheme {
    my $s=shift;
    $$s[Uri]->scheme
}

sub do_calculate {
    my $s=shift;
    my $uri= $$s[Uri];
    my $authorityvalues= Delay {
	my $authority= $uri->authority;
	my %res;
	($res{maybeuser},
	 $res{host},
	 $res{maybeport})
	  = $authority=~ /^(?:(\w+)\@)?(.*?)(?::(\d+))?\z/
	    or die "authority does not match expected pattern: '$authority'";
	\%res
    };
    my $calculate= sub {
	my ($field,$methodname,$maybe_authorityvalues_field)=@_;
	$$s[$field] ||= do {
	    if (my $m= $uri->can($methodname)) {
		$m->($uri);
	    } else {
		if ($maybe_authorityvalues_field) {
		    Force($authorityvalues)->{$maybe_authorityvalues_field}
		} else {
		    undef
		}
	    }
	}
    };
    $calculate->(User,"user","maybeuser");
    $calculate->(Host,"host","host");
    $calculate->(Port,"port","maybeport");
    $calculate->(Path,"path");
}

sub _MkCalculate {
    my ($field)=@_;
    sub {
	my $s=shift;
	if (!$$s[_Didcalculate]) {
	    $s->do_calculate;
	    $$s[_Didcalculate]=1;
	}
	$$s[$field]
    }
}

*user= _MkCalculate (User);
*host= _MkCalculate (Host);
*port= _MkCalculate (Port);
*path= _MkCalculate (Path);


end Class::Array;

__END__

  tests:

chris@lombi chris > calc -MChj::Parse::Location::URI
calc> :l $u= Chj::Parse::Location::URI->new("ssh://e5/sum");
Chj::Parse::Location::URI=ARRAY(0x10372470)
calc> :l $u->host
e5
calc> :l $u->user

calc> :l $u->port

calc> :l $u->path
/sum
calc> :l $u= Chj::Parse::Location::URI->new('ssh://chris@e5:2111');
Chj::Parse::Location::URI=ARRAY(0x103932ac)
calc> :l $u->user
chris
calc> :l $u->port
2111
calc> :l $u->host
e5
calc> :l $u->path

calc> :l $u= Chj::Parse::Location::URI->new('ssh://chris@e5:2111/'); 
Chj::Parse::Location::URI=ARRAY(0x10397044)
calc> :l $u->path
/

