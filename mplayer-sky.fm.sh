#!/bin/bash
# $Id: mplayer-sky.fm.sh,v 1.15 2005/07/04 03:00:21 jjo Exp $

CACHE_DIR="${TMPDIR:-/tmp/}/mplayer.sh-$(id -un)"
EXPIRE_TIME="1 day"

URL="http://www.sky.fm"
#URL="http://www.shoutcast.com"
generate_href_and_desc() {
	#sed -n -r -e 's,.*href="(/(wma|mp3)/([^"]*)[.](asx|pls))".*,'"$URL"'\1 \3 (\2),pg' < $URLFILE  | sort | uniq
	python - "$URL" "$URLFILE" <<-EOF
import sys;import re
for x in re.compile(r'href="(([^"]*).(?:asx|pls))"', re.MULTILINE|re.DOTALL).findall(open(sys.argv[2]).read()): print "%s/%s %s" % (sys.argv[1],x[0],x[1])
#for x in re.compile(r'href="(([^"]*)[.](?:asx|pls))".*?(\[.*?\])', re.MULTILINE|re.DOTALL).findall(open(sys.argv[2]).read()): print "%s/%s %s %s" % (sys.argv[1],x[0],x[1],x[2])
	EOF

} 

error_exit() {
	status="$1";shift
	echo "$@" >&2
	exit $status
}
# cache_file_url(): 
#	descarga en tmpdir la URL pasada y lo mueve al cache; setea URLFILE a
# 	el nombre de archivo cache-ado. Pone fecha (touch) en +$EXPIRE_TIME en 
#	el futuro para poder simplificar la comp. de refresco.
#
cache_file_url() {
	typeset url="$1"
	typeset hash="$(echo "$url"| md5sum /dev/stdin)";hash=${hash%% *}
	typeset tmpdir=$(mktemp -d ${TMPDIR:-/tmp/}/mplayer.sh-tmp-XXXXXX)
	typeset tmpfile="$tmpdir/url-$hash.cache"
	typeset file="$CACHE_DIR/url-$hash.cache"
	test -d "$CACHE_DIR" || mkdir "$CACHE_DIR" || return 1
	touch "$tmpfile"
	if [ ! -s "$file" -o "$tmpfile" -nt "$file" ];then
		echo "Obteniendo $url ... -> $tmpfile" >&2
		curl -s "$url" > "$tmpfile" || return 1
		mv "$tmpfile" "$file"       || return 1
		touch -t "$(date -d +"$EXPIRE_TIME" +%Y%m%d%H%M)" "$file"
	fi
	echo "URL=$url (cache=$file)" >&2
	rm -f "$tmpfile"
	rmdir "$tmpdir"
	URLFILE="$file"
	return 0
}

# menu(): 
#	muestra el menu de opciones; si se tipea:
#	. un nro:  setea la var. TOPLAY a la opcion elegida
#	. /patron: filtra la lista (glob usando patron)
#	. -flags:  guarda estos flags para pasarlos a mplayer
#	. "q":     exit
#	. "r":     refrescar URL (cache)
#	. <enter> o cualquer otra cosa: vuelve a mostrar el menu
menu() {
	select opt in "${OPT_DESC2[@]}" ;do
		case "$REPLY" in
		[0-9]*) TOPLAY=$((REPLY-1));return 0;;
		/*) 	apply_filter "$REPLY"; return 0;;
		-*)	menu_opt_flags "$REPLY";return 0;;
		r)	download_url_and_build_opts -r;return 0;;
		v)	echo "MPLAYER_ARGS=$MPLAYER_ARGS" OUTFILE="$OUTFILE";;
		q) 	exit ;;
		esac
	done
	return 1
}
apply_filter() {
	typeset pattern="$1" opt_desc opt_href
	typeset -i i=0 j=0
	pattern="${pattern#/}"
	unset OPT_DESC2 OPT_HREF2
	while let "i-100";do
		opt_desc="${OPT_DESC[i]}"
		opt_href="${OPT_HREF[i]}"
		test -z "$opt_href" && break
		case "$opt_desc" in
		*"${pattern}"*) 
			OPT_DESC2[j]="$opt_desc"
			OPT_HREF2[j]="$opt_href"
			j=j+1;;
		esac
		i=i+1
	done
}
menu_opt_flags() {
	MPLAYER_ARGS="$MPLAYER_ARGS_EXEC $*"
}
download_url_and_build_opts() {
	case "$1" in
	-r) rm -f "$URLFILE";shift;;
	esac
	cache_file_url "$URL" || error_exit 1 "cache_file_url() failed"
	test -r $URLFILE || error_exit 1 "cachefile: \"$URLFILE\" not found"
	typeset -i n=0
	while read href desc ;do
		test -n "$href" -a -n "$href" -a -n "$desc" || continue
		OPT_HREF[$n]="$href"
		OPT_DESC[$n]="$desc"
		n=n+1
	done <<-EOF
		$(generate_href_and_desc)
	EOF
	apply_filter ""
}
do_play() {
	typeset url="$1"
	typeset MPLAYER="mplayer $MPLAYER_ARGS"
	case "$OUTFILE" in
	"")	echo "PLAY: $MPLAYER_ARGS $url"
		$MPLAYER -playlist "$url"
		;;
	*.mp3)	echo "SAVE: $MPLAYER_ARGS $url -> $OUTFILE (|lame)"
		$MPLAYER -nocache -quiet -ao pcm -aofile >(lame - "$OUTFILE") -playlist "$url"
		;;
	*.ogg)	echo "SAVE: $MPLAYER_ARGS $url -> $OUTFILE (|oggenc)"
		$MPLAYER -nocache -quiet -ao pcm -aofile >(oggenc -o "$OUTFILE" -) -playlist "$url"
		;;
	*)	echo "SAVE: $MPLAYER_ARGS $url -> $OUTFILE"
		$MPLAYER -nocache -quiet -ao pcm -aofile "$OUTFILE" -playlist "$url"
		;;
	esac
}
main_loop() {
	TOPLAY=""
	while menu;do 
		if [ -n "$TOPLAY" ];then
			url="${OPT_HREF2[$TOPLAY]}"
			do_play "$url"
		fi
		TOPLAY=""
	done
}
parse_args() {
	typeset opt
	while getopts "o:" opt; do
	case $opt in
	o) 	OUTFILE="$OPTARG";MPLAYER_ARGS_EXEC=;;
	?)   	printf "Usage: %s: [ -s path/to/output.mp3 (.ogg, .wav) ] \n" $PROG
		exit 2;;
	esac
	done
}
###
### main()
###
PROG="$0"
OUTFILE=
URLFILE=
OPT_HREF=
OPT_DESC=
#1024 KB, 5% fill
MPLAYER_ARGS_EXEC="-cache-min 5 -cache 1024 $@"

parse_args "$@"
test "$OPTIND" -ne 1 && shift $((OPTIND-1))

MPLAYER_ARGS="$MPLAYER_ARGS_EXEC"
download_url_and_build_opts
main_loop
