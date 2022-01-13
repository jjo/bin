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

MAIN_MODE=2560x1440        # Can't read with native 4K :/
LEFT_MATCH=RXP1N7890TNL    # Dell 24" S/N
MAIN_MATCH=H4ZN900103      # Samsung 31" S/N
RIGHT_MATCH=R9F1P45O9M0L   # Dell 24" S/N
BUILTIN_MATCH="Manufacturer:?AUO"  # X1 Gen9 builtin display (no S/N, match by Manufacturer)


test -f /usr/bin/edid-decode || {
    echo "ERROR: needs edid-decode installed"
}

[ $(grep ^connected /sys/class/drm/card*/*/status|wc -l) == 4 ] || {
    echo "NOTE: $0: SKIP, didn't detect FOUR connected monitors"
    exit 0
}

for file in $(ls -1 /sys/class/drm/*/edid); do
    text=$(tr -d '\0' <"$file")
    test -n "$text" && {
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
            *${LEFT_MATCH}*)    LEFT=${device};;
            *${MAIN_MATCH}*)    MAIN=${device};;
            *${RIGHT_MATCH}*)   RIGHT=${device};;
            *${BUILTIN_MATCH}*) BUILTIN=${device};;
        esac
    }
done
echo "LEFT=${LEFT:?} MAIN=${MAIN:?} RIGHT=${RIGHT:?} BUILTIN=${BUILTIN:?}"
set -x
# Workaround Dell D6000 Dock HDMI output to LEFT monitor sending it to sleep -> "Did you try turning off/on again ?"
xrandr --output $LEFT --off; xrandr --output $LEFT --auto
xrandr --output $MAIN --mode $MAIN_MODE --primary --output $LEFT --left-of $MAIN --output $BUILTIN --below $MAIN --output $RIGHT --right-of $MAIN
