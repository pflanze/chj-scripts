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

our $optionspec=
  +{
    verbose=> "be verbose",
    help=> undef,
    "no-run-if-empty"=> "do not run if stdin doesn't deliver any items",
    "run-if-empty" => "inverse of --no-run-if-empty",
    "null|0|z"=> "split stdin on \\0 instead of \\n", #wow that's cool, that | thingie. for here.same way usable.
   };
#^ well sort of dumb idea since ordering will be lost  but  i  do not care now.

sub usage {
    print STDERR map{"$_\n"} @_ if @_;
    print "$myname cmd [static args]

  Read stdin and add it's records to the arguments of cmd, and run cmd.
  Runs cmd at most once.

  Options:
".join("",
       map{my ($name,$desc)=@$_;
	   $desc ? "  --$name  $desc\n" : ""}
       map{my $key=$_; [$key,$$optionspec{$key}]} sort keys %$optionspec
      )."

  (Christian Jaeger <$email>)
";
exit (@_ ? 1 : 0);
}

use Getopt::Long;

sub Hash_addnew ( $ $ ) {
    my ($a,$b)=@_;
    my $res=+{%$a};
    for my $key (keys %$b) {
	if (not exists $$res{$key}) {
	    $$res{$key}=$$b{$key}
	}
    }
    $res
}


sub MyGetOptions {
    # only accept options up to the first argument not starting with a dash. or so.
    # well ugly wegen argtaking options.
    # well luckily we don't have any of those here.hu.
    my @argv1;
    while (@ARGV) {
	my $v= shift @ARGV;
	if ($v eq "--") {
	    last;
	} elsif ($v=~ /^-/) {
	    push @argv1, $v;
	} else {
	    unshift @ARGV, $v; #'haha'  wl wsm
	    last;
	}
    }
    my @argv2=@ARGV;
    @ARGV=@argv1;
    my $res= GetOptions (@_);
    die "??" if @ARGV;
    @ARGV=@argv2;
    $res
}

#use Chj::Backtrace;
sub options_and_cmd {
    my ($maybe_optiondefaults)=@_;
    my $optiondefaults= $maybe_optiondefaults || {};
    # then set all options which haven't already
    #could possibly use Collection_add from  well actually do it.  well actually doesn't work, assumes key==value and acts as such for adding (hu~wl.y named it so)
    my $options;
    $options= #yes memleak, whatever.
      Hash_addnew
	($optiondefaults,
      +{
	verbose=>0,
	#"no-run-if-empty"=>0,
	help=> sub{usage}, # so that the option parser will see that during parsing,k?
	'run-if-empty'=> sub {
	    $$options{'no-run-if-empty'}=0
	},
       });
    MyGetOptions($options,
		 keys %$optionspec)
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
    local $/= $$options{null} ? "\0" : $/;
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
