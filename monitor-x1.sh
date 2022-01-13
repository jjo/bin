#!/bin/bash
# 4x screen setup thru Dell D6000 dock via USB-C from Thinkpad X1 Gen9 on linux-5.15 (Pop_OS 21.10)
# This script fixes 2 issues:
#   - after re-plugging / coming back from suspend, device IDs get reset,
#     thus the whole curated layout gets scrambled
#   - HDMI connected monitor (LEFT in my case) goes to sleep, while still
#     connected and showing in /sys/class/drm/card*/edid
#
#  LEFT | MAIN | RIGHT
#        BUILTIN
#

MAIN_MODE=2560x1440 # Can't read with 4K :/
for file in `ls -1 /sys/class/drm/*/edid`; do
	text=$(tr -d '\0' <"$file")
	if [ -n "$text" ]; then
		EDID=$(edid-decode "$file")
        # Remove `cardN-` prefix and `/edid` postfix
		device=${file#/sys/class/drm/card*-}
		device=${device%/edid}
        # Fix: sys/class device appears as e.g. `DVI-I-1` while xrandr uses `DVI-I-1-1`
        device=$(xrandr -q | grep -oE "^${device}\S*")
        echo "device=${device}"
        echo "${EDID}" | grep -e Manufacturer: -e Serial.Number:
        # Map monitor S/N (or Manufacturer for builtin) to `xrandr` device
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
# Workaround Dell D6000 Dock HDMI output to LEFT monitor: "Did you try turning off/on again ?"
xrandr --output $LEFT --off; xrandr --output $LEFT --auto
xrandr --output $MAIN --mode $MAIN_MODE --primary --output $LEFT --left-of $MAIN --output $BUILTIN --below $MAIN --output $RIGHT --right-of $MAIN
