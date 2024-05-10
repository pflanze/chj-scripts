#!/bin/bash
set -meuo pipefail
IFS=

if [ -e Makefile ]; then
    exec make -j16 "$@"
else
    exec cargo build "$@"
fi
