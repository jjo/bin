#!/bin/bash -x
URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/player.js|sed -rn 's,\\,,g;/video-link/s/.*(http[^"]+)".*/\1/p')
echo "URL=$URL"
extra=""
if [[ "$1" == --save ]];then
    extra="--sout #std{access=file,mux=raw,dst=$2}"
fi
set -x
exec cvlc $extra "$URL"
