#!/bin/bash

set -eu

# Look at $EDITOR ? No, that one should be set to 'e' (for calling
# 'r') in any case? So instead just look at what's installed etc.

flavour=${EMACS_FLAVOUR-}

if [[ "$flavour" = "" ]]; then
    if which xemacs > /dev/null; then
	flavour=xemacs
    elif which xemacs21 > /dev/null; then
	flavour=xemacs
    else
	flavour=emacs
    fi
fi

if [[ "$flavour" = "xemacs" ]]; then
    exec r _e "$@"
    # XX btw security re options ? !

elif [[ "$flavour" = "emacs" ]]; then
    if [[ -n ${DISPLAY-} ]]; then
	exec r _e-gnu-multiarg "$@"
    else
	exec r "${EMACS_ALTERNATE_EDITOR-emacs}" "$@"
    fi

else
    echo "$0: unknown flavour '$flavour', set \$EMACS_FLAVOUR to either xemacs or emacs or leave it unset or empty, please"
fi
