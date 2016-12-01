#!/bin/bash
# Vertical mouse: setup button-map
vmouse_id="$(xinput -list |sed -nr 's/.*Kingsis.*id=([0-9]+).*/\1/p')"
test -n "$vmouse_id" && (set -x;xinput set-button-map "$vmouse_id" 1 2 3 4 5 6 7 8 9 10 11 12 13 14)
# TrackPoint: bounce it - w/ ubuntu LTS 16.04 around ~Aug/2016 started to come out of suspend w/o buttons working [-(
trackpoint_id=$(xinput list|sed -nr '/TrackPoint/s/.*id=([0-9]+).*/\1/p')
test -n "$trackpoint_id" && (set -x; xinput disable $trackpoint_id ; xinput enable $trackpoint_id)
sleep 0.2 #(?), needed anyway to effectively disable ->
# Touchpad: disable
touchpad_id=$(xinput list|sed -nr '/Synaptics.TouchPad/s/.*id=([0-9]+).*/\1/p')
# test -n "$touchpad_id" && (set -x;xinput set-prop "$touchpad_id" "Device Enabled" 0; xinput disable "$touchpad_id")
(set -x
xinput set-prop ${touchpad_id} "Synaptics Finger" 20 40 255
xinput set-prop ${touchpad_id} "Synaptics Noise Cancellation" 20 20
)
(set -x
synclient Palmdetect=1
synclient TouchpadOff=1
synclient PalmMinWidth=8
synclient PalmMinZ=100
)
setxkbmap -option ctrl:nocaps us altgr-intl
