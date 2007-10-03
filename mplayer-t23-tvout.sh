#!/bin/sh
GEOM="-geometry 667x404-72+9"
VF="-vf expand=0:-90:0:0"
VO="-vo sdl"
set -x
exec mplayer $VF $VO $GEOM "$@"

