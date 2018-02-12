#!/bin/bash -x
LCD_OUT=$(/usr/bin/xrandr -q|sed -nr   's/^(LVDS[0-9]|eDP-?[0-9]) conn.*/\1/p')
: ${LCD_OUT:?}
case "$1" in
	0) /usr/bin/xrandr --output ${LCD_OUT} --mode 1920x1080;;
	1) /usr/bin/xrandr --output ${LCD_OUT} --mode 1360x768;;
	desk) ~/bin/monitor.sh h3v2 1360x768;;
	*) ~/bin/monitor.sh ${1:?} 1360x768;;
esac
