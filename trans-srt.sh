#!/bin/bash
# Use Google translate to translate passed SRT file to stdout, use as eg:
#   ./trans-srt.sh nl es foo.S01E01.nl.srt > foo.S01E01.srt
#
TRANS=~/bin/trans
[ -x $TRANS ] || {
     echo "ERROR: missing $TRANS, do:"
     echo "wget -O ~/bin/trans git.io/trans; chmod +x ~/bin/trans"
     exit 1
}
src=${1?missing src lang, eg: nl}
dst=${2?missing dst lang, eg: es}
file=${3?missing file, eg: foo.S01E01.nl.srt}

# sed#1: remove <font> marking
# sed#2: rebuild timing line (as "translate" modifies it)
cat "${file?}" |\
  sed -u -r -e 's/<.?[fF]ont[^>]*>//ig' -e '/->/s/,/./g'|\
  stdbuf -o0 $TRANS -b ${src?}:${dst?} |\
  sed -u -r -e '/- u003e/s/: /:/g' -e '/- u003e/s/[ ,]([0-9]{3})/.\1/g' -e 's/- u003e/-->/'
