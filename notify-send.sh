#!/bin/bash
# run notify-send, and some ~armonic beep
notify-send "$@"
play -q -n synth 0.25 pluck C4 pluck E4 vol 0.40 fade 0.1
