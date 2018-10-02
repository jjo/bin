#!/bin/sh
set -e
cd
git init
git remote add origin https://github.com/jjo/config
git fetch
git reset origin/master
# Just in case I have valuable local changes
git stash
git checkout -f
