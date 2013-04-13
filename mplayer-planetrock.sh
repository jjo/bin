#!/bin/bash -x
#mplayer -playlist http://www.planetrock.com/planetrock.m3u
mplayer <(curl -s $(curl -s http://www.planetrock.com/player/|sed -nr '/audioURL/s,.*"(http://.*)".*,\1,p')|sed -nr 's,.*"(rtmp://.*/)(.*)".*,rtmpdump -q -y \2 -r \1\2,p'|rbash -x)
