#!/bin/bash

set -euo pipefail
IFS=

usage () {
    {
    echo "Usage: \$($(basename "$0") prog args..)"
    echo "    Similar to 'lambda' but allows to create a command that
    just consists of a tail call to the given prog and args (simpler,
    avoids the need to shell quote arguments)

    Also see: lambda, inplace"
    } >& 2
    false
}

if [ $# -eq 0 ]; then
    usage
fi


tmp=`tempfile`

{
    echo -n '#!/bin/bash
set -eu
exec --'

    for arg in "$@"; do
        printf ' %q' "$arg"
    done
    echo
} >> "$tmp"

chmod +x "$tmp"

echo "$tmp"
