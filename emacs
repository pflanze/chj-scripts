#!/bin/bash

# cj Wed, 16 Aug 2006 01:56:27 +0200

# increase the ulimit   (todo only if smaller?)
ulimit -S -v 200000

/usr/bin/emacs "$@"
