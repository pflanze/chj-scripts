#!/bin/bash

exec ls --color=auto -lrt -I '*~' --time-style=long-iso --quoting-style=literal "$@"
