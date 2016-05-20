#!/bin/bash -x
#URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/player.js|sed -rn 's,\\,,g;/video-link/s/.*(http[^"]+)".*/\1/p')
URL=$(wget -qO- www.mdzradio.com/player.php|egrep androidButton|sed -rn 's|.*"(http://.*/playlist.m3u8)".*|\1|p')
echo "URL=$URL"
extra=""
VLC=nvlc
if [[ "$1" == --save ]];then
    VLC=cvlc
    extra="--sout #std{access=file,mux=raw,dst=$2}"
fi
set -x
exec $VLC $extra $URL
