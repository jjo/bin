#!/bin/bash
# run notify-send, and some ~armonic beep
exec 2>$HOME/log/notify-send.log
play_human() {
	play -q -n synth 0.25 pluck C4 pluck E4 vol 0.40 fade 0.1
}
play_alert_bootstack() {
	#play -n synth 1 sine 900 trap 2000 2 gain -5 bend .1,500,.100 remix 1-2 trim 0 0.3 delay 0.2 repeat 3
	play -q -n synth 1 sine 900 trap 2000 2 gain -5 bend .1,700,.100 remix 1-2 trim 0 0.3 delay 0.2 repeat 4
}
play_alert_other() {
	#play -q -n synth 1 sine 980 trap 2000 2 gain -7 bend .1,{-,}500,.100 remix 1-2  fade 0 0.4 delay 0.2 repeat 3
	#play -q -n synth 2 sine 980 trap 1500 2 gain -7 bend .1,{-,}500,.100 remix 1-2 trim 0 0.2 delay 0.2 repeat 5
	play -q -n synth 1 sine 900 trap 2000 2 gain -5 bend .1,-500,.100 remix 1-2 trim 0 0.3 delay 0.2 repeat 3
}
notify-send "$@"
case "$@" in
	*is?taking?a?look*) ;;
	*is-pd-bot*ACKNOWLEDGED*|*is-pd-bot*RESOLVED*);;
	*is-pd-bot*ootstack*)
		play_alert_bootstack "$@";;
	*is-pd-bot*)
		play_alert_other "$@";;
        *)
		play_human "$@";;
esac
