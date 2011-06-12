#!/bin/bash

set -eu

g-push --tags ${GP_REMOTE-t3} $(cj-git-current-branchS)
