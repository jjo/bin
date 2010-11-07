#!/bin/sh

xrandr() {
	(set -x; exec /usr/bin/xrandr "$@" || exit 1)
}

case "$1" in
    solo)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        ;;
    pres)
        xrandr --output VGA1 --mode 1024x768 --same-as LVDS1 --output LVDS1 --mode 1024x768
        ;;
    pres19)
        xrandr --output VGA1 --mode 1440x900 --same-as LVDS1 --output LVDS1 --mode 1024x768
    	;;
    pres24)
        xrandr --output VGA1 --mode 1920x1200 --same-as LVDS1 --output LVDS1 --mode 1024x768
    	;;
    vga24)
        xrandr --output VGA1 --mode 1920x1200 --output LVDS1 --off
    	;;
    dual)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        xrandr --output VGA1 --mode 1440x900 --pos 0x0 --left-of LVDS1 --output LVDS1 --mode 1024x768 --right-of VGA1
        ;;
    dualup)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        xrandr --output VGA1 --mode 1440x900 --pos 0x0 --above LVDS1 --output LVDS1 --mode 1024x768 --below VGA1
        ;;
    dualup24)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        xrandr --output VGA1 --mode 1920x1200 --pos 0x0 --above LVDS1 --output LVDS1 --mode 1024x768 --below VGA1
        ;;
    dual24)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        xrandr --output LVDS1 --mode 1024x768 --left-of VGA1 --pos 0x0 --output VGA1 --mode 1920x1200 --right-of LVDS1 
        ;;
    dualv)
        xrandr --output VGA1 --off --output LVDS1 --mode 1024x768
        xrandr --output VGA1 --mode 1920x1200 --pos 0x0 --right-of LVDS1 --rotate left --output LVDS1 --mode 1024x768 --left-of VGA1
        ;;
    *)
        echo "Uso: monitor.sh $(sed -r -n 's/^[ \t]+([a-z0-9]+)\)/\t\1|/p' $0)"
        exit 1
        ;;
esac

exit 0
