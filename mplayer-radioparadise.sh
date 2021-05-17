#!/bin/sh
stream=aac-
qual=320
while [ $# -gt 0 ]; do
    case "$1" in
        -rock|-mellow|-eclectic|-world) stream=${1#-}-; shift;;
        -64|-128|-320) qual=${1#-}; shift;;
        -flac) qual=${1#-}; shift;;
        *) break;;
    esac
done
# Particular case :/ ->
[ ${stream}${qual} = "aac-flac" ] && stream=""
set -x
case $(uname -s) in
    Darwin) exec vlc -I ncurses "$@" http://stream.radioparadise.com/${stream}${qual};;
    *) exec mplayer -prefer-ipv4 -cache 256 "$@" http://stream.radioparadise.com/${stream}${qual};;
esac
