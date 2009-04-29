#
# Copyright 2009 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Myxargs

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::App::Myxargs;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(options_and_cmd
	   myxargs);
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

(my $email='pflanze%gmx,ch')=~ tr/%,/@./;

use strict;

$0=~ /(.*?)([^\/]+)\z/s or die "?";
my ($mydir, $myname)=($1,$2);
sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname ..

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

use Getopt::Long;
use Chj::Collection 'Collection_addnew';
#use Chj::Backtrace;
sub options_and_cmd {
    my ($optiondefaults)=@_;
    $optiondefaults||={};
    # then set all options which haven't already
    #could possibly use Collection_add from  well actually do it.
    my $options;
    $options= #yes memleak, whatever.
      Collection_addnew
	($optiondefaults,
      +{
	verbose=>0,
	#"no-run-if-empty"=>0,
	help=> sub{usage}, # so that the option parser will see that during parsing,k?
	'run-if-empty'=> sub {
	    $$options{'no-run-if-empty'}=0
	},
       });
    GetOptions($options,
	       qw(verbose
		  help
		  no-run-if-empty
		  run-if-empty
		 ))
      or exit 1;
    usage unless @ARGV;
    #($options, [@ARGV]) well. rather?: well or not?
    [$options, [@ARGV]]
}

our $max_args= 1e6;##for now
our $max_size= 20e6;# bytes ##for now

sub myxargs { # global inputs (free variables.eben. und autodetect?..) : STDIN
    my ($_options_and_argv)=@_;
    my ($options, $cmd)=@$_options_and_argv;
    #my @args= @$argv; #so that I don't have to change the code below.well. well indented anyway so git will not find it anyway? well maybenot ?.
    #well but I have to change the code to use different options anyway. so. rite.
    #h GetOptions should take a cont,really....H (or, values to be applied) (well fun and we're back at bad matching scm apply.)
    #well actually @args is separate anyway and I'd have to have aliased it to @ARGV actually,wow.  wl actually name it $cmd now for that, better named ('speaking'), reason.
    my @args;
    my $tot_size=0; #initialize it!!
    while (<STDIN>) {
	if (@args >= $max_args) {
	    die "$myname: input exceeds maximum number of arguments ($max_args)\n";
	}
	chomp;
	$tot_size+=length($_);
	if ($tot_size > $max_size) {
	    die "$myname: input exceeds maximum total length of arguments "
	      ."($max_size bytes)\n";
	}
	push @args,$_;
    }

    if (!$$options{"no-run-if-empty"} or @args) {
	do {
	    no warnings;
	    exec @$cmd,@args
	} or do {
	    my $err="$!";
	    require Chj::singlequote;
	    die ("$myname: could not exec "
		 .Chj::singlequote::singlequote_many(@$cmd)
		 ." with "
		 .@args." additional arguments of total size $tot_size: $err\n");
	}
    }
}

#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;

1
