#!/bin/bash

XRANDR=$(xrandr -q)

init_RESOL_DB() {
    RESOL_DB=$(echo "${XRANDR}"| egrep -A1 '^(VGA|eDP|DP|HDMI)-[0-9](-[0-9])? conn'| awk '/^[^-]/{ print $1 }' |xargs -n2)
}

get_resol() {
    local output=${1:?missing output}
    local resol=$(echo "$RESOL_DB"|awk '$1=="'"$output"'" { print $2 }')
    test -n "${resol}" && { echo "${resol}"; return 0 ;}
    echo "Output '$output' not found" >&2; return 1
}

#echo "$RESOL_DB"
check() {
    local output=${1:?missing output}
    get_resol ${output} >/dev/null
}

unused_outputs() {
    local SPEC="${*}"
    PATT="^(NONE"
    for spec in ${SPEC};do
        output=${spec%%[/@]*}
        PATT="${PATT}|${output}"
    done
    PATT="${PATT})"
    echo "$RESOL_DB" | grep -E -v "$PATT" | sed -E 's/[[:blank:]].+$//'
}

spec_to_xrandr() {
    local SPEC="${*}"
    #echo "SPEC=$SPEC" >&2
    LINES=""
    for output in $(unused_outputs ${SPEC}); do
        test -z "${output}" && continue
        LINES="${LINES}
xrandr --output ${output} --off"
    done
    for spec in ${SPEC};do
        output=${spec%%[/@]*}
        OUTPUT="--output ${output}"
        ON_OFF="--auto"
        case "$spec" in
            */off*) ON_OFF=--off;;
        esac
        ROTATE="--rotate normal"
        case "$spec" in
            */rn*) ROTATE="--rotate normal";;
            */rr*) ROTATE="--rotate right";;
            */rl*) ROTATE="--rotate left";;
        esac
        PRI=""
        case "$spec" in
            */pri*) PRI="--primary";;
        esac
        POS="${prev_output+--right-of ${prev_output}}"
        case "$spec" in
            */lo*) POS="--left-of ${prev_output}";;
            */bo*) POS="--below ${prev_output}";;
            */ao*) POS="--above ${prev_output}";;
        esac
        MODE=""
        if [[ $ON_OFF != --off ]]; then
            MODE="--mode $(get_resol ${output})" || return 1
            case ${spec} in
                *@*) MODE="--mode ${spec##*@}"
            esac
        fi
        LINES="${LINES}
xrandr ${OUTPUT} ${ON_OFF} ${MODE} ${PRI} ${ROTATE} ${POS}"
        if [[ $ON_OFF == --auto ]];then
            prev_output=${output}
        else
            unset prev_output
        fi
    done
    echo "${LINES}" | ${RUN}
}

usage() {
    echo -e "Usage: monitor-ng.sh [-n] wot\n  wot:\n$(sed -r -n 's/#[%]usage//p' $0)" >&2
    exit 1
}

# main()
RUN="bash -x"
RES_2K=2560x1440
RES_LOW=1368x768

init_RESOL_DB

[[ $1 == -n ]] && RUN="cat" && shift
case "$1" in
    desk)  #%usage 3-horizontal DP-1 -> DP-2-1 -> DP-2-2
        check DP-1 && spec_to_xrandr DP-1 DP-2-1/pri@${RES_2K} DP-2-2;;
    deskl) #%usage DP-2-1 center, eDP-1 below, DP-2-2 right
        check eDP-1 && spec_to_xrandr eDP-1 DP-2-1/pri/ao@${RES_2K} DP-2-2;;
    solo)  #%usage laptop only
        check eDP-1 && spec_to_xrandr eDP-1;;
    solo@low) #%usage laptop only, lowres
        check eDP-1 && spec_to_xrandr eDP-1@${RES_LOW};;
    *) usage;;
esac
