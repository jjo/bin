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

typeset -a OUT_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^(VGA|DP|HDMI)[0-9] conn'| awk '/^[^-]/{ print $1 }'))
typeset -a LCD_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^LVDS[0-9] conn'| awk '{ print $1 }'))
PRES_MODE=1024x768
OUT_DEV1=${OUT_DEV_RES[0]}
OUT_RES1=${OUT_DEV_RES[1]}
OUT_DEV2=${OUT_DEV_RES[2]}
OUT_RES2=${OUT_DEV_RES[3]}
LCD_DEV=${LCD_DEV_RES[0]}
LCD_RES=${LCD_DEV_RES[1]}

echo LCD:${LCD_DEV?}@${LCD_RES?} OUT:${OUT_DEV1?}@${OUT_RES1?} ${OUT_DEV2:+${OUT_DEV2}@${OUT_RES2}}

wot="$1"
dryrun="$2"
case "$wot" in
    solo)    #%usage LCD display only
        xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off}
        xrandr --output $LCD_DEV --mode $LCD_RES ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off}
        ;;
    soloext) #%usage External output only
        xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off}
        xrandr --output $OUT_DEV1 --mode $OUT_RES1 ${LCD_DEV:+--output $LCD_DEV --off}
	;;
    pres*)   #%usage Presentation mode 1:1
	LCD_RES=$PRES_MODE
	OUT_RES1=$PRES_MODE
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV1 --same-as $LCD_DEV --mode $OUT_RES1
        ;;
    dualleft|dualright|dualup|dualdown|dualleftv|dualrightv) #%usage dual<ext_position>
	xtra=""
	# eg: dualrightv -> right-of --rotate left (vertical external)
	case "$wot" in *v) xtra="--rotate left";wot=${wot%v};; esac
	where="${wot#dual}-of"
	case $where in "up-of") where="above";; "down-of") where="below";; esac
        xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off} --output $LCD_DEV --mode $LCD_RES 
        xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --output $OUT_DEV1 --mode $OUT_RES1 --$where $LCD_DEV $xtra
        ;;
    h2v3)   #%usage Dual Horiz(left) Vert(right) 
        xrandr --output $LCD_DEV --off
        xrandr --output HDMI2
        xrandr --output HDMI3 --right-of HDMI2 --rotate right
	;;
    h2h3)   #%usage Dual Horiz(left) Horiz(right)
        xrandr --output $LCD_DEV --off
        xrandr --output HDMI2
        xrandr --output HDMI3 --right-of HDMI2
	;;
    h2h3)   #%usage Dual Vert(left) Horiz(right)
        xrandr --output $LCD_DEV --off
        xrandr --output HDMI2
        xrandr --output HDMI3 --right-of HDMI2 --rotate normal
	;;
    *)
        usage
        ;;
esac

exit 0
