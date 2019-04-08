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

# Specification of options:
our @optionspec=
  # [option_names, arity, helptext_or_sub, maybe_subforretrieval]
  (
   [verbose=> 0,
    "be verbose"],
   [help=> 0,
    undef],
   ["no-run-if-empty"=> 0,
    "do not run if stdin doesn't deliver any items"],
   ["run-if-empty" => 0,
    "inverse of --no-run-if-empty", sub {
	 my ($options)=@_;
	 sub {
	     $$options{'no-run-if-empty'}=0
	 }
     }],
   ["null|0|z"=> 0,
    "split stdin on \\0 instead of \\n"],
   ["num-parallel"=> 1,
    sub {
	my $n = $_[0] // 1;
	"number of processes to run in parallel, default $n"
    }]
  );



sub usage ($) {
    my ($options)= @_;
    print "$myname cmd [static args]

  Read stdin and add it's records to the arguments of cmd, and run cmd.
  Runs cmd at most once.

  Options:
".join("",
       map{
	   my ($name,$desc)= @$_;
	   $desc ? "  --$name  $desc\n" : ""
       }
       map{
	   my ($key, $arity, $doc, $maybe_retrieval)= @$_;
	   [$key, ref($doc) ? $doc->($$options{$key}) : $doc]
       }
       @optionspec
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


sub MyGetOptions ($) {
    # Read options from ARGV, only up to the first non-option
    # argument; use optionspec (see description of @optionspec) to
    # know the arity of options. Returns a hash with key/value for the
    # options (where the part of the key before the first '|' (if any)
    # is used as the key), removes those options from @ARGV. Or
    # returns undef upon error (in which case a message was already
    # printed by GetOptions which is used underneath).
    my ($optionspec)= @_;

    my $optionarity= do {
	my %os;
	for (@$optionspec) {
	    my ($key, $arity, $doc, $maybe_retrieval)= @$_;
	    my @key= split /\|/, $key;
	    for (@key) {
		$os{$_}= $arity
	    }
	}
	\%os
    };

    my @argv1;
    while (@ARGV) {
	my $v= shift @ARGV;
	if ($v eq "--") {
	    last;
	} elsif (my ($key,$maybe_val)=
		 $v=~ /^--?(\w[^=]+)(?:=(.*))?\z/s) {
	    push @argv1, $v;
	    my $arity= $$optionarity{$key};
	    if (defined $arity) {
		for (1..$arity) {
		    push @argv1, shift @ARGV;
		}
	    } else {
		die "unknown option: $v"; #XX proper message?
	    }
	} else {
	    unshift @ARGV, $v; # hacky
	    last;
	}
    }
    my @argv2=@ARGV;
    @ARGV=@argv1;

    # convert optionspec to something GetOptions understands:
    my %options;
    my @getoptargs=
      map {
	  my ($key, $arity, $doc, $maybe_retrieval)= @$_;
	  # save as the first entry in key
	  my ($optionkey)= $key=~ /^([^|]+)/ or die;
	  # prepare slot to pass as a reference
	  $options{$optionkey}= undef;
	  # value for GetOptions:
	  my $storage= ($maybe_retrieval ? &$maybe_retrieval(\%options)
			: \($options{$optionkey}));
	  # need to indicate arity to GetOptions:
	  if ($arity==0) {
	      # noop
	  } elsif ($arity == 1) {
	      $key.= "=s"
	  } else {
	      die "arity > 1 not supported by GetOptions, right?"
	  }
	  ($key, $storage)
      } @$optionspec;

    my $res= GetOptions(@getoptargs);
    return undef unless $res;
    die "??" if @ARGV;
    @ARGV=@argv2;
    \%options
}

#use Chj::Backtrace;
sub options_and_cmd {
    my ($maybe_optiondefaults)=@_;
    # optiondefaults are *values* for options, which are overridden by
    # what's read from ARGV.
    my $optiondefaults= $maybe_optiondefaults || {};

    my $options1= MyGetOptions(\@optionspec)
      or exit 1;

    my $options= Hash_addnew($optiondefaults, $options1);

    usage $options
      if ($$options{help} or !@ARGV);

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
	my $ex= sub {
	    my ($args)=@_;
	    do {
		no warnings;
		exec @$cmd,@$args
	    } or do {
		my $err="$!";
		require Chj::singlequote;
		die ("$myname: could not exec "
		     .Chj::singlequote::singlequote_many(@$cmd)
		     ." with "
		     .@$args." additional arguments of total size $tot_size: $err\n");
	    }
	};
	my $npar= $$options{"num-parallel"} || 1;  $npar >= 1 or die;
	if ($npar == 1) {
	    &$ex (\@args)
	} else {
	    # split args. or, how ? .
	    # yeah in the interest to make few calls? well. for now.
	    # totally randomize or what ?
	    # yeah maybe
	    my @argss;
	    while (@args) {
		my $i= int(rand() * $npar); # parens after rand required!
		push @{$argss[$i]}, pop @args;
	    }
	    # (well that's not totally randomized, 'partial
	    # sequencing' still observed, wl.)
	    my $subex= sub {
		my ($args)=@_;
		my $pid= fork;
		defined $pid or die "fork: $!";
		if ($pid) {
		    $pid
		} else {
		    if (@$args) { ##  check for no-run-if-empty? probably not ?
			&$ex($args)
		    } else {
			exit 0
		    }
		}
	    };
	    my @ps= map { &$subex ($_||[]) } @argss;
	    # ||[] needed or it will fail with 'Can't use an undefined
	    # value as an ARRAY reference'. Perl Perl Perl.
	    my @ss= map {
		waitpid ($_, 0) == $_ or die "??";
		$?
	    } @ps;
	    my $excode=0;
	    for (@ss) {
		if ($_ != 0) {
		    require Chj::Unix::exitcode;
		    warn "$myname: one of the subprocesses returned with "
		      .Chj::Unix::exitcode($_)."\n";
		    $excode=1;
		}
	    }
	    exit $excode
	}
    }
}

#use Chj::ruse;
#use Chj::Backtrace; use Chj::repl; repl;

1
