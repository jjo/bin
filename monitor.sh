#!/bin/sh


xrandr() {
	(set -x; exec /usr/bin/xrandr "$@" || exit 1)
}

BEST_VGA=$(/usr/bin/xrandr -q|egrep -A1 '^VGA'| sed -nr 's/^ +([^ ]+).*/\1/p')
BEST_LCD=$(/usr/bin/xrandr -q|egrep -A1 '^LVDS'| sed -nr 's/^ +([^ ]+).*/\1/p')
PRES_MODE=1024x768
case "$1" in
    solo)
        xrandr --output LVDS1 --mode $BEST_LCD --output VGA1 --off
        ;;
    pres)
        xrandr --output LVDS1 --mode $PRES_MODE --output VGA1 --same-as LVDS1 --mode $PRES_MODE
        ;;
    dual)
        xrandr --output LVDS1 --mode $BEST_LCD --output VGA1 --off
        xrandr --output LVDS1 --mode $BEST_LCD --pos 0x0 --left-of VGA1 --output VGA1 --mode $BEST_VGA --right-of LVDS1
        ;;
    dualup)
        xrandr --output LVDS1 --mode $BEST_LCD --output VGA1 --off
        xrandr --output LVDS1 --mode $BEST_LCD --pos 0x0 --below VGA1 --output VGA1 --mode $BEST_VGA
        ;;
    dualv)
        xrandr --output LVDS1 --mode $BEST_LCD --output VGA1 --off
        xrandr --output LVDS1 --mode $BEST_LCD --pos 0x0 --left-of LVDS1 --output VGA1 --mode $BEST_VGA --right-of LVDS1 --rotate left
        ;;
    *)
        echo "Uso: monitor.sh $(sed -r -n 's/^[ \t]+([a-z0-9]+)\)/\t\1|/p' $0)"
        exit 1
        ;;
esac

exit 0
