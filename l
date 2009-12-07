#!/bin/bash

exec ls --color=auto -lrt -I '*~' "$@"
