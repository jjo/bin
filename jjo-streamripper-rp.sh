#!/bin/sh -x
DIR=$HOME/Download/rp
cd $DIR || exit 2
PREFIX=%q-%A-%T
AAC_128=http://www.radioparadise.com/musiclinks/rp_128aac-2.m3u
MP3_128=http://www.radioparadise.com/musiclinks/rp_128.m3u
MP3_192=http://www.radioparadise.com/musiclinks/rp_192.m3u

SRC=$MP3_192
cleanup() {
	id3v2 -A RadioParadise $DIR/*.mp3
	exit
}
trap 'cleanup' 2 15
rm -f $DIR/incomplete/*.mp3
streamripper $SRC "Mozilla/4.0" -D $PREFIX
