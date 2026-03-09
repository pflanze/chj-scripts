#!/bin/bash

if [ $# == 0 ]; then
    dir=.
elif [ $# == 1 ]; then
    if ! [[ "$1" =~ ^- ]]; then
        if [ -d "$1" ]; then
            dir=$1
        fi
    fi
fi

if [ -n "$dir" ]; then
    exec lst --ls-dir "$dir" --ignore '^\.' --ignore '~$' -lrt
else
    exec /opt/chj/bin/ls -lrt --time-style=long-iso "$@"
fi
