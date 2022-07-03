# My collection of random scripts

## Installation

### Via chjize

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
    mkdir chj
    cd chj
    git clone https://github.com/pflanze/chj-scripts.git bin
    git clone https://github.com/pflanze/chj-perllib.git perllib
    ln -s /opt/chj/perllib/Chj /etc/perl/
    mkdir /etc/perl/Class
    ln -s /opt/chj/perllib/Class/Array.pm /etc/perl/Class

Optional (alternatively just add /opt/chj/chj-scripts/bin into your PATH
environment variable):

As root:

    cd
    git clone https://github.com/pflanze/chj-root.git .
    mv chj-root/.git .
    rm -rf chj-root

Now run `git status` and/or `git diff` to verify that you're not
overwriting any files you want to keep. If you're sure you don't lose
anything (otherwise consider running `git commit -a -m mystuff`, `git
branch mystuff`, `git reset HEAD^` then proceeding)

    git reset --hard
    lesskey

As normal user:

    cd
    git clone https://github.com/pflanze/chj-home-chris.git
    mv chj-home-chris/.git .
    rm -rf chj-home-chris

And again check that you don't kill any files/changes you want to
keep, before running:

    git reset --hard
    lesskey

### Packaging

There is some unfinished support for packaging, see
[packaging](docs/packaging.md).

