# My collection of random scripts

## Installation

### Via chjize

If you're on Debian (or perhaps derivative),
[chjize](https://github.com/pflanze/chjize) makes installation of this
library easy. Follow its own installation instructions, then:

    chjize chj-scripts

### Manually

(In all repositories there may be a signed tag every now and
then. Feel free to check with `git tag -v $tagname`.)

As root:

    cd /opt
    git clone https://github.com/pflanze/functional-perl.git
    cd functional-perl
    # follow instructions in README.md to check fingerprint
    perl Makefile.PL && make install
    cd /opt
    git clone https://github.com/pflanze/chj-scripts.git
    ln -s /opt/chj-scripts/perllib/Chj /etc/perl/
    mkdir /etc/perl/Class
    ln -s /opt/chj-scripts/perllib/Class/Array.pm /etc/perl/Class

Optionally, get the files from
[chj-home](https://github.com/pflanze/chj-home), which will set up the
`PATH` env var to find the scripts. Alternatively just add
`/opt/chj-scripts/bin` to your `PATH` environment variable yourself.

The process for that would be:

    cd
    git clone https://github.com/pflanze/chj-home
    mv chj-home/.git .
    rm -rf chj-home

Now run `git status` and/or `git diff` to verify that you're not
overwriting any files you want to keep. If you're sure you don't lose
anything (otherwise consider running `git commit -a -m mystuff`, `git
branch mystuff`, `git reset HEAD^` then proceeding)

    git reset --hard
    lesskey

### Packaging

There is some unfinished support for packaging, see
[packaging](packaging.md).

