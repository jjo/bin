#!/bin/sh
f="${1:?missing file.flv}"
o="${f%.flv}.avi"
V_BITRATE=1000
#ffmpeg -i "$f" -y -v 0 -f avi -sameq "$o"
ffmpeg -i "$f" -y -v 0 -f avi -sameq "$o"
exit
mencoder -forceidx \
"$@" \
-oac mp3lame -lameopts abr:br=56 -srate 22050 \
-ovc xvid -xvidencopts bitrate=$V_BITRATE:autoaspect \
-vf pp=ac \
-o "$o" "$f"

