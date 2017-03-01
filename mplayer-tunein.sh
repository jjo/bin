#!/bin/bash
cache() {
    local cmdline="$*"
    local dir="$HOME/.cache/mplayer-tunein"
    local key="${cmdline// /_}"
    local cachefile="${dir}/cache-${key}"
    mkdir -p ${dir}
    # GC w/1day TTL:
    find ${dir:?}  -name 'cache-*' -mtime +1 -delete
    if [ -s ${cachefile} ] ;then
        cat "${cachefile}"
    else
        ${cmdline} | tee "${cachefile}"
        [ ${PIPESTATUS[0]} -eq 0 ] || { rm -f "${cachefile}"; return 1 ;}
    fi
    return 0
}
tunein_search() {
   local query=${*:?}
   query="${query// /+}"
   local tunein_search_result=$(curl -s "http://tunein.com/search/?query=$query"|egrep -o '/radio/[^"]+-s[^"]+'|sort|uniq)
   local tunein_url=http://tunein.com/${tunein_search_result:?}
   local streamurl=$(curl -s $(curl -s ${tunein_url:?} |sed -rn 's/.*StreamUrl.:.([^"]+)".*/http:\1/p')|jq -r '.Streams[0].Url')
   echo "*** streamurl=${streamurl:?}" >&2
   echo ${streamurl}
}

OPTS=$(getopt -o vnc:s: --long verbose,no-urlcache,cache:,save: -n 'mplayer-tunein' -- "$@") || exit 1
eval set -- "$OPTS"
cache_func=cache
SAVE=""
VERBOSE=""
MPLAYER_CACHE=""
while true; do
   case "$1" in
       -v | --verbose) VERBOSE=1; shift;;
       -n | --no-urlcache) cache_func=""; shift;;
       -s | --save) SAVE="$2"; shift 2;;
       -c | --cache) MPLAYER_CACHE="-cache $2 -cache-min 90"; shift 2;;
       --) shift; break;;
       *) break;;
    esac
done

case "$0" in
    *mplayer-tunein.sh)
        search="$*"
        shift
    ;;
    *mplayer-*.sh)
    # infer search from mplayer-<QUERY>.sh symlink
        search=${0##*mplayer-}
        search=${search%.sh}
    ;;
    *)  exit 1;;
esac


CMD="mplayer $MPLAYER_CACHE"
if [ -n "$SAVE" ]; then
    CMD="ffmpeg -c copy $SAVE -i"
fi
[ -n "$VERBOSE" ] && set -x
URL=$($cache_func tunein_search "${search:?}") || exit 1
: ${URL:?}
set -x
exec $CMD $URL
