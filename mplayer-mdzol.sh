#!/bin/bash -x
#URL=$(wget -qO- www.mdzradio.com/player.php|egrep androidButton|sed -rn 's|.*"(http://.*/playlist.m3u8)".*|\1|p')
#URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/js/classes/JwPlayer2.js | sed -rn '/jwplayer.*load/s|.*(http:[^"]+)".*|\1|p')
#URL=http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
#URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/player.js|sed -rn 's,\\,,g;/video-link/s/.*(http[^"]+)".*/\1/p')
URL=$(wget -qO- http://www.mdzradio.com/player.php| sed -rn '/androidButton/s|.*(http://.*.mp3)".*|\1|p')

echo "URL=$URL"
extra=""
VLC=nvlc
if [[ "$1" == --save ]];then
    exec ffmpeg -i "$URL" -c copy "$2"
fi
set -x
exec $VLC $extra $URL
