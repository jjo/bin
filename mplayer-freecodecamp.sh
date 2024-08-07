#!/bin/bash
# mplayer CLI friendly play for https://coderadio.freecodecamp.org/
Q=radio
case "$1" in
    -64) Q=low
esac
#STREAMS=$(curl -s https://coderadio-admin.freecodecamp.org/api/live/nowplaying/coderadio | jq -r .station.mounts[].url|egrep -o https://.+${Q}.mp3)
#STREAMS=$(curl -s https://coderadio-admin.freecodecamp.org/public/coderadio/playlist/pls | egrep -o https://.+${Q}.mp3)
#STREAMS=https://coderadio-relay-blr.freecodecamp.org/radio/8010/radio.mp3
STREAMS=https://coderadio-admin-v2.freecodecamp.org/listen/coderadio/radio.mp3
echo $STREAMS
set -x
exec mplayer $STREAMS
