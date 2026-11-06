#!/usr/bin/perl -w

use strict;

my ($mydir, $myname);
BEGIN {
    $0=~ /(.*?)([^\/]+)\z/s or die "?";
    ($mydir, $myname)=($1,$2);
}

my ($list_opts, $do_tail) = do {
    if ($myname eq "l") {
        ('-lrt', 0)
    } elsif ($myname eq "lt") {
        ('-lrt', 1)
    } elsif ($myname eq "ll") {
        ('-l', 0)
    } else {
        die "unknown symlink name '$myname'"
    }
};

my @argv = @ARGV;
my $dir;
my $opt_fullpath = 0;

# whether to call traditional ls because it's ~too complicated to do with 'lst'
my $do_fallback = 0;

while (@argv) {
    my $arg = shift @argv;
    #warn "arg='$arg'";
    if ($arg eq "--") {
        if (!@argv) {
            last
        }
        if (!defined($dir) and @argv == 1) {
            ($dir) = @argv;
        } else {
            $do_fallback = 1;
        }
        last
    }
    if ($arg eq '--fullpath') {
        $opt_fullpath = 1;
        next;
    }
    if ($arg =~ /^-/) {
        $do_fallback = 1;
        last
    }
    if (!defined($dir) and (! -l $arg and -d _)) {
        $dir = $arg;
    } else {
        $do_fallback = 1;
        last
    }
}

my $tail = $ENV{TAIL} // 20;

my @cmd = do {
    if (!$do_fallback) {
        #warn "lst mode";
        $dir //= ".";
        my @tail = $do_tail ? ("tail", $tail) : ();
        my @fullpath = $opt_fullpath ? ("--fullpath") : ();
        ('lst', '--ls', $dir, '--ignore-item-regex', '^\.', '--ignore-item-regex', '~$', $list_opts, @fullpath, @tail)
    } else {
        # Note: this isn't always triggering since not all options
        # have been processed; just let ls pring an error in those
        # cases, meh.
        if ($opt_fullpath) {
            die "$myname: can't do both --fullpath and fallback because of unknown options or multiple paths"
        }
        # Note: this is inconsistent with `lst` case, should only do
        # it if our context requires it!
        my @color = $do_tail ? ("--color=always") : ();
        my @cmd = ('/opt/chj/bin/ls', @color, $list_opts, '--time-style=long-iso', @ARGV);
        if ($do_tail) {
            #warn "ls pipe mode";
            my ($tail_str) = $tail =~ /^(\d+)\z/ or die "invalid TAIL string '$tail'";
            require Chj::singlequote;
            my $cmd1 = join " ", map { Chj::singlequote::singlequote_sh($_) } @cmd;
            ("bash", "-c", "$cmd1 | tail -$tail_str")
        } else {
            #warn "ls mode";
            @cmd
        }
    }
};

#warn "cmd = ".join(" ", @cmd);
exec(@cmd) || exit(127);
