#!/bin/sh
set -e
cd
git init
git remote add origin https://github.com/jjo/config
git fetch
git reset origin/master
git checkout -f
