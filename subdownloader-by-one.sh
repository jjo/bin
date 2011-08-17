#!/bin/bash
# meh: workaround https://bugs.launchpad.net/subdownloader/+bug/722084:
# subdownloader crashes on dirs with already downloaded subtitles
find ${*:?missing dirs}  -mtime -7 -regextype posix-egrep -regex '.*[.](avi|mkv)$' -print0 |xargs --null -I@ sh -c 'file=@;test -f "${file%???}srt" || subdownloader -c -l es --rename-subs --video=@'
