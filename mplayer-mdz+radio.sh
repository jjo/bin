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
URI=https://latamstreaming-live-os.akamaized.net/live_passthrough/ammdz/chunks.m3u8

case "$SAVE" in
    "") vlc -I ncurses "${URI}";;
    *)  vlc -I dummy --sout="file/ogg:${SAVE}" "${URI}";;
esac
