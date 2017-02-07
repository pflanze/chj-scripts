# My collection of random scripts

## Installation

(In all repositories there may be a signed tag every now and
then. Feel free to check with `git tag -v $tagname`.)

As root:

    cd /opt
    mkdir chj
    cd chj
    git clone https://github.com/pflanze/chj-bin.git bin
    git clone https://github.com/pflanze/chj-perllib.git perllib
    ln -s /opt/chj/perllib/Chj /etc/perl/
    mkdir /etc/perl/Class
    ln -s /opt/chj/perllib/Class/Array.pm /etc/perl/Class

Optional (alternatively just add /opt/chj/bin into your PATH
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

