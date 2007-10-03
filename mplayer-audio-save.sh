#!/bin/bash
# $Id: mplayer-audio-save.sh,v 1.9 2005/01/24 18:16:07 jjo Exp $
#
# Saves mplayer audio stream as OGG or MP3; uses mplayer for stream 
# sucking, piping PCM audio stream to encoder stdin. Intended for
# saving online radio streams.
#
# Requires: mplayer, oggenc for ogg(or lame for mp3).
#
# Author: JuanJo Ciarlante
# License: GPLv2
#
help() {
cat <<EOF
Usage:
     mplayer-audio-save.sh {output-file} {input-stream}

Usage examples:
     mplayer-audio-save.sh output.ogg http://site/stream
     mplayer-audio-save.sh output.mp3 http://site/stream
     mplayer-audio-save.sh output.ogg {any mplayer opts} http://site/stream

   ... some presets:
     mplayer-audio-save.sh --nihuil

   deferred execution (non interactive):
     screen -dm -S SessionName mplayer-audio-save.sh ...args... | at 17:30
EOF
}
DATE=$(date +%Y%m%d-%H%M)
Q=1
MONO=1

#Presets useful for me @Mendoza,Argentina ...
case "$1" in
--nihuil|--ni*) shift;set -- nihuil-$DATE.ogg $* http://200.61.35.6/nihuil ;;
--fmunc*)       shift;set -- fmuncu-$DATE.ogg $* http://fm.uncu.edu.ar:8000;;
esac

test $# -ge 2 || { help;exit 2;}
FILE=${1?ERROR: missing output file}
shift
URL=${*?ERROR: missing source URL}

exit_if_not_present(){ 
	which "$1" >&/dev/null && return 0
	echo "ERROR: Required \"$1\" not installed. $2" >&2;exit 1
}

exit_if_not_present mplayer
#OGG_ARGS="-resample 16000"
#MP3_ARGS="-m s --abr 44"
#SPX_ARGS="-n"

EXT=${FILE#*.} 
case $EXT in
ogg) 	exit_if_not_present oggenc
	ENCCMD="oggenc  ${MONO:+ --downmix} -q $Q $OGG_ARGS -o $FILE -" ;;
mp3) 	exit_if_not_present lame
	ENCCMD="lame    ${MONO:+ -a}        -q $Q --nohist $MP3_ARGS - $FILE" ;;
spx) 	exit_if_not_present speexenc
	#Speex ... mostly working
	test -n "$MONO" && MONO="" || MONO="--stereo" # speexenc defaults mono
	ENCCMD="speexenc ${MONO} $SPX_ARGS - $FILE" ;;

*)	echo "Extesion \"$EXT\" unknown (use .ogg or  .mp3 or .spx)";exit 1;;
esac

echo "Saving to \"$FILE\" from $URL"
echo "ENCCMD=$ENCCMD"
# doit the sexy way...
# use bash idiom to cleanly pipe from mplayer to $ENCCMD stdin
set -x
mplayer -nocache -quiet -ao pcm -aofile >($ENCCMD) $URL
