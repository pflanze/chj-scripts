# Fri Jun 27 17:13:48 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::FileExcluder

=head1 SYNOPSIS

 use Chj::Util::FileExcluder;
 my $excluder= new Chj::Util::FileExcluder "some/excludefile";
 $excluder->verbose(1);
 if (! $excluder->match("/some/path/somefile","somefile")) {
    # do something with this item
 }

=head1 DESCRIPTION

Currently only does matches on the full path, or on the filename if no
slash is present in the corresponding line of the config file.

match(fullpath,itemname) extracts the itemname itself from the
fullpath if it is not given.

=head1 IMPORTANT

The fullpath given to match must not contain multiple adjacent
slashes, and should be a realpath (i.e. not contain "../" or "./") or
from a guaranteed base, so that it will correctly detect
matches. L<Chj::Cwd::realpath> for one way to ensure this. For
performance reasons match() does not do cleanups.

=head1 BUGS

Should really be called PathExcluder, arghhh.

=cut


package Chj::Util::FileExcluder;

use strict;
use Carp;
use Chj::xopen;

use Class::Array -fields=> (
			    "ExclPath",
			    "ExclItem",
			    "Verbose",
			   );


# functions:
sub cleanpath {
    my ($path)=@_;
    # do not resolve ../ stuff yet
    $path=~ s|^\s*||s; $path=~ s|\s*\z||s; # gobble whitespace  /;
    $path=~ s/\/*$//s; # no trailing slashes.;/;
    $path=~ s|/+|/|sg;
    $path
}

# methods:

sub new {
    my $class=shift;
    my ($configfile)=@_;
    my $self= $class->SUPER::new(@_);
    my $f= xopen "<", $configfile;
    my (%excludepath,%excludeitem);
    while(defined(my$line=$f->xreadline)){
        chomp $line;
        next if $line=~ /^\s*\#/ or $line=~ /^\s*\z/s;
        $line= cleanpath($line);
        if ($line=~ /\//) {
            $excludepath{$line}++;
        } else {
            $excludeitem{$line}++;
        }
    }
    @$self[ExclPath,ExclItem]= (\%excludepath,\%excludeitem);
    $self
}

sub match {
    my $self=shift;
    my ($path,$item)=@_;
    if (!defined $item){
	$path=~ m{([^/]*)\z} or die "???";
	$item= $1;
    }
    if (exists $$self[ExclItem]{$item}) {
	carp "excluding item '$item'" if $$self[Verbose];
	1
    } elsif (exists $$self[ExclPath]{$path}) {
	carp "excluding path '$path'" if $$self[Verbose];
	1
    } else {
	0
    }
}


sub verbose {
    my $self=shift;
    if(@_){
	($$self[Verbose])=@_;
    } else {
	$$self[Verbose]
    }
}


1;
