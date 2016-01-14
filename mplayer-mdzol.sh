#!/bin/bash -x
# http://www.universomdz.com/home.html
#exec mplayer -playlist $@ http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
exec nvlc http://207.198.106.33:1935/mdzradio/default.stream/playlist.m3u8
