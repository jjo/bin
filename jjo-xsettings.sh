#!/bin/bash
# Setup vertical mouse
xinput set-button-map "$(xinput -list |sed -nr 's/.*Kingsis.*id=([0-9]+).*/\1/p')" 1 2 3 4 5 6 7 8 9 10 11 12 13 14
setxkbmap -option ctrl:nocaps us altgr-intl
#disable thinkpad trackpad
trackpad_id=$(xinput list|sed -nr '/Synaptics.TouchPad/s/.*id=([0-9]+).*/\1/p')
test -n "$trackpad_id" && xinput set-prop $trackpad_id "Device Enabled" 0
