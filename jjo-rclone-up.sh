#!/bin/bash
X="--exclude=.dropbox**"
set -x
printf "%s\n" jjo-pcloud:Dropbox/ jjo-dropbox:/ | xargs -tI{} -P99 rclone sync --skip-links -v ${X} "${@}" ~/Dropbox/ {}
