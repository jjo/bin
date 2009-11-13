#!/bin/sh

case "$1" in
    solo)
        xrandr --output VGA --off --output LVDS --mode 1024x768
        ;;
    pres)
        xrandr --output VGA --mode 1024x768 --same-as LVDS --output LVDS --mode 1024x768
        ;;
    pres19)
        xrandr --output VGA --mode 1440x900 --same-as LVDS --output LVDS --mode 1024x768
    	;;
    pres24)
        xrandr --output VGA --mode 1920x1200 --same-as LVDS --output LVDS --mode 1024x768
    	;;
    vga24)
        xrandr --output VGA --mode 1920x1200 --output LVDS --off
    	;;
    dual)
        xrandr --output VGA --off --output LVDS --mode 1024x768
        xrandr --output VGA --mode 1440x900 --pos 0x0 --left-of LVDS --output LVDS --mode 1024x768 --right-of VGA
        ;;
    dual24)
        xrandr --output VGA --off --output LVDS --mode 1024x768
        xrandr --output LVDS --mode 1024x768 --left-of VGA --pos 0x0 --output VGA --mode 1920x1200 --right-of LVDS 
        ;;
    dualv)
        xrandr --output VGA --off --output LVDS --mode 1024x768
        xrandr --output VGA --mode 1920x1200 --pos 0x0 --right-of LVDS --rotate left --output LVDS --mode 1024x768 --left-of VGA
        ;;
    *)
        echo "Uso: monitor.sh $(sed -r -n 's/^[ \t]+([a-z0-9]+)\)/\t\1|/p' $0)"
        exit 1
        ;;
esac

exit 0
