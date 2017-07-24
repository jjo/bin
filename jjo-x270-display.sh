#!/bin/bash -x
case "$1" in
	0) /usr/bin/xrandr --output eDP-1 --mode 1920x1080;;
	1) /usr/bin/xrandr --output eDP-1 --mode 1360x768;;
	desk) ~/bin/monitor.sh h3v2 1360x768;;
esac
