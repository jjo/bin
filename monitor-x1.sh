#!/bin/bash
# 4x screen setup thru Dell D6000 dock via USB-C from Thinkpad X1 Gen9 on linux-5.15 (Pop_OS 21.10)
#
#  LEFT | MAIN | RIGHT
#        BUILTIN
#

MAIN_MODE=2560x1440 # Can't read with 4K :/
for file in `ls -1 /sys/class/drm/*/edid`; do
	text=$(tr -d '\0' <"$file")
	if [ -n "$text" ]; then
		EDID=$(edid-decode "$file")
		device=${file#/sys/class/drm/card*-}
		device=${device%/edid}
        device=$(xrandr -q | grep -oE "^${device}\S*")
        echo "device=${device}"
        echo "${EDID}" | grep -e Manufacturer: -e Serial.Number:
        case "${EDID}" in
            *RXP1N7890TNL*) LEFT=${device};;  # Dell 24"
            *H4ZN900103*)   MAIN=${device};;  # Samsung 31"
            *R9F1P45O9M0L*) RIGHT=${device};; # Dell 24"
            *Manufacturer:?AUO*) BUILTIN=${device};; # X1 Gen9 display
        esac
	fi
done
echo "LEFT=${LEFT:?} MAIN=${MAIN:?} RIGHT=${RIGHT:?} BUILTIN=${BUILTIN:?}"
set -x
xrandr --output $LEFT --off; xrandr --output $LEFT --auto  # workaround Dell D6000 Dock HDMI output to LEFT monitor
xrandr --output $MAIN --mode $MAIN_MODE --primary --output $LEFT --left-of $MAIN --output $BUILTIN --below $MAIN --output $RIGHT --right-of $MAIN
