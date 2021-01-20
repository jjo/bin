#!/bin/bash -x
LCD_OUT=$(/usr/bin/xrandr -q|sed -nr   's/^(LVDS[0-9]|eDP-?[0-9]) conn.*/\1/p')
: ${LCD_OUT:?}
case "$1" in
	0)
        ~/bin/monitor-ng.sh solo
        ;;
	1)
        ~/bin/monitor-ng.sh solo@low
        ;;
	desk)
        #~/bin/monitor.sh h3v2 #1360x768
        ~/bin/monitor-ng.sh desk
        ;;
	deskl)
        #~/bin/monitor.sh h3v2 #1360x768
        ~/bin/monitor-ng.sh deskl
        ;;
	*) ~/bin/monitor.sh ${1:?} 1360x768;;
esac
