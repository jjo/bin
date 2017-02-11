#!/bin/bash -x
tunein_search() {
   local query=${1:?}
   local tunein_search_result=$(curl -s "http://tunein.com/search/?query=$query"|egrep -o '/radio/[^"]+-s[^"]+'|sort|uniq)
   local tunein_url=http://tunein.com/${tunein_search_result:?}
   local streamurl=$(curl -s $(curl -s ${tunein_url:?} |sed -rn 's/.*StreamUrl.:.([^"]+)".*/http:\1/p')|jq -r '.Streams[0].Url')
   echo "*** streamurl=${streamurl:?}" >&2
   echo ${streamurl}
}
case "$0" in
    *mplayer-tunein.sh)
	# search is 1st arg only
        search="$1"
        shift
	;;
    *mplayer-*.sh)
	# infer search from mplayer-<QUERY>.sh symlink
        search=${0##*mplayer-}
        search=${search%.sh}
	;;
    *)  exit 1;;
esac

CMD=mplayer
if [[ "$1" == --save ]];then
    CMD="ffmpeg -c copy $2 -i"
    shift 2
fi
URL=$(tunein_search "${search:?}") || exit 1
: ${URL:?}
set -x
exec $CMD $extra $URL
