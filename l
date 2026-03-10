#!/usr/bin/perl -w

use strict;

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

my @cmd = do {
    if (defined $dir) {
        ('lst', '--ls-dir', $dir, '--ignore', '^\.', '--ignore', '~$', '-lrt')
    } else {
        ('/opt/chj/bin/ls', '-lrt', '--time-style=long-iso', @ARGV)
    }
};

exec(@cmd) || exit(127);
