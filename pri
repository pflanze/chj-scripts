#!/bin/bash
set -meuo pipefail
IFS=

# XX replace --ignore with .gitignore awareness
PAGER_OPTS=-S exec ele priorities --ignore '\.(html|svg|png|jpe?g)$' "$@"
