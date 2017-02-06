#!/bin/bash -x
#URL=$(wget -qO- www.mdzradio.com/player.php|egrep androidButton|sed -rn 's|.*"(http://.*/playlist.m3u8)".*|\1|p')
#URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/js/classes/JwPlayer2.js | sed -rn '/jwplayer.*load/s|.*(http:[^"]+)".*|\1|p')
#URL=http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
#URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/player.js|sed -rn 's,\\,,g;/video-link/s/.*(http[^"]+)".*/\1/p')
#URL=$(wget -qO- http://www.mdzradio.com/player.php| sed -rn '/androidButton/s|.*(http://.*.mp3)".*|\1|p')
# 2017-02-06:
TUNEIN_URL="http://tunein.com/$(curl -s http://tunein.com/search/?query=mdzradio|egrep -o '/radio/MDZ[^"]+'|sort|uniq)"
URL=$(curl -s $(curl -s ${TUNEIN_URL:?} |sed -rn 's/.*StreamUrl.:.([^"]+)".*/http:\1/p')|jq -r '.Streams[-1].Url')

echo "URL=$URL"
extra=""
VLC=nvlc
if [[ "$1" == --save ]];then
    exec ffmpeg -i "$URL" -c copy "$2"
fi
set -x
exec $VLC $extra $URL
