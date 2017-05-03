#!/bin/bash

set -eu

# Look at $EDITOR ? No, that one should be set to 'e' (for calling
# 'r') in any case? So instead just look at what's installed etc.

if which xemacs > /dev/null; then
    exec r _e "$@"
elif which xemacs21 > /dev/null; then
    exec r _e "$@"
elif [[ -n ${DISPLAY-} ]]; then
    exec E "$@"
else
    exec r emacs "$@"
fi
