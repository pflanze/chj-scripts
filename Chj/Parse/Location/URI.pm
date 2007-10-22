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

use Chj::Parse::Location -extend=>
  -publica=>
  'uri', # URI object.
  # caches:
  '_didcalculate', # bool
#   'user',
#   'host',
#   'port',
#   'path',
#now moved to abstract class. strange right?. caches there. whatever?.
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

#*is_valid= \&scheme;# good? nope. string 'foo:' would return scheme foo. but would in fact rather be a candidate for SSH locators.
sub is_valid {
    my $s=shift;
    my (@accepted_schemes)=@_;
    if (my $lcscheme= lc($s->scheme)) {
	for (@accepted_schemes) {
	    return $s->is_valid_in_scheme($lcscheme) if ($lcscheme eq lc($_));
	}
	()
    } else {
	()
    }
}

#sub is_safely_valid
# how to call it?
#sub is_
# but maybe I should check for ssh:// and so on anyway, above.

our $lcschemes_with_double_slashes=
  +{
    map { $_ => 1 } qw(http https ftp ssh rsync)  ## which others also ?
   };

sub is_valid_in_scheme { # contains knowledge about which schemes require double slashes
    my $s=shift;
    my ($lcscheme)=@_;
    if ($$lcschemes_with_double_slashes{$lcscheme}) {
	lc($$s[Uri]."")=~ m{^$lcscheme://}  ##am I not missing any uri feature which could invalidate this assumption?
    } else {
	# we don't know, assume that yes?
	2
    }
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
	  = $authority=~ /^(?:(\w+)\@)?(.*?)(?::(\d*))?\z/  ##NOTE that maybeport is being defined if authority is containing a colon but no digits afterwards!
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


sub path_is_shellcode {
    # no, for URI's, assume that the path is "lowlevel" (it must be quoted still before being passed to a shell)
    0
}

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

