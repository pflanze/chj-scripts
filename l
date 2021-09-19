#!/bin/bash

exec ls --color=auto --hide-control-chars -lrt -I '*~' --time-style=long-iso --quoting-style=literal "$@"
