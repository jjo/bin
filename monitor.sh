#!/bin/bash


xrandr() {
	case "$dryrun" in 
	-n) echo xrandr "$@";;
        "") (sleep 1;set -x; exec /usr/bin/xrandr "$@" || exit 1)
	esac
}

usage() {
	echo -e "Usage: monitor.sh wot [-n]\n  wot:\n$(sed -r -n 's/#[%]usage//p' $0)"
	exit 1
}

test $# -gt 0 || usage

typeset -a OUT_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^(VGA|DP|HDMI)[0-9] conn'| awk '{ print $1 }'))
typeset -a LCD_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^LVDS[0-9] conn'| awk '{ print $1 }'))
PRES_MODE=1024x768
OUT_DEV=${OUT_DEV_RES[0]}
OUT_RES=${OUT_DEV_RES[1]}
LCD_DEV=${LCD_DEV_RES[0]}
LCD_RES=${LCD_DEV_RES[1]}

echo LCD:${LCD_DEV?}@${LCD_RES?} OUT:${OUT_DEV?}@${OUT_RES?} 

wot="$1"
dryrun="$2"
case "$wot" in
    solo)    #%usage LCD display only
        xrandr --output $LCD_DEV --mode $LCD_RES ${OUT_DEV:+--output $OUT_DEV --off}
        ;;
    soloext) #%usage External output only
        xrandr --output $OUT_DEV --mode $OUT_RES ${LCD_DEV:+--output $LCD_DEV --off}
	;;
    pres*)   #%usage Presentation mode 1:1
	LCD_RES=$PRES_MODE
	OUT_RES=$PRES_MODE
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --same-as $LCD_DEV --mode $OUT_RES
        ;;
    dualleft|dualright|dualup|dualdown|dualleftv|dualrightv) #%usage dual<ext_position>
	xtra=""
	# eg: dualrightv -> right-of --rotate left (vertical external)
	case "$wot" in *v) xtra="--rotate left";wot=${wot%v};; esac
	where="${wot#dual}-of"
	case $where in "up-of") where="above";; "down-of") where="below";; esac
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --off
        xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --output $OUT_DEV --mode $OUT_RES --$where $LCD_DEV $xtra
        ;;
    *)
        usage
        ;;
esac

exit 0
