#!/bin/bash -x
tunein_search() {
   local query=${1:?}
   local tunein_search_result=$(curl -s "http://tunein.com/search/?query=$query"|egrep -o '/radio/[^"]+-s[^"]+'|sort|uniq)
   local tunein_url=http://tunein.com/${tunein_search_result:?}
   local streamurl=$(curl -s $(curl -s ${tunein_url:?} |sed -rn 's/.*StreamUrl.:.([^"]+)".*/http:\1/p')|jq -r '.Streams[0].Url')
   echo "*** streamurl=${streamurl:?}" >&2
   echo ${streamurl}
}
# Use $* as tunein query
if [ -n "$*" ]; then
    search="$*"
# else infer it from mplayer-<QUERY>.sh symlink name
else
    search=${0##*mplayer-}
    search=${search%.sh}
    # except that mplayer-tunein.sh without args makes no sense
    [[ $search == tunein ]] && search=
fi
URL=$(tunein_search "$search") || exit 1
: ${URL:?}
extra=""
VLC=nvlc
VLC=mplayer
if [[ "$1" == --save ]];then
    exec ffmpeg -i "$URL" -c copy "$2"
fi
set -x
exec $VLC $extra $URL
