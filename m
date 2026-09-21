#!/bin/bash
set -euo pipefail
IFS=

if [ -e Makefile ]; then
    CORECOUNT=${CORECOUNT-$(corecount)}
    exec make -j"$CORECOUNT" "$@"
else
    exec cargo build "$@"
fi
