# Sat Mar  1 23:54:37 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

SP::YAML

=head1 SYNOPSIS

=head1 DESCRIPTION

Proxy module for YAML and YAML::Syck (try to load the latter, fall
back to the former if that fails).

Additionally provide UTFLoadFile; also provide both variants of these
separately as UTFLoadFile_syck and UTFLoadFile_yamlpm.

=cut


package SP::YAML;

use strict;

our ($using_syck, $original_import, $original_class);

eval {
    require YAML::Syck;
    $using_syck=1;
};
if (ref $@ or $@) {
    require YAML;
    warn "note: YAML::Syck not installed, falling back to YAML.pm";
}

# *LoadFile= $using_syck ?
#   *YAML::Syck::LoadFile :
#     *YAML::LoadFile;

$original_class=
  ($using_syck ? "YAML::Syck" : "YAML");
$original_import=
  $original_class->can("import")
    or die "??";

*UTFLoadFile_syck= do {
    my $s= sub ( $ ) {
	local $YAML::Syck::ImplicitUnicode=1;
	[ YAML::Syck::LoadFile($_[0]) ]
    };
    my $init= sub {
	$YAML::Syck::ImplicitUnicode=$YAML::Syck::ImplicitUnicode; #avoid warning, grr.
    };
    if ($using_syck) {
	&$init;
	$s
    } else {
	my $inited;
	sub ( $ ) {
	    unless ($inited) {
		require YAML::Syck;
		&$init;
		$inited=1;
	    }
	    goto $s
	}
    }
};

*UTFLoadFile_yamlpm= do {
    my $s= sub ( $ ) {
	my ($path)=@_;
	open my $in, "<:utf8", $path
	  or die "UTFLoadFile: could not open '$path': $!";
	my $res= [ YAML::LoadFile($in) ];
	close $in or die "UTFLoadFile: closing input '$path': $!"; # yes we check for errors, unlike either YAML.pm nor YAML::Syck!
	$res
    };
    if ($using_syck) {
	my $inited;
	sub ( $ ) {
	    unless ($inited) {
		require YAML;
		$inited=1;
	    }
	    goto $s
	}
    } else {
	$s
    }
};

*UTFLoadFile= $using_syck ? \&UTFLoadFile_syck : \&UTFLoadFile_yamlpm;

my $exports=
  {
   UTFLoadFile=> \&UTFLoadFile,
   UTFLoadFile_yamlpm=> \&UTFLoadFile_yamlpm,
   UTFLoadFile_syck=> \&UTFLoadFile_syck,
  };

sub import {
    my $class=shift;
    my @remaining;
    my $caller=caller;
    for (@_) {
	if (my $c= $$exports{$_}) {
	    no strict "refs";
	    *{$caller."::$_"}= $c;
	} else {
	    push @remaining,$_
	}
    }
    if (@remaining) {
	@_=($original_class,@remaining);
	goto $original_import;
    }
}



1
