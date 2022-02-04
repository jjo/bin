#!/bin/bash
AWK=awk
case $(uname -s) in
    Darwin) AWS=gawk;;
esac
which "${AWK}" >/dev/null|| exit 1
HOSTS=${*:?"
Usage:
  ${0##*/} host1 host2 | sponge ~/.zsh_history"}
printf "%s\n" ${HOSTS}| xargs -rI@ ssh @ cat .zsh_history  | \
    "${AWK}" -v date="WILL_NOT_APPEAR$(date +"%s")" '{if (sub(/\\$/,date)) printf "%s", $0; else print $0}' | \
    LC_ALL=C sort -u | \
    "${AWK}" -v date="WILL_NOT_APPEAR$(date +"%s")" '{gsub('date',"\\\n"); print $0}'
