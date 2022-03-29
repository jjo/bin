#!/bin/bash
SAVE=""
while true; do
    case "$1" in
        -s | --save) SAVE="$2"; shift 2;;
        --) shift; break;;
        *) break;;
    esac
done

echo SAVE=$SAVE
URI=https://latamstreaming-live-os.akamaized.net/live_passthrough_static/ammdz/playlist.m3u8

case "$SAVE" in
    "") exec vlc -I ncurses "${URI}";;
    *)  for i in {01..99};do sleep 0.1 || break; vlc -I dummy --sout="file/ogg:${SAVE%.ogg}-${i}.ogg" "${URI}"; done;;
esac
