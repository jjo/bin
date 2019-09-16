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
# Thanks xndc for
# https://gist.githubusercontent.com/xndc/c732204e274743204f1f/raw/c03eb16f7ed5088732dde85c3f2d2162b52b78cd/tunejack.sh !
# Cherry picking bits:
# Helper function for encoding a URL.
# See http://stackoverflow.com/questions/296536/
urlencode() {
    local string="$*"
    local strlen=${#string}
    local encoded=""

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}
# Main tunejack.sh (adapted) logic
tunejack() {
    local pattern=${*:?}
    local API_RESPONSE API_RESULT_TAG API_URL
    API_RESPONSE=$(curl -s "http://opml.radiotime.com/Search.ashx?query=$(urlencode $pattern)")
    # Try to grab the first <outline> element from the response.
    # It has to have attributes type="audio" and item="station".
    # Discard results containing key="unavailable" - they're useless stubs.
    API_RESULT_TAG=$(echo "$API_RESPONSE" \
        | grep '<outline type="audio"' \
        | grep 'item="station"' \
        | grep -v 'key="unavailable"' \
        | head -n 1)
    API_RESULT_TAG=$(echo "$API_RESULT_TAG" | sed 's/" /"\n/g')
    # Helper function to extract a tag.
    # The sed is because we're not actually decoding XML, and things like
    # apostrophes are represented by HTML entities like &apos;.
    extract_tag() {
        TAG="${1}"
        echo "$API_RESULT_TAG" | grep "^$TAG=" | cut -d '"' -f 2 \
            | sed "s/&apos;/\'/g"
    }
    # Display the details we're interested in - name, subtext, URL.
    echo "$(extract_tag text)" >&2
    echo "$(extract_tag subtext)" >&2
    echo "$(extract_tag URL)" >&2
    # Throw the URL in a variable for later purposes.
    API_URL="$(extract_tag URL)"
    echo "${API_URL}"
}
tunein_search() {
    local query=${*:?} streamurl api_url
    query="${query// /+}"
    if [ -f ~/etc/radiocache.d/${query} ]; then
        streamurl=$(cat ~/etc/radiocache.d/${query})
    else
        api_url=$(tunejack ${query})
        streamurl=$(curl -s "${api_url}")
    fi
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
