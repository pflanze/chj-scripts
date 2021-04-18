# Packaging

(Some of) the files have metainformation to allow them to be packaged
without including everything in chj-bin and its dependencies (a form
of tree shaking / dead code elimination). The metadata is incomplete,
patches are welcome.

[`packaging-get-key file Key`](../packaging-get-key) allows to
retrieve a metadata key. Example:

    # packaging-get-key xlastfile Depends
    (lastfile )
    # packaging-get-key trigger-listen Tags
    (ipc)

The values are lists of symbols in Scheme-compatible S-expression
format.

Dependencies on Perl modules in Perl code are not listed in
`Depends`. Instead, use [`packaging-perl-getdeps
file(s)`](../packaging-perl-getdeps) to retrieve them.

## Algorithm for finding all dependencies

Finding all dependencies for a set of files consists of:

 1. for each file, get the value associated with the `Depends`
    metadata key (and if not present in the file, add it there, and
    then please feed back the patch). As mentioned above, the
    `packaging-get-key` script can provide this.

 1. also for each file, check if it's a Perl file (look at the shebang
    line), if so, extract the Perl level dependencies (`use` and
    `require`). As mentioned above, the `packaging-perl-getdeps`
    script can provide these.

 1. recursively, find the dependencies of the files found via the two
    steps above, too.  Careful: `Depends` allows dependency circles
    (and Perl modules, too, even though that shouldn't happen), thus,
    avoid recursion on files that have already been processed.

 1. For each Perl module dependency, find out which package it comes
    from. You can use `perl-namespace2path` to get the file path
    corresponding to the namespace, check if it exists in
    `chj-perllib` (or `functional-perl` / `FunctionalPerl` from CPAN),
    if not, check via the system packaging system or CPAN where it can
    be found.

 1. Pack up the files from `chj-bin` (and `chj-perllib`, if that is
    not packaged separately) that are needed, specify a dependency on
    the other packages needed.

### (Partial) usage example:

    $ cd /opt/chj/perllib
    $ t=$(mktemp)
    $ perl-getdeps Chj/Transform/Xml2Sexpr.pm Chj/xtmpfile.pm | perl-namespace2path > "$t"
    $ # Modules which are part of chj-perllib:
    $ filter $(C test -f _) < "$t" | perl-path2namespace --no-use
    Chj::IO::Tempfile
    Chj::schemestring
    Chj::xtmpfile
    $ # Modules which are *not* part of chj-perllib:
    $ filter $(C test '!' -f _) < "$t" | perl-path2namespace --no-use
    Exporter
    XML::LibXML
    strict

(Note that `strict` and `Exporter` are part of the Perl core.)
