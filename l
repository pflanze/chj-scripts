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

my $dir = do {
    if (@ARGV == 0) {
        "."
    } elsif (@ARGV == 1) {
        my $path = $ARGV[0];
        if (not($path =~ /^-/)
            and
            ! -l $path
            and
            -d _
            ) {
            $path
        } else {
            undef
        }
    } else {
        undef
    }
};

my $tail = $ENV{TAIL} // 20;

my @cmd = do {
    if (defined $dir) {
        my @tail = $do_tail ? ("tail", $tail) : ();
        ('lst', '--ls', $dir, '--ignore-item-regex', '^\.', '--ignore-item-regex', '~$', $list_opts, @tail)
    } else {
        my @cmd = ('/opt/chj/bin/ls', $list_opts, '--time-style=long-iso', @ARGV);
        if ($do_tail) {
            my ($tail_str) = $tail =~ /^(\d+)\z/ or die "invalid TAIL string '$tail'";
            require Chj::singlequote;
            my $cmd1 = join " ", map { Chj::singlequote::singlequote_sh($_) } @cmd;
            ("bash", "-c", "$cmd1 --color=always | tail -$tail_str")
        } else {
            @cmd
        }
    }
};

exec(@cmd) || exit(127);
