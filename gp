#!/bin/bash

set -eu

cb=$(cj-git-current-branch)

git push --tags "${GP_REMOTE-t3}" "$cb"
