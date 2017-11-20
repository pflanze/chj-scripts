#!/bin/bash

exec ls --color=auto -b -lrt -I '*~' --time-style=long-iso "$@"
