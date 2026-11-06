#!/usr/bin/perl -w

use strict;

my ($mydir, $myname);
BEGIN {
    $0=~ /(.*?)([^\/]+)\z/s or die "?";
    ($mydir, $myname)=($1,$2);
}

my $list_opts = do {
    if ($myname eq "l") {
        '-lrt'
    } elsif ($myname eq "lt") {
        '-lrt'
    } elsif ($myname eq "ll") {
        '-l'
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


my @cmd = do {
    if (defined $dir) {
        ('lst', '--ls', $dir, '--ignore-item-regex', '^\.', '--ignore-item-regex', '~$', $list_opts)
    } else {
        ('/opt/chj/bin/ls', $list_opts, '--time-style=long-iso', @ARGV)
    }
};

exec(@cmd) || exit(127);
