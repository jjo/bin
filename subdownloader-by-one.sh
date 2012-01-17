#!/bin/bash
# meh: workaround https://bugs.launchpad.net/subdownloader/+bug/722084:
# subdownloader crashes on dirs with already downloaded subtitles
DIR="${1:?missing_dir}"
TS=${2:-14}
subdownload_lang() {
	local dir="${1:?missing dir}"
	local lang="${2:?missing lang}"
	shift 2
	local find_args="$*"
	local L0=$(find "${dir?}" -type f -name '*.srt'| sort)
	find "${dir?}" $find_args -regextype posix-egrep -regex '.*[.](avi|mkv)$' -print0 |xargs --null -I@ sh -c 'file="@";test -f "${file%???}srt" || subdownloader -c -l '"${lang?}"' --rename-subs --video="@"'
	local L1=$(find "$dir" -type f -name '*.srt'| sort)
	local DIFF=$(diff -U0 <(echo "$L0") <(echo "$L1"))
	test -n "$DIFF" && {
		#only works for single dir $DIR - meh
		#subject=$(echo "$DIFF"| sed -n "s%$DIR%%p"|xargs)
		subject="subdownload_lang $dir $lang $*"
		echo "$DIFF" | mutt -s "${0##*/}: $subject" juanjosec+logger@gmail.com
	}
}
subdownload_lang "$DIR" "en" -mtime -$TS
subdownload_lang "$DIR" "es" -mtime -7 -mtime +$TS
