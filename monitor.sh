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

typeset -a LCD_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^(LVDS[0-9]|eDP-?[0-9]) conn'| awk '{ print $1 }'))
typeset -a OUT_DEV_RES=($(/usr/bin/xrandr -q|egrep -A1 '^(VGA|DP-?1|DP-?2|HDMI)-?[0-9] conn'| awk '/^[^-]/{ print $1 }'))
PRES_MODE=1024x768
#PRES_MODE=1920x1080
OUT_DEV1=${OUT_DEV_RES[0]}
OUT_RES1=${OUT_DEV_RES[1]}
OUT_DEV2=${OUT_DEV_RES[2]}
OUT_RES2=${OUT_DEV_RES[3]}
LCD_DEV=${LCD_DEV_RES[0]}
LCD_RES=${LCD_DEV_RES[1]}
: ${LCD_DEV:?} ${LCD_RES:?}

case "$1" in
    -n) dryrun="$1"; shift;;
esac
wot="$1"
shift; test -n "$1" && LCD_RES="$1"
shift; test -n "$1" && OUT_RES1="$2"
shift; test -n "$1" && OUT_RES2="$3"
echo "# LCD:${LCD_DEV?}@${LCD_RES?} OUT:${OUT_DEV1?}@${OUT_RES1?} ${OUT_DEV2:+${OUT_DEV2}@${OUT_RES2}}"
case "$wot" in
    solo)    #%usage LCD display only
        xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off}
        xrandr --output $LCD_DEV --mode $LCD_RES ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off} --rotate normal --auto
        ;;
    soloext) #%usage External output only
        xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off}
        xrandr --output $OUT_DEV1 --mode $OUT_RES1 ${LCD_DEV:+--output $LCD_DEV --off}
        ;;
    pres*)   #%usage Presentation mode 1:1
        LCD_RES=$PRES_MODE
        OUT_RES1=$PRES_MODE
        xrandr --output $LCD_DEV --mode $LCD_RES --output $OUT_DEV1 --same-as $LCD_DEV --mode $OUT_RES1 --rotate normal --auto
        ;;
    dualleft|dualright|dualup|dualdown|dualleftv|dualrightv) #%usage dual<ext_position>
        : ${OUT_DEV1:?} ${OUT_RES1:?}
        xtra=""
        # eg: dualrightv -> right-of --rotate left (vertical external)
        case "$wot" in *v) xtra="--rotate left";wot=${wot%v};; esac
        where="${wot#dual}-of"
        case $where in "up-of") where="above";; "down-of") where="below";; esac
            xrandr ${OUT_DEV1:+--output $OUT_DEV1 --off} ${OUT_DEV2:+--output $OUT_DEV2 --off} --output $LCD_DEV --mode $LCD_RES 
            xrandr --output $LCD_DEV --mode $LCD_RES --pos 0x0 --output $OUT_DEV1 --mode $OUT_RES1 --$where $LCD_DEV $xtra
        ;;
    h3v2)   #%usage Dual Horiz(left) Vert(right)
        : ${OUT_DEV1:?} ${OUT_RES1:?}
        : ${OUT_DEV2:?} ${OUT_RES2:?}
        xtra=""
        [[ $LCD_DEV =~ eDP-?[0-9] ]] || \
            xrandr --output $LCD_DEV --off
            xrandr --output $OUT_DEV2 --primary --rotate normal --auto
        [[ $LCD_DEV =~ eDP-?[0-9] ]] && \
            xrandr --output $LCD_DEV --below $OUT_DEV2 --mode $LCD_RES --rotate normal --auto
            xrandr --output $OUT_DEV1 --right-of $OUT_DEV2 --rotate right --auto
        ;;
    h2v3)   #%usage Dual Horiz(left) Vert(right)
        : ${OUT_DEV1:?} ${OUT_RES1:?}
        : ${OUT_DEV2:?} ${OUT_RES2:?}
        [[ $LCD_DEV =~ eDP-?[0-9] ]] || \
            xrandr --output $LCD_DEV --off
            xrandr --output $OUT_DEV1 --primary --rotate normal --auto
        [[ $LCD_DEV =~ eDP-?[0-9] ]] && \
            xrandr --output $LCD_DEV --below $OUT_DEV1 --mode $LCD_RES --rotate normal --auto
            xrandr --output $OUT_DEV2 --right-of $OUT_DEV1 --rotate right --auto
        ;;
    h2h3)   #%usage Dual Horiz(left) Horiz(right)
        : ${OUT_DEV1:?} ${OUT_RES1:?}
        : ${OUT_DEV2:?} ${OUT_RES2:?}
        [[ $LCD_DEV =~ eDP-?[0-9] ]] || \
            xrandr --output $LCD_DEV --off
            xrandr --output $OUT_DEV1 --primary --rotate normal --auto
        [[ $LCD_DEV =~ eDP-?[0-9] ]] && \
            xrandr --output $LCD_DEV --below $OUT_DEV1 --mode $LCD_RES --rotate normal --auto
            xrandr --output $OUT_DEV2 --right-of $OUT_DEV1 --rotate normal --auto
        ;;
    h3h2)   #%usage Dual Horiz(left) Horiz(right)
        : ${OUT_DEV1:?} ${OUT_RES1:?}
        : ${OUT_DEV2:?} ${OUT_RES2:?}
        [[ $LCD_DEV =~ eDP-?[0-9] ]] || \
            xrandr --output $LCD_DEV --off
            xrandr --output $OUT_DEV2 --primary --rotate normal --auto
        [[ $LCD_DEV =~ eDP-?[0-9] ]] && \
            xrandr --output $LCD_DEV --below $OUT_DEV2 --mode $LCD_RES --rotate normal --auto
            xrandr --output $OUT_DEV1 --right-of $OUT_DEV2 --rotate normal --auto
        ;;
    *)
        usage
        ;;
esac

exit 0
# vim: sw=4 ts=4 si et
