#!/bin/bash
set -meuo pipefail
IFS=

if [ -e Makefile ]; then
    exec make -j16 test "$@"
else
    exec cargo test "$@"
fi
