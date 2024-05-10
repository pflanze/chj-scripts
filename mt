#!/bin/bash
set -meuo pipefail
IFS=

if [ -e Makefile ]; then
    CORECOUNT=${CORECOUNT-$(corecount)}
    exec make -j"$CORECOUNT" test "$@"
else
    exec cargo test "$@"
fi
