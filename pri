#!/bin/bash
set -meuo pipefail
IFS=

PAGER_OPTS=-S exec ele priorities "$@"
