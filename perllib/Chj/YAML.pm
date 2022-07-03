# Sat Mar  1 23:54:37 2008  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2008 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::YAML

=head1 SYNOPSIS

=head1 DESCRIPTION

Proxy module for YAML and YAML::Syck (try to load the latter, fall
back to the former if that fails).

Additionally provide UTF8LoadFile; also provide both variants of these
separately as UTF8LoadFile_syck and UTF8LoadFile_yamlpm.

=cut


package Chj::YAML;

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

*UTF8LoadFile_syck= do {
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

*UTF8LoadFile_yamlpm= do {
    my $s= sub ( $ ) {
	my ($path)=@_;
	open my $in, "<:utf8", $path
	  or die "UTF8LoadFile: could not open '$path': $!";
	my $res= [ YAML::LoadFile($in) ];
	close $in or die "UTF8LoadFile: closing input '$path': $!"; # yes we check for errors, unlike either YAML.pm nor YAML::Syck!
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

*UTF8LoadFile= $using_syck ? \&UTF8LoadFile_syck : \&UTF8LoadFile_yamlpm;

*DumpFile= $using_syck ? \&YAML::Syck::DumpFile : \&YAML::DumpFile;

sub UTF8DumpFile ( $ $ ) {
    # to following the "same" interface as UTF8LoadFile, take exactly
    # 1 data argument
    @_==2 or die;
    #[does it require an additional copy versus just accessing @_? but
    #I don't care right now.]
    my ($file,$data)=@_;
    ###is this correct??  and does it throw exceptions?:
    DumpFile($file,@$data)
      or die "didn't get true";#
}

my $exports=
  {
   UTF8LoadFile=> \&UTF8LoadFile,
   UTF8LoadFile_yamlpm=> \&UTF8LoadFile_yamlpm,
   UTF8LoadFile_syck=> \&UTF8LoadFile_syck,
   UTF8DumpFile=> \&UTF8DumpFile,
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
