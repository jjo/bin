#!/bin/bash


xrandr() {
	(set -x; exec /usr/bin/xrandr "$@" || exit 1)
}

typeset -a OUT_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^(VGA|DP|HDMI)[0-9] conn'| awk '{ print $1 }'))
typeset -a LCD_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^LVDS[0-9] conn'| awk '{ print $1 }'))
PRES_MODE=1024x768
OUT_DEV=${OUT_DEV_RES[0]}
OUT_RES=${OUT_DEV_RES[1]}
LCD_DEV=${LCD_DEV_RES[0]}
LCD_RES=${LCD_DEV_RES[1]}

echo LCD:${LCD_DEV?}@${LCD_RES?} OUT:${OUT_DEV?}@${OUT_RES?} 
sleep 2

case "$1" in
    solo)
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --off
        ;;
    pres)
        xrandr --output $LCD_DEV --mode $PRES_MODE --output $OUT_DEV --same-as $LCD_DEV --mode $PRES_MODE
        ;;
    dual)
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --off
        xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --left-of $OUT_DEV --output $OUT_DEV --mode $OUT_RES --right-of $LCD_DEV
        ;;
    dualup)
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --off
        xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --below $OUT_DEV --output $OUT_DEV --mode $OUT_RES
        ;;
    dualv)
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV --off
        xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --left-of $LCD_DEV --output $OUT_DEV --mode $OUT_RES --right-of $LCD_DEV --rotate left
        ;;
    *)
        echo "Uso: monitor.sh $(sed -r -n 's/^[ \t]+([a-z0-9]+)\)/\t\1|/p' $0)"
        exit 1
        ;;
esac

exit 0
