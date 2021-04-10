#!/bin/bash
DIR=${1:-}
test -n "${DIR}" && shift
X="--exclude=.dropbox**"
set -x
printf "%s\n" jjo-pcloud:Dropbox/${DIR} jjo-dropbox:/${DIR} | xargs -tI{} -P99 rclone sync --skip-links -v ${X} "${@}" ~/Dropbox/${DIR} {}
