#!/bin/bash 
VARNAME=youtube.jjo.tedx.viewCount.10min
FILE=~/var/lib/jjo-tedx-views.data
as_graphite() {
  local varname="${1}"
  sed -r "s/.*viewCount:([0-9]+).*secs:([0-9]+).*/${varname} \1 \2/"|egrep "^${VARNAME}"
}
out_normal() {
curl -s 'https://gdata.youtube.com/feeds/api/videos/RoXoerNW3zY?v=2&alt=json'|printf '%s%(,secs:%s,date:"%c")T\n' "$(egrep -o ..favoriteCount.* |sed 's/["{}]//g;s/[$]/_/;s/$//')" -1
}
case "$1" in
	-P) sed -rn 's/.*viewCount:([0-9]+),.*secs:([0-9]+).*/\2,\1/p' ${FILE};exit;;
	-G) cat ${FILE}|as_graphite ${VARNAME};exit ;;
  -g) out_normal |as_graphite ${VARNAME};exit ;;
esac
out_normal
