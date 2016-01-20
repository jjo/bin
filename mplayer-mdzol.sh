#!/bin/bash -x
# http://www.universomdz.com/home.html
#exec mplayer -playlist $@ http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
#exec nvlc http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
URL=$(wget -qO- http://latinstatic.edgesuite.net/radio-mdz/player.js|sed -rn 's,\\,,g;/video-link/s/.*(http[^"]+)".*/\1/p')
echo "URL=$URL"
exec nvlc "$URL"
